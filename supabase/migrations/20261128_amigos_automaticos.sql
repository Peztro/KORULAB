-- Amistades automáticas por rol.
--
-- * Los administradores son amigos de todas las cuentas.
-- * Los profesores son amigos de todos los estudiantes.
-- Se crean solas al registrarse alguien o al cambiarle el rol, y no se pueden
-- eliminar. Requiere 20261126_amigos_y_chats.sql.

-- ¿Deben ser amigos dos cuentas con estos roles?
create or replace function public.amistad_automatica(rol_a text, rol_b text)
returns boolean
language sql immutable as $$
  select rol_a = 'admin'
      or rol_b = 'admin'
      or (rol_a = 'teacher' and rol_b = 'student')
      or (rol_a = 'student' and rol_b = 'teacher')
$$;

-- Crea (o acepta) todas las amistades automáticas de p_user.
create or replace function public.ensure_auto_friendships(p_user uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  mi_rol text;
begin
  select role into mi_rol from public.profiles where id = p_user;
  if mi_rol is null then return; end if;

  -- Acepta solicitudes pendientes que ya existieran entre ellos.
  update public.friendships f
  set status = 'accepted', responded_at = now()
  from public.profiles otro
  where f.status = 'pending'
    and (f.requester_id = p_user or f.addressee_id = p_user)
    and otro.id = case when f.requester_id = p_user
                       then f.addressee_id else f.requester_id end
    and public.amistad_automatica(mi_rol, otro.role);

  -- Crea las que falten. Envía la "solicitud" quien tiene el rol mayor.
  insert into public.friendships (requester_id, addressee_id, status, responded_at)
  select
    case when mi_rol = 'admin' or (mi_rol = 'teacher' and otro.role = 'student')
         then p_user else otro.id end,
    case when mi_rol = 'admin' or (mi_rol = 'teacher' and otro.role = 'student')
         then otro.id else p_user end,
    'accepted',
    now()
  from public.profiles otro
  where otro.id <> p_user
    and public.amistad_automatica(mi_rol, otro.role)
  on conflict do nothing;
end $$;

revoke all on function public.ensure_auto_friendships(uuid) from public;

create or replace function public.trg_auto_friendships() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform public.ensure_auto_friendships(new.id);
  return new;
end $$;

drop trigger if exists auto_friendships_on_insert on public.profiles;
create trigger auto_friendships_on_insert
  after insert on public.profiles
  for each row execute function public.trg_auto_friendships();

drop trigger if exists auto_friendships_on_role on public.profiles;
create trigger auto_friendships_on_role
  after update of role on public.profiles
  for each row
  when (new.role is distinct from old.role)
  execute function public.trg_auto_friendships();

-- Las amistades automáticas no se pueden eliminar.
drop policy if exists friendships_delete on public.friendships;
create policy friendships_delete on public.friendships for delete to authenticated
  using (
    (requester_id = auth.uid() or addressee_id = auth.uid())
    and not exists (
      select 1
      from public.profiles a, public.profiles b
      where a.id = requester_id
        and b.id = addressee_id
        and public.amistad_automatica(a.role, b.role)
    )
  );

-- Para que la app sepa qué amistades no se pueden quitar. Cambia las columnas
-- que devuelve, así que hay que borrarla y crearla de nuevo.
drop function if exists public.my_friendships();
create function public.my_friendships()
returns table (
  id bigint,
  other_id uuid,
  username text,
  display_name text,
  profile_photo text,
  role text,
  status text,
  incoming boolean,
  created_at timestamptz,
  automatic boolean
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
    f.created_at,
    public.amistad_automatica(yo.role, p.role)
  from public.friendships f
  join public.profiles yo on yo.id = auth.uid()
  join public.profiles p
    on p.id = case when f.requester_id = auth.uid()
                   then f.addressee_id else f.requester_id end
  where f.requester_id = auth.uid() or f.addressee_id = auth.uid()
  order by f.status, f.created_at desc
$$;

revoke all on function public.my_friendships() from public;
grant execute on function public.my_friendships() to authenticated;

-- Aplica la regla a las cuentas que ya existen (admins y profesores cubren
-- todas las parejas automáticas).
do $$
declare
  staff_id uuid;
begin
  for staff_id in
    select id from public.profiles where role in ('admin', 'teacher')
  loop
    perform public.ensure_auto_friendships(staff_id);
  end loop;
end $$;
