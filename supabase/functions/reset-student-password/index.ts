// Edge Function: restablece la contraseña de otra cuenta.
//
// * Profesores: solo pueden restablecer la de estudiantes.
// * Administradores: la de estudiantes y profesores (no la de otros admins
//   ni la propia).
// * Si se envía "password" se usa esa (mínimo 6 caracteres); si no, se genera
//   una aleatoria de 8 caracteres.
// * La cuenta queda marcada (user_metadata.must_change_password) para que la
//   app obligue a crear una contraseña propia al entrar.
//
// Despliegue: Supabase > Edge Functions > "reset-student-password" > Deploy.
import { createClient } from 'npm:@supabase/supabase-js@2';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  });

// Sin caracteres que se confunden al dictarlos (0/O, 1/l/I).
const ALFABETO = 'abcdefghjkmnpqrstuvwxyz23456789';

function aleatoria(largo = 8): string {
  const bytes = crypto.getRandomValues(new Uint8Array(largo));
  return Array.from(bytes, (b) => ALFABETO[b % ALFABETO.length]).join('');
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  const url = Deno.env.get('SUPABASE_URL')!;
  const caller = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
  });
  const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

  const { data: userData } = await caller.auth.getUser();
  if (!userData.user) return json({ error: 'No autenticado' }, 401);

  const { data: me } = await admin
    .from('profiles').select('id, role').eq('id', userData.user.id).single();
  if (me?.role !== 'teacher' && me?.role !== 'admin') {
    return json(
      { error: 'Solo profesores y administradores pueden restablecer contraseñas.' },
      403,
    );
  }

  let body: { username?: unknown; password?: unknown };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Solicitud no válida.' }, 400);
  }

  const { data: target } = await admin
    .from('profiles')
    .select('id, role')
    .eq('username', String(body.username ?? '').toLowerCase())
    .single();
  if (!target) return json({ error: 'No se encontró la cuenta.' }, 404);
  if (target.id === me.id) {
    return json({ error: 'Cambia tu propia contraseña desde Ajustes.' }, 400);
  }

  const permitido =
    me.role === 'admin'
      ? target.role === 'student' || target.role === 'teacher'
      : target.role === 'student';
  if (!permitido) {
    return json(
      {
        error: me.role === 'admin'
          ? 'No se puede restablecer la contraseña de otro administrador.'
          : 'Los profesores solo pueden restablecer contraseñas de estudiantes.',
      },
      403,
    );
  }

  let password: string;
  if (body.password === undefined || body.password === null || body.password === '') {
    password = aleatoria();
  } else if (typeof body.password !== 'string') {
    return json({ error: 'Contraseña no válida.' }, 400);
  } else if (body.password.length < 6) {
    return json({ error: 'La contraseña debe tener al menos 6 caracteres.' }, 400);
  } else if (body.password.length > 72) {
    return json({ error: 'La contraseña es demasiado larga (máximo 72).' }, 400);
  } else {
    password = body.password;
  }

  // Conserva los metadatos existentes (p. ej. el username del registro).
  const { data: actual } = await admin.auth.admin.getUserById(target.id);
  const metadatos = {
    ...(actual?.user?.user_metadata ?? {}),
    must_change_password: true,
  };

  const { error } = await admin.auth.admin.updateUserById(target.id, {
    password,
    user_metadata: metadatos,
  });
  if (error) return json({ error: error.message }, 500);
  return json({ password });
});
