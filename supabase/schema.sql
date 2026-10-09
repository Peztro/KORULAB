-- Korulab: esquema para Supabase. Ejecutar completo en SQL Editor.
-- Antes: Authentication > Providers > Email > desactivar "Confirm email".

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (username ~ '^[a-z0-9._]{3,20}$'),
  display_name text,
  age int,
  birth_year int,
  location text,
  occupation text,
  bio text,
  learning_goal text,
  profile_photo text,
  handle_changed_at timestamptz,
  role text not null default 'student' check (role in ('admin','teacher','student')),
  created_at timestamptz not null default now()
);

create table public.profile_private (
  id uuid primary key references public.profiles(id) on delete cascade,
  email text not null
);

create table public.discussion_spaces (
  id bigint generated always as identity primary key,
  title text not null,
  description text not null,
  author text not null,
  author_handle text not null default '',
  created_at timestamptz not null default now()
);

create table public.discussion_replies (
  id bigint generated always as identity primary key,
  discussion_id bigint not null references public.discussion_spaces(id) on delete cascade,
  author text not null,
  author_handle text not null default '',
  message text not null,
  created_at timestamptz not null default now()
);

create table public.support_requests (
  id bigint generated always as identity primary key,
  username text not null,
  display_name text not null,
  author_handle text not null,
  email text not null,
  category text not null,
  subject text not null,
  message text not null,
  status text not null default 'Pendiente',
  created_at timestamptz not null default now()
);

create table public.teacher_lessons (
  id bigint generated always as identity primary key,
  teacher_username text not null,
  title text not null,
  summary text not null,
  content text not null,
  destination text not null default 'koruclases',
  created_at timestamptz not null default now()
);

create table public.teacher_courses (
  id bigint generated always as identity primary key,
  teacher_username text not null,
  title text not null,
  subtitle text not null default '',
  activities text not null default '[]',
  created_at timestamptz not null default now()
);

create table public.eco_journal_entries (
  id bigint generated always as identity primary key,
  username text not null,
  challenge_id text not null,
  note text not null,
  created_at timestamptz not null
);
create index on public.eco_journal_entries (username, challenge_id, created_at);

create table public.eco_journal_photos (
  id bigint generated always as identity primary key,
  entry_id bigint not null references public.eco_journal_entries(id) on delete cascade,
  photo text not null
);
create index on public.eco_journal_photos (entry_id);

create table public.user_progress (
  username text primary key,
  data jsonb not null default '{}',
  updated_at timestamptz not null default now()
);

-- Funciones auxiliares ------------------------------------------------------
create function public.my_username() returns text
language sql stable security definer set search_path = public as
$$ select username from public.profiles where id = auth.uid() $$;

create function public.my_role() returns text
language sql stable security definer set search_path = public as
$$ select role from public.profiles where id = auth.uid() $$;

create function public.is_admin() returns boolean
language sql stable security definer set search_path = public as
$$ select coalesce(public.my_role() = 'admin', false) $$;

create function public.is_staff() returns boolean
language sql stable security definer set search_path = public as
$$ select coalesce(public.my_role() in ('admin','teacher'), false) $$;

-- Vista con los datos públicos de los perfiles
create view public.public_profiles as
  select id, username, display_name, profile_photo, role from public.profiles;
grant select on public.public_profiles to authenticated;

-- Alta automática del perfil al registrarse
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare uname text := lower(coalesce(new.raw_user_meta_data->>'username', ''));
begin
  if uname in ('koruadm', 'korucol') then
    raise exception 'Nombre de usuario reservado';
  end if;
  insert into public.profiles (id, username) values (new.id, uname);
  insert into public.profile_private (id, email) values (new.id, new.email);
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Protege rol y usuario contra cambios no autorizados
create function public.guard_profile_update() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null then
    new.id := old.id;
    if not public.is_admin() then new.role := old.role; end if;
    if coalesce(current_setting('app.allow_username_change', true), '') <> '1' then
      new.username := old.username;
      new.handle_changed_at := old.handle_changed_at;
    end if;
  end if;
  return new;
end $$;
create trigger guard_profile_update before update on public.profiles
  for each row execute function public.guard_profile_update();

-- RPC públicas ----------------------------------------------------------------
create function public.login_email(p_username text) returns text
language sql stable security definer set search_path = public as $$
  select pp.email from public.profile_private pp
  join public.profiles p on p.id = pp.id
  where p.username = lower(p_username)
$$;

create function public.username_available(p_username text) returns boolean
language sql stable security definer set search_path = public as $$
  select not exists (select 1 from public.profiles where username = lower(p_username))
$$;

create function public.change_username(new_name text) returns text
language plpgsql security definer set search_path = public as $$
declare
  me public.profiles;
  n text := lower(trim(both '@' from trim(new_name)));
  disp text;
begin
  select * into me from public.profiles where id = auth.uid();
  if me.id is null then return 'not_found'; end if;
  if n !~ '^[a-z0-9._]{3,20}$' then return 'invalid'; end if;
  if n = me.username then return null; end if;
  if me.role = 'admin' then return 'admin_handle_locked'; end if;
  if n in ('koruadm', 'korucol')
     or exists (select 1 from public.profiles where username = n) then
    return 'taken';
  end if;
  if coalesce(me.handle_changed_at, me.created_at) + interval '60 days' > now() then
    return 'cooldown';
  end if;
  disp := coalesce(nullif(trim(me.display_name), ''), n);
  perform set_config('app.allow_username_change', '1', true);
  update public.profiles set username = n, handle_changed_at = now() where id = me.id;
  update public.discussion_spaces
    set author = case when author = me.username then disp else author end,
        author_handle = n
    where author_handle = me.username;
  update public.discussion_replies
    set author = case when author = me.username then disp else author end,
        author_handle = n
    where author_handle = me.username;
  update public.eco_journal_entries set username = n where username = me.username;
  update public.user_progress set username = n where username = me.username;
  return null;
