-- PQRS en tiempo real y solución guardada en la propia PQRS.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'support_requests'
  ) then
    alter publication supabase_realtime add table public.support_requests;
  end if;
end $$;

alter table public.support_requests add column if not exists resolution text;

update public.support_requests r
set resolution = (
  select m.message from public.messages m
  where m.support_request_id = r.id and m.kind = 'support_resolved'
  order by m.created_at desc limit 1)
where r.status = 'Resuelta' and r.resolution is null;

create or replace function public.update_support_request_status(
  p_request_id bigint,
  p_status text,
  p_resolution_message text default null
) returns void
language plpgsql security definer set search_path = public as $$
declare
  request_row public.support_requests;
  sender text := public.my_username();
begin
  if not public.is_admin() then
    raise exception 'Solo la cuenta administradora puede actualizar las PQRS.';
  end if;
  if p_status not in ('Pendiente', 'En revisión', 'Resuelta') then
    raise exception 'Estado de PQRS no válido.';
  end if;
  if p_status = 'Resuelta'
     and length(trim(coalesce(p_resolution_message, ''))) < 10 then
    raise exception 'Describe la resolución con al menos 10 caracteres.';
  end if;

  select * into request_row
  from public.support_requests
  where id = p_request_id
  for update;
  if not found then
    raise exception 'No se encontró la PQRS.';
  end if;
  if request_row.status = 'Resuelta' then
    raise exception 'Esta PQRS ya está resuelta y no puede cambiar de estado.';
  end if;
  if request_row.status = p_status then
    return;
  end if;

  update public.support_requests
  set status = p_status,
      resolved_at = case when p_status = 'Resuelta' then now() else null end,
      resolution = case when p_status = 'Resuelta' then trim(p_resolution_message) else null end
  where id = p_request_id;

  if p_status = 'En revisión' then
    insert into public.messages (
      sender_username, recipient_username, title, message, kind, support_request_id
    ) values (
      sender, request_row.username, 'Tu PQRS está en revisión',
      'Revisamos tu solicitud y ya está en ejecución. Te avisaremos cuando se resuelva.',
      'support_review', request_row.id
    );
  elsif p_status = 'Resuelta' then
    insert into public.messages (
      sender_username, recipient_username, title, message, kind, support_request_id
    ) values (
      sender, request_row.username, 'Tu PQRS fue resuelta',
      trim(p_resolution_message), 'support_resolved', request_row.id
    );
  end if;
end;
$$;
