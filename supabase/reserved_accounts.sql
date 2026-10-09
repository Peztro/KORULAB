-- Cuentas reservadas koruadm y korucol.
--
-- PASO 1: ejecuta SOLO este bloque en SQL Editor (permite crear las cuentas desde el panel).
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare uname text := lower(coalesce(new.raw_user_meta_data->>'username', ''));
begin
  if uname in ('koruadm', 'korucol') then
    raise exception 'Nombre de usuario reservado';
  end if;
  if uname = '' and new.email in ('koruadm@korulab.local', 'korucol@korulab.local') then
    return new;
  end if;
  insert into public.profiles (id, username) values (new.id, uname);
  insert into public.profile_private (id, email) values (new.id, new.email);
  return new;
end $$;

-- PASO 2 (en el panel):
--   Authentication > Users > Add user > Create new user
--     Email: koruadm@korulab.local   Password: (la que quieras)   [x] Auto Confirm User
--     Email: korucol@korulab.local   Password: (la que quieras)   [x] Auto Confirm User

-- PASO 3: ejecuta este bloque en SQL Editor.
insert into public.profiles (id, username, display_name, role)
select id, 'koruadm', 'KORUADMIN', 'admin' from auth.users
where email = 'koruadm@korulab.local'
on conflict (id) do update set role = 'admin', display_name = 'KORUADMIN';

insert into public.profiles (id, username, display_name, role)
select id, 'korucol', 'KoruCol', 'admin' from auth.users
where email = 'korucol@korulab.local'
on conflict (id) do update set role = 'admin', display_name = 'KoruCol';

insert into public.profile_private (id, email)
select id, email from auth.users
where email in ('koruadm@korulab.local', 'korucol@korulab.local')
on conflict (id) do nothing;
