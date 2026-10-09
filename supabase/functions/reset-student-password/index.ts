// Edge Function: restablece la contraseña de un estudiante (solo profesores).
// Despliegue: Supabase > Edge Functions > Deploy a new function > nombre "reset-student-password".
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
    .from('profiles').select('role').eq('id', userData.user.id).single();
  if (me?.role !== 'teacher') {
    return json({ error: 'Solo los profesores pueden restablecer contraseñas.' }, 403);
  }

  const { username } = await req.json();
  const { data: student } = await admin
    .from('profiles').select('id, role').eq('username', String(username).toLowerCase()).single();
  if (!student || student.role !== 'student') {
    return json({ error: 'Estudiante no encontrado.' }, 404);
  }

  const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
  const bytes = crypto.getRandomValues(new Uint8Array(8));
  const password = Array.from(bytes, (b) => chars[b % chars.length]).join('');

  const { error } = await admin.auth.admin.updateUserById(student.id, { password });
  if (error) return json({ error: error.message }, 500);
  return json({ password });
});
