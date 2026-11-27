-- Más notificaciones push: amistades y Korublog.
--
-- * Solicitud de amistad nueva       → a quien la recibe.
-- * Solicitud de amistad aceptada    → a quien la envió.
-- * Respuesta en Korublog            → al autor de la publicación.
--
-- Usa la misma Edge Function "enviar-push" (actualízala con la versión
-- nueva) y la función trg_pedir_push de 20261201_notificaciones_push.sql,
-- que ahora acepta un nombre de evento como argumento.

-- El disparador manda { tabla, id }. "tabla" es el nombre del evento si se
-- pasa como argumento (p. ej. friendships_aceptada), o el de la tabla.
create or replace function public.trg_pedir_push()
returns trigger
language plpgsql security definer set search_path = public, extensions as $$
begin
  perform net.http_post(
    url := 'https://rnsxdjmywwweqkrxasjg.supabase.co/functions/v1/enviar-push',
    body := jsonb_build_object(
      'tabla', coalesce(tg_argv[0], tg_table_name),
      'id', new.id
    ),
    headers := '{"Content-Type": "application/json"}'::jsonb,
    timeout_milliseconds := 8000
  );
  return new;
exception when others then
  raise warning 'No se pudo pedir la notificación push: %', sqlerrm;
  return new;
end $$;

-- Solicitud nueva (las amistades automáticas nacen aceptadas: no avisan).
drop trigger if exists pedir_push on public.friendships;
create trigger pedir_push
  after insert on public.friendships
  for each row
  when (new.status = 'pending')
  execute function public.trg_pedir_push('friendships');

-- Solicitud aceptada.
drop trigger if exists pedir_push_aceptada on public.friendships;
create trigger pedir_push_aceptada
  after update of status on public.friendships
  for each row
  when (old.status = 'pending' and new.status = 'accepted')
  execute function public.trg_pedir_push('friendships_aceptada');

-- Respuesta en Korublog.
drop trigger if exists pedir_push on public.discussion_replies;
create trigger pedir_push
  after insert on public.discussion_replies
  for each row execute function public.trg_pedir_push('discussion_replies');
