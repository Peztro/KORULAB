-- Notificaciones push (Firebase Cloud Messaging).
--
-- * push_tokens: la "dirección" de notificaciones de cada teléfono y de qué
--   cuenta es. La app la guarda al iniciar sesión y la borra al cerrarla.
-- * Al guardarse un mensaje privado (direct_messages) o un aviso (messages),
--   un disparador le pide a la Edge Function "enviar-push" que notifique.
--   Solo le pasa la tabla y el id: la función vuelve a leer la fila con
--   permisos de servidor y anota lo enviado en push_enviados, así que nadie
--   puede inventar notificaciones ni repetirlas.
--
-- Requiere: la Edge Function "enviar-push" desplegada (sin verificación de
-- JWT) y el secreto FIREBASE_SERVICE_ACCOUNT configurado en Supabase.

create extension if not exists pg_net;

create table if not exists public.push_tokens (
  token text primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  plataforma text not null default 'android',
  actualizado timestamptz not null default now()
);
create index if not exists push_tokens_user_idx on public.push_tokens (user_id);

-- Qué filas ya se notificaron (evita repetir).
create table if not exists public.push_enviados (
  tabla text not null,
  fila_id bigint not null,
  enviado_en timestamptz not null default now(),
  primary key (tabla, fila_id)
);

-- Sin políticas: solo las funciones de abajo y la Edge Function (con
-- permisos de servidor) usan estas tablas.
alter table public.push_tokens enable row level security;
alter table public.push_enviados enable row level security;

-- Guarda el token de este teléfono para la cuenta con sesión iniciada. Si el
-- teléfono era de otra cuenta, pasa a la nueva.
create or replace function public.registrar_token_push(
  p_token text,
  p_plataforma text default 'android'
)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then
    raise exception 'No autenticado';
  end if;
  if p_token is null or length(p_token) < 20 or length(p_token) > 4096 then
    raise exception 'Token no válido';
  end if;
  insert into public.push_tokens (token, user_id, plataforma, actualizado)
  values (p_token, auth.uid(), coalesce(p_plataforma, 'android'), now())
  on conflict (token) do update
    set user_id = excluded.user_id,
        plataforma = excluded.plataforma,
        actualizado = now();
end $$;

-- Al cerrar sesión: este teléfono deja de recibir lo de la cuenta.
create or replace function public.borrar_token_push(p_token text)
returns void
language sql security definer set search_path = public as $$
  delete from public.push_tokens
  where token = p_token and user_id = auth.uid();
$$;

revoke all on function public.registrar_token_push(text, text) from public, anon;
revoke all on function public.borrar_token_push(text) from public, anon;
grant execute on function public.registrar_token_push(text, text) to authenticated;
grant execute on function public.borrar_token_push(text) to authenticated;

-- Pide el push sin frenar el guardado del mensaje (pg_net lo envía aparte).
-- Si algo falla, el mensaje se guarda igual.
create or replace function public.trg_pedir_push()
returns trigger
language plpgsql security definer set search_path = public, extensions as $$
begin
  perform net.http_post(
    url := 'https://rnsxdjmywwweqkrxasjg.supabase.co/functions/v1/enviar-push',
    body := jsonb_build_object('tabla', tg_table_name, 'id', new.id),
    headers := '{"Content-Type": "application/json"}'::jsonb,
    timeout_milliseconds := 8000
  );
  return new;
exception when others then
  raise warning 'No se pudo pedir la notificación push: %', sqlerrm;
  return new;
end $$;

drop trigger if exists pedir_push on public.direct_messages;
create trigger pedir_push
  after insert on public.direct_messages
  for each row execute function public.trg_pedir_push();

drop trigger if exists pedir_push on public.messages;
create trigger pedir_push
  after insert on public.messages
  for each row execute function public.trg_pedir_push();