end $$;

revoke all on function public.login_email(text), public.username_available(text) from public;
grant execute on function public.login_email(text), public.username_available(text) to anon, authenticated;
revoke all on function public.change_username(text) from public;
grant execute on function public.change_username(text) to authenticated;

-- Seguridad por filas -----------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.profile_private enable row level security;
alter table public.discussion_spaces enable row level security;
alter table public.discussion_replies enable row level security;
alter table public.support_requests enable row level security;
alter table public.teacher_lessons enable row level security;
alter table public.teacher_courses enable row level security;
alter table public.eco_journal_entries enable row level security;
alter table public.eco_journal_photos enable row level security;
alter table public.user_progress enable row level security;

create policy profiles_select on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_staff());
create policy profiles_update on public.profiles for update to authenticated
  using (id = auth.uid() or public.is_admin())
  with check (id = auth.uid() or public.is_admin());

create policy private_select on public.profile_private for select to authenticated
  using (id = auth.uid() or public.is_staff());

create policy spaces_select on public.discussion_spaces for select to authenticated using (true);
create policy spaces_insert on public.discussion_spaces for insert to authenticated
  with check (author_handle = public.my_username());
create policy spaces_update on public.discussion_spaces for update to authenticated
  using (author_handle = public.my_username() or public.is_staff())
  with check (author_handle = public.my_username() or public.is_staff());
create policy spaces_delete on public.discussion_spaces for delete to authenticated
  using (author_handle = public.my_username() or public.is_staff());

create policy replies_select on public.discussion_replies for select to authenticated using (true);
create policy replies_insert on public.discussion_replies for insert to authenticated
  with check (author_handle = public.my_username());
create policy replies_update on public.discussion_replies for update to authenticated
  using (author_handle = public.my_username() or public.is_staff())
  with check (author_handle = public.my_username() or public.is_staff());
create policy replies_delete on public.discussion_replies for delete to authenticated
  using (author_handle = public.my_username() or public.is_staff());

create policy support_insert on public.support_requests for insert to authenticated
  with check (username = public.my_username());
create policy support_select on public.support_requests for select to authenticated
  using (public.is_admin());
create policy support_update on public.support_requests for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy lessons_select on public.teacher_lessons for select to authenticated using (true);
create policy lessons_insert on public.teacher_lessons for insert to authenticated
  with check (public.my_role() = 'teacher' and teacher_username = public.my_username());
create policy lessons_update on public.teacher_lessons for update to authenticated
  using (public.is_admin() or (public.my_role() = 'teacher' and teacher_username = public.my_username()))
  with check (public.is_admin() or (public.my_role() = 'teacher' and teacher_username = public.my_username()));
create policy lessons_delete on public.teacher_lessons for delete to authenticated
  using (public.is_admin() or (public.my_role() = 'teacher' and teacher_username = public.my_username()));

create policy courses_select on public.teacher_courses for select to authenticated using (true);
create policy courses_insert on public.teacher_courses for insert to authenticated
  with check (public.my_role() = 'teacher' and teacher_username = public.my_username());
create policy courses_update on public.teacher_courses for update to authenticated
  using (public.is_admin() or (public.my_role() = 'teacher' and teacher_username = public.my_username()))
  with check (public.is_admin() or (public.my_role() = 'teacher' and teacher_username = public.my_username()));
create policy courses_delete on public.teacher_courses for delete to authenticated
  using (public.is_admin() or (public.my_role() = 'teacher' and teacher_username = public.my_username()));

create policy eco_entries_all on public.eco_journal_entries for all to authenticated
  using (username = public.my_username()) with check (username = public.my_username());
create policy eco_photos_all on public.eco_journal_photos for all to authenticated
  using (exists (select 1 from public.eco_journal_entries e
                 where e.id = entry_id and e.username = public.my_username()))
  with check (exists (select 1 from public.eco_journal_entries e
                      where e.id = entry_id and e.username = public.my_username()));

create policy progress_select on public.user_progress for select to authenticated
  using (username = public.my_username() or public.is_staff());
create policy progress_insert on public.user_progress for insert to authenticated
  with check (username = public.my_username());
create policy progress_update on public.user_progress for update to authenticated
  using (username = public.my_username()) with check (username = public.my_username());

-- Espacios iniciales de la comunidad ---------------------------------------------
insert into public.discussion_spaces (title, description, author, author_handle) values
  ('Ideas para cuidar el planeta', 'Comparte acciones sencillas que podemos aplicar cada día.', 'KoruCol', 'korucol'),
  ('Preguntas sobre las lecciones', 'Ayuda a otros usuarios y resuelve tus dudas.', 'KoruCol', 'korucol');
insert into public.discussion_replies (discussion_id, author, author_handle, message)
  select id, 'KoruCol', 'korucol', '¡Todas las ideas son bienvenidas!'
  from public.discussion_spaces where title = 'Ideas para cuidar el planeta';

-- Para crear el primer administrador: registra tu cuenta en la app y luego ejecuta
--   update public.profiles set role = 'admin' where username = 'TU_USUARIO';
