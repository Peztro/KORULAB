// Edge Function: envía notificaciones push (Firebase Cloud Messaging).
//
// La llama la base de datos (disparadores "pedir_push", ver
// supabase/migrations/20261201_notificaciones_push.sql y
// 20261202_push_amistades_korublog.sql) cuando:
//   * llega un mensaje privado (direct_messages): avisa al destinatario;
//   * se publica un aviso (messages): a su destinatario, o a todos si es "*";
//   * llega una solicitud de amistad (friendships): a quien la recibe;
//   * aceptan una solicitud (friendships_aceptada): a quien la envió;
//   * responden en Korublog (discussion_replies): al autor de la publicación.
//
// Solo recibe { tabla, id }. Vuelve a leer la fila con permisos de servidor
// y anota lo enviado en push_enviados, así que llamarla a mano no sirve para
// inventar notificaciones ni para repetirlas.
//
// Necesita el secreto FIREBASE_SERVICE_ACCOUNT (el JSON de la cuenta de
// servicio de Firebase) y desplegarse SIN verificación de JWT.
import { createClient } from 'npm:@supabase/supabase-js@2';

type CuentaServicio = {
  project_id: string;
  client_email: string;
  private_key: string;
};

type Aviso = {
  titulo: string;
  cuerpo: string;
  destinatarios: string[]; // ids de usuario
  datos: Record<string, string>;
  /// Sin notificación armada: la app la arma (chats: plegada dice "Mensaje
  /// nuevo" y desplegada muestra remitente y mensaje).
  soloDatos?: boolean;
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });

const admin = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  { auth: { persistSession: false } },
);

// Solo se notifican filas recientes (evita reenviar mensajes viejos).
const MAX_ANTIGUEDAD_MS = 10 * 60 * 1000;

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json({ error: 'Método no permitido' }, 405);

  let tabla: unknown, id: unknown;
  try {
    ({ tabla, id } = await req.json());
  } catch {
    return json({ error: 'Cuerpo no válido' }, 400);
  }
  const avisadores: Record<string, (id: number) => Promise<Aviso | null>> = {
    direct_messages: avisoDeMensajePrivado,
    messages: avisoGeneral,
    friendships: avisoDeSolicitud,
    friendships_aceptada: avisoDeAmistadAceptada,
    discussion_replies: avisoDeRespuesta,
  };
  if (
    typeof tabla !== 'string' ||
    !(tabla in avisadores) ||
    typeof id !== 'number'
  ) {
    return json({ error: 'Petición no válida' }, 400);
  }

  // Reclama la fila: si ya se notificó, no hace nada.
  const { error: yaEnviado } = await admin
    .from('push_enviados')
    .insert({ tabla, fila_id: id });
  if (yaEnviado) return json({ ok: true, omitido: 'ya enviado' });

  const aviso = await avisadores[tabla](id);
  if (!aviso || aviso.destinatarios.length === 0) {
    return json({ ok: true, omitido: 'sin destinatarios' });
  }

  const { data: filas, error } = await admin
    .from('push_tokens')
    .select('token')
    .in('user_id', aviso.destinatarios);
  if (error) return json({ error: error.message }, 500);
  const tokens = (filas ?? []).map((f) => f.token as string);
  if (tokens.length === 0) return json({ ok: true, omitido: 'sin teléfonos' });

  const cuenta = leerCuentaServicio();
  if (!cuenta) {
    return json({ error: 'Falta el secreto FIREBASE_SERVICE_ACCOUNT' }, 500);
  }
  const acceso = await tokenDeGoogle(cuenta);

  let enviados = 0;
  const invalidos: string[] = [];
  // De a 50 a la vez para no saturar.
  for (let i = 0; i < tokens.length; i += 50) {
    const lote = tokens.slice(i, i + 50);
    const resultados = await Promise.all(
      lote.map((token) => enviarAFcm(cuenta.project_id, acceso, token, aviso)),
    );
    resultados.forEach((r, j) => {
      if (r === 'ok') enviados++;
      if (r === 'invalido') invalidos.push(lote[j]);
    });
  }
  // Teléfonos que ya no existen (app desinstalada): se olvidan.
  if (invalidos.length > 0) {
    await admin.from('push_tokens').delete().in('token', invalidos);
  }
  return json({ ok: true, enviados, invalidos: invalidos.length });
});

function reciente(creado: string | null): boolean {
  if (!creado) return false;
  return Date.now() - new Date(creado).getTime() < MAX_ANTIGUEDAD_MS;
}

