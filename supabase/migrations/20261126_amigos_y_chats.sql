-- Amigos y mensajes privados.
--
-- Reglas:
-- * Una solicitud de amistad la acepta o rechaza quien la recibe. Si ambos se
--   envían solicitud, la amistad queda aceptada.
-- * Se puede escribir a los amigos y a cualquier profesor o administrador.
--   Profesores y administradores pueden escribir a cualquiera (así pueden
--   responder a estudiantes que no son sus amigos).
-- * Cada conversación solo la pueden leer sus dos participantes.
--
-- Las personas se identifican por su id (no por @usuario), para que cambiar de
-- @usuario no rompa amistades ni conversaciones.

-- Tablas ---------------------------------------------------------------------

create table if not exists public.friendships (
  id bigint generated always as identity primary key,
  requester_id uuid not null references public.profiles(id) on delete cascade,
  addressee_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  check (requester_id <> addressee_id)
);

-- Una sola fila por pareja, sin importar quién envió la solicitud.
create unique index if not exists friendships_pair_idx on public.friendships (
  least(requester_id, addressee_id),
  greatest(requester_id, addressee_id)
);
create index if not exists friendships_addressee_idx
  on public.friendships (addressee_id, status);

create table if not exists public.direct_messages (
  id bigint generated always as identity primary key,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (length(trim(body)) between 1 and 2000),
  created_at timestamptz not null default now(),
  read_at timestamptz,
  check (sender_id <> recipient_id)
);

create index if not exists direct_messages_pair_idx on public.direct_messages (
  least(sender_id, recipient_id),
  greatest(sender_id, recipient_id),
  created_at desc
);
create index if not exists direct_messages_unread_idx
  on public.direct_messages (recipient_id) where read_at is null;

-- Permisos -------------------------------------------------------------------
-- Las altas y cambios de amistad pasan por funciones (más abajo); desde la app
-- solo se puede leer y borrar (cancelar, rechazar o eliminar un amigo).

grant select, delete on public.friendships to authenticated;
grant select, insert on public.direct_messages to authenticated;
grant usage, select on sequence public.direct_messages_id_seq to authenticated;

alter table public.friendships enable row level security;
alter table public.direct_messages enable row level security;

create or replace function public.are_friends(a uuid, b uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.friendships f
    where f.status = 'accepted'
      and least(f.requester_id, f.addressee_id) = least(a, b)
      and greatest(f.requester_id, f.addressee_id) = greatest(a, b)
  )
$$;

