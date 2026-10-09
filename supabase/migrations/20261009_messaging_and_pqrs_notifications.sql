create table if not exists public.messages (
  id bigint generated always as identity primary key,
  sender_username text not null,
  recipient_username text not null,
  title text not null,
  message text not null,
  kind text not null default 'general'
    check (kind in ('general', 'support_review', 'support_resolved')),
  support_request_id bigint references public.support_requests(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists messages_recipient_created_idx
  on public.messages (recipient_username, created_at desc);
grant select, insert on public.messages to authenticated;
grant usage, select on sequence public.messages_id_seq to authenticated;

alter table public.messages enable row level security;

drop policy if exists messages_select on public.messages;
create policy messages_select on public.messages for select to authenticated
  using (
    recipient_username = public.my_username()
    or recipient_username = '*'
  );

drop policy if exists messages_insert_broadcast on public.messages;
create policy messages_insert_broadcast on public.messages for insert to authenticated
  with check (
    sender_username = public.my_username()
    and public.my_role() in ('admin', 'teacher')
    and recipient_username = '*'
    and kind = 'general'
    and support_request_id is null
  );

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
  if request_row.status = p_status then
    return;
  end if;

  update public.support_requests set status = p_status where id = p_request_id;

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

revoke all on function public.update_support_request_status(bigint, text, text)
  from public, anon;
grant execute on function public.update_support_request_status(bigint, text, text)
  to authenticated;