async function avisoDeMensajePrivado(id: number): Promise<Aviso | null> {
  const { data: m } = await admin
    .from('direct_messages')
    .select('sender_id, recipient_id, body, image_path, created_at')
    .eq('id', id)
    .maybeSingle();
  if (!m || !reciente(m.created_at)) return null;

  const { data: remitente } = await admin
    .from('profiles')
    .select('username, display_name')
    .eq('id', m.sender_id)
    .maybeSingle();
  const nombre =
    (remitente?.display_name as string | null)?.trim() ||
    (remitente ? `@${remitente.username}` : 'Nuevo mensaje');

  const texto = ((m.body as string | null) ?? '').trim();
  const cuerpo = m.image_path
    ? texto
      ? `📷 ${texto}`
      : '📷 Foto'
    : texto;

  return {
    titulo: 'Mensaje nuevo',
    cuerpo: recortar(cuerpo),
    destinatarios: [m.recipient_id as string],
    datos: {
      tipo: 'chat',
      remitente: m.sender_id as string,
      remitente_nombre: nombre,
      texto: recortar(cuerpo, 900),
      mensaje_id: String(id),
    },
    soloDatos: true,
  };
}

async function avisoGeneral(id: number): Promise<Aviso | null> {
  const { data: m } = await admin
    .from('messages')
    .select('sender_username, recipient_username, title, message, created_at')
    .eq('id', id)
    .maybeSingle();
  if (!m || !reciente(m.created_at)) return null;

  const remitente = ((m.sender_username as string) ?? '').toLowerCase();
  const para = ((m.recipient_username as string) ?? '').toLowerCase();
  let consulta = admin.from('profiles').select('id, username');
  consulta =
    para === '*'
      ? consulta.neq('username', remitente)
      : consulta.eq('username', para);
  const { data: perfiles } = await consulta;

  return {
    titulo: (m.title as string) || 'Aviso de Korulab',
    cuerpo: recortar((m.message as string) ?? ''),
    destinatarios: (perfiles ?? [])
      .filter((p) => (p.username as string).toLowerCase() !== remitente)
      .map((p) => p.id as string),
    datos: { tipo: 'aviso' },
  };
}

/** Nombre para mostrar de un usuario (por id). */
async function nombreDe(id: string): Promise<string> {
  const { data } = await admin
    .from('profiles')
    .select('username, display_name')
    .eq('id', id)
    .maybeSingle();
  return (
    (data?.display_name as string | null)?.trim() ||
    (data ? `@${data.username}` : 'Alguien')
  );
}

// Amistades automáticas (admin con todos, profes con estudiantes): no
// cuentan como "aceptar una solicitud".
function amistadAutomatica(rolA?: string, rolB?: string): boolean {
  return (
    rolA === 'admin' ||
    rolB === 'admin' ||
    (rolA === 'teacher' && rolB === 'student') ||
    (rolA === 'student' && rolB === 'teacher')
  );
}

async function avisoDeSolicitud(id: number): Promise<Aviso | null> {
  const { data: f } = await admin
    .from('friendships')
    .select('requester_id, addressee_id, status, created_at')
    .eq('id', id)
    .maybeSingle();
  if (!f || f.status !== 'pending' || !reciente(f.created_at)) return null;
  const quien = await nombreDe(f.requester_id as string);
  return {
    titulo: 'Nueva solicitud de amistad 🤝',
    cuerpo: `${quien} quiere ser tu amigo en Korulab.`,
    destinatarios: [f.addressee_id as string],
    datos: { tipo: 'amistad' },
  };
}

async function avisoDeAmistadAceptada(id: number): Promise<Aviso | null> {
  const { data: f } = await admin
    .from('friendships')
    .select('requester_id, addressee_id, status, responded_at')
    .eq('id', id)
    .maybeSingle();
  if (!f || f.status !== 'accepted' || !reciente(f.responded_at)) return null;
  const { data: roles } = await admin
    .from('profiles')
    .select('id, role')
    .in('id', [f.requester_id, f.addressee_id]);
  const rol = (uid: string) =>
    (roles ?? []).find((r) => r.id === uid)?.role as string | undefined;
  if (amistadAutomatica(rol(f.requester_id), rol(f.addressee_id))) return null;
  const quien = await nombreDe(f.addressee_id as string);
  return {
    titulo: '¡Tienes un amigo nuevo! 🎉',
    cuerpo: `${quien} aceptó tu solicitud de amistad. ¡Escríbele!`,
    destinatarios: [f.requester_id as string],
    datos: { tipo: 'amistad' },
  };
}