-- ¿Puede el usuario actual escribirle a p_other?
create or replace function public.can_message(p_other uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select auth.uid() is not null
    and p_other <> auth.uid()
    and (
      public.is_staff()
      or exists (
        select 1 from public.profiles p
        where p.id = p_other and p.role in ('teacher', 'admin')
      )
      or public.are_friends(auth.uid(), p_other)
    )
$$;

drop policy if exists friendships_select on public.friendships;
create policy friendships_select on public.friendships for select to authenticated
  using (requester_id = auth.uid() or addressee_id = auth.uid());

drop policy if exists friendships_delete on public.friendships;
create policy friendships_delete on public.friendships for delete to authenticated
  using (requester_id = auth.uid() or addressee_id = auth.uid());

drop policy if exists direct_messages_select on public.direct_messages;
create policy direct_messages_select on public.direct_messages for select to authenticated
  using (sender_id = auth.uid() or recipient_id = auth.uid());

drop policy if exists direct_messages_insert on public.direct_messages;
create policy direct_messages_insert on public.direct_messages for insert to authenticated
  with check (
    sender_id = auth.uid()
    and read_at is null
    and public.can_message(recipient_id)
  );

-- Funciones ------------------------------------------------------------------

-- Envía una solicitud por @usuario. Devuelve:
-- 'sent', 'accepted' (había una solicitud suya pendiente), 'pending' (ya la
-- enviaste), 'friends', 'self' o 'not_found'.
create or replace function public.send_friend_request(p_username text)
returns text
language plpgsql security definer set search_path = public as $$
declare
  me uuid := auth.uid();
  other uuid;
  existing public.friendships;
begin
  if me is null then
    raise exception 'Debes iniciar sesión.';
  end if;
  select id into other from public.profiles
  where username = lower(trim(both '@' from trim(p_username)));
  if other is null then return 'not_found'; end if;
  if other = me then return 'self'; end if;

  select * into existing from public.friendships f
  where least(f.requester_id, f.addressee_id) = least(me, other)
    and greatest(f.requester_id, f.addressee_id) = greatest(me, other)
  for update;

  if existing.id is null then
    insert into public.friendships (requester_id, addressee_id)
    values (me, other);
    return 'sent';
  elsif existing.status = 'accepted' then
    return 'friends';
  elsif existing.requester_id = me then
    return 'pending';
  else
    update public.friendships
    set status = 'accepted', responded_at = now()
    where id = existing.id;
    return 'accepted';
  end if;
end $$;

-- Acepta o rechaza una solicitud recibida.
create or replace function public.respond_friend_request(
  p_id bigint,
  p_accept boolean
) returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_accept then
    update public.friendships
    set status = 'accepted', responded_at = now()
    where id = p_id and addressee_id = auth.uid() and status = 'pending';
  else
    delete from public.friendships
    where id = p_id and addressee_id = auth.uid() and status = 'pending';
  end if;
  if not found then
    raise exception 'La solicitud ya no está disponible.';
  end if;
end $$;

-- Amistades y solicitudes del usuario actual, con los datos de la otra persona.
create or replace function public.my_friendships()
returns table (
  id bigint,
  other_id uuid,
  username text,
  display_name text,
  profile_photo text,
  role text,
  status text,
  incoming boolean,
  created_at timestamptz
)
language sql stable security definer set search_path = public as $$
  select
    f.id,
    p.id,
    p.username,
    p.display_name,
    p.profile_photo,
    p.role,
    f.status,
    f.addressee_id = auth.uid(),
    f.created_at
  from public.friendships f
  join public.profiles p
    on p.id = case when f.requester_id = auth.uid()
                   then f.addressee_id else f.requester_id end
  where f.requester_id = auth.uid() or f.addressee_id = auth.uid()
  order by f.status, f.created_at desc
$$;

-- Lista de conversaciones: último mensaje y no leídos por cada persona.
create or replace function public.my_conversations()
returns table (
  partner_id uuid,
  username text,
  display_name text,
  profile_photo text,
  role text,
  last_body text,
  last_at timestamptz,
  last_from_me boolean,
  unread integer
)
language sql stable security definer set search_path = public as $$
  with mine as (
    select
      m.*,
      case when m.sender_id = auth.uid() then m.recipient_id else m.sender_id end
        as partner
    from public.direct_messages m
    where m.sender_id = auth.uid() or m.recipient_id = auth.uid()
  ),
  last_message as (
    select distinct on (partner) partner, body, created_at, sender_id
    from mine
    order by partner, created_at desc, id desc
  ),
  unread as (
    select partner, count(*)::int as total
    from mine
    where recipient_id = auth.uid() and read_at is null
    group by partner
  )
  select
    p.id,
    p.username,
    p.display_name,
    p.profile_photo,
    p.role,
    l.body,
    l.created_at,
    l.sender_id = auth.uid(),
    coalesce(u.total, 0)
  from last_message l
  join public.profiles p on p.id = l.partner
  left join unread u on u.partner = l.partner
  order by l.created_at desc
$$;

-- Marca como leídos los mensajes recibidos de p_partner.
create or replace function public.mark_conversation_read(p_partner uuid)
returns void
language sql security definer set search_path = public as $$
  update public.direct_messages
  set read_at = now()
  where recipient_id = auth.uid()
    and sender_id = p_partner
    and read_at is null
$$;

-- Solicitudes recibidas pendientes + mensajes sin leer (para el contador).
create or replace function public.my_pending_counts()
returns table (requests integer, unread integer)
language sql stable security definer set search_path = public as $$
  select
    (select count(*)::int from public.friendships
     where addressee_id = auth.uid() and status = 'pending'),
    (select count(*)::int from public.direct_messages
     where recipient_id = auth.uid() and read_at is null)
$$;

revoke all on function public.are_friends(uuid, uuid) from public;
revoke all on function public.can_message(uuid) from public;
revoke all on function public.send_friend_request(text) from public;
revoke all on function public.respond_friend_request(bigint, boolean) from public;
revoke all on function public.my_friendships() from public;
revoke all on function public.my_conversations() from public;
revoke all on function public.mark_conversation_read(uuid) from public;
revoke all on function public.my_pending_counts() from public;
grant execute on function public.can_message(uuid) to authenticated;
grant execute on function public.send_friend_request(text) to authenticated;
grant execute on function public.respond_friend_request(bigint, boolean) to authenticated;
grant execute on function public.my_friendships() to authenticated;
grant execute on function public.my_conversations() to authenticated;
grant execute on function public.mark_conversation_read(uuid) to authenticated;
grant execute on function public.my_pending_counts() to authenticated;

-- Tiempo real: mensajes nuevos y cambios de amistad llegan al instante.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'direct_messages'
  ) then
    alter publication supabase_realtime add table public.direct_messages;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'friendships'
  ) then
    alter publication supabase_realtime add table public.friendships;
  end if;
end $$;