async function avisoDeRespuesta(id: number): Promise<Aviso | null> {
  const { data: r } = await admin
    .from('discussion_replies')
    .select('discussion_id, author, author_handle, message, created_at')
    .eq('id', id)
    .maybeSingle();
  if (!r || !reciente(r.created_at)) return null;
  const { data: pub } = await admin
    .from('discussion_spaces')
    .select('title, author_handle')
    .eq('id', r.discussion_id)
    .maybeSingle();
  if (!pub) return null;
  const autor = ((pub.author_handle as string) ?? '').toLowerCase();
  const quien = ((r.author_handle as string) ?? '').toLowerCase();
  // No se avisa a uno mismo.
  if (!autor || autor === quien) return null;
  const { data: dueno } = await admin
    .from('profiles')
    .select('id')
    .eq('username', autor)
    .maybeSingle();
  if (!dueno) return null;
  const nombre = ((r.author as string) ?? '').trim() || `@${quien}`;
  return {
    titulo: `Comentaron tu publicación en Korublog 💬`,
    cuerpo: recortar(`${nombre} en "${pub.title}": ${r.message}`),
    destinatarios: [dueno.id as string],
    datos: { tipo: 'korublog', publicacion: String(r.discussion_id) },
  };
}

function recortar(texto: string, max = 180): string {
  return texto.length <= max ? texto : `${texto.slice(0, max - 1)}…`;
}

function leerCuentaServicio(): CuentaServicio | null {
  const crudo = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
  if (!crudo) return null;
  try {
    const c = JSON.parse(crudo);
    if (!c.project_id || !c.client_email || !c.private_key) return null;
    return c;
  } catch {
    return null;
  }
}

// --- Acceso a la API de Firebase con la cuenta de servicio -----------------

let accesoEnCache: { token: string; vence: number } | null = null;

async function tokenDeGoogle(c: CuentaServicio): Promise<string> {
  if (accesoEnCache && accesoEnCache.vence > Date.now() + 60_000) {
    return accesoEnCache.token;
  }
  const ahora = Math.floor(Date.now() / 1000);
  const cabecera = { alg: 'RS256', typ: 'JWT' };
  const datos = {
    iss: c.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: ahora,
    exp: ahora + 3600,
  };
  const sinFirma = `${b64url(JSON.stringify(cabecera))}.${b64url(
    JSON.stringify(datos),
  )}`;
  const llave = await crypto.subtle.importKey(
    'pkcs8',
    pemABytes(c.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const firma = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    llave,
    new TextEncoder().encode(sinFirma),
  );
  const jwt = `${sinFirma}.${b64url(new Uint8Array(firma))}`;

  const resp = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  if (!resp.ok) {
    throw new Error(`Google rechazó la cuenta de servicio: ${await resp.text()}`);
  }
  const { access_token, expires_in } = await resp.json();
  accesoEnCache = {
    token: access_token,
    vence: Date.now() + (expires_in ?? 3600) * 1000,
  };
  return access_token;
}

async function enviarAFcm(
  proyecto: string,
  acceso: string,
  token: string,
  aviso: Aviso,
): Promise<'ok' | 'invalido' | 'error'> {
  const resp = await fetch(
    `https://fcm.googleapis.com/v1/projects/${proyecto}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${acceso}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: aviso.soloDatos
          ? {
              token,
              data: aviso.datos,
              // Alta prioridad: despierta la app para que arme la
              // notificación aunque esté cerrada.
              android: { priority: 'HIGH' },
            }
          : {
              token,
              notification: { title: aviso.titulo, body: aviso.cuerpo },
              data: aviso.datos,
              android: {
                priority: 'HIGH',
                notification: { channel_id: 'messages' },
              },
            },
      }),
    },
  );
  if (resp.ok) return 'ok';
  const texto = await resp.text();
  // El teléfono ya no está registrado (desinstaló la app, etc.).
  if (
    resp.status === 404 ||
    texto.includes('UNREGISTERED') ||
    texto.includes('registration-token-not-registered')
  ) {
    return 'invalido';
  }
  console.error('FCM no aceptó el envío:', resp.status, texto);
  return 'error';
}

function b64url(dato: string | Uint8Array): string {
  const bytes = typeof dato === 'string' ? new TextEncoder().encode(dato) : dato;
  let binario = '';
  bytes.forEach((b) => (binario += String.fromCharCode(b)));
  return btoa(binario).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function pemABytes(pem: string): ArrayBuffer {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '');
  const binario = atob(base64);
  const bytes = new Uint8Array(binario.length);
  for (let i = 0; i < binario.length; i++) bytes[i] = binario.charCodeAt(i);
  return bytes.buffer;
}
