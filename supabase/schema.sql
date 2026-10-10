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
  gender text check (gender in ('female', 'male', 'non_binary', 'unspecified')),
  profile_photo text,
  banner text,
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
  is_pinned boolean not null default false,
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

create table public.messages (
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
create index messages_recipient_created_idx
  on public.messages (recipient_username, created_at desc);
grant select, insert on public.messages to authenticated;
grant usage, select on sequence public.messages_id_seq to authenticated;

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

create function public.set_discussion_pinned(
  p_discussion_id bigint,
  p_is_pinned boolean
) returns boolean
language plpgsql security invoker set search_path = public as $$
begin
  if not public.is_admin() then
    raise exception 'Solo los administradores pueden fijar discusiones.';
  end if;
  update public.discussion_spaces
    set is_pinned = p_is_pinned
    where id = p_discussion_id;
  return found;
end $$;

create function public.guard_discussion_pin_update() returns trigger
language plpgsql set search_path = public as $$
begin
  if old.is_pinned is distinct from new.is_pinned
     and not public.is_admin() then
    raise exception 'Solo los administradores pueden fijar discusiones.';
  end if;
  return new;
end $$;
create trigger guard_discussion_pin_update
  before update of is_pinned on public.discussion_spaces
  for each row execute function public.guard_discussion_pin_update();

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
revoke all on function public.set_discussion_pinned(bigint, boolean) from public;
grant execute on function public.set_discussion_pinned(bigint, boolean) to authenticated;

create function public.admin_delete_user(p_username text)
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  target_username text := lower(trim(both '@' from trim(p_username)));
  target_id uuid;
  target_role text;
begin
  if not public.is_admin() then
    raise exception 'Solo los administradores pueden eliminar cuentas.';
  end if;
  if target_username is null or target_username = ''
     or target_username = public.my_username()
     or target_username in ('koruadm', 'korucol') then
    raise exception 'No se puede eliminar esta cuenta.';
  end if;

  select p.id, p.role
    into target_id, target_role
    from public.profiles p
    where p.username = target_username
    for update;

  if target_id is null then
    raise exception 'No se encontró la cuenta.';
  end if;
  if target_role not in ('student', 'teacher') then
    raise exception 'Solo se pueden eliminar cuentas de estudiantes o profesores.';
  end if;

  delete from public.teacher_courses where teacher_username = target_username;
  delete from public.teacher_lessons where teacher_username = target_username;
  delete from public.discussion_replies where author_handle = target_username;
  delete from public.discussion_spaces where author_handle = target_username;
  delete from public.eco_journal_entries where username = target_username;
  delete from public.messages
    where sender_username = target_username
       or recipient_username = target_username;
  delete from public.support_requests where username = target_username;
  delete from public.user_progress where username = target_username;

  delete from auth.users where id = target_id;
  return target_id;
end
$$;

revoke all on function public.admin_delete_user(text) from public;
grant execute on function public.admin_delete_user(text) to authenticated;

create function public.get_public_profile(p_username text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  handle text := lower(trim(both '@' from trim(p_username)));
  result jsonb;
begin
  if auth.uid() is null then
    raise exception 'Debes iniciar sesión.';
  end if;

  select jsonb_build_object(
    'username', p.username,
    'display_name', p.display_name,
    'bio', p.bio,
    'location', p.location,
    'occupation', p.occupation,
    'learning_goal', p.learning_goal,
    'profile_photo', p.profile_photo,
    'banner', p.banner,
    'role', p.role,
    'created_at', p.created_at,
    'completed_lessons', coalesce(
      jsonb_array_length(up.data -> 'korulab_course_progress_'), 0),
    'daily_streak', coalesce((up.data ->> 'korulab_daily_streak_')::int, 0),
    'posts_count', (
      select count(*) from public.discussion_spaces d
      where d.author_handle = p.username),
    'replies_count', (
      select count(*) from public.discussion_replies r
      where r.author_handle = p.username)
  )
  into result
  from public.profiles p
  left join public.user_progress up on up.username = p.username
  where p.username = handle;

  return result;
end
$$;

revoke all on function public.get_public_profile(text) from public;
grant execute on function public.get_public_profile(text) to authenticated;

-- Seguridad por filas -----------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.profile_private enable row level security;
alter table public.discussion_spaces enable row level security;
alter table public.discussion_replies enable row level security;
alter table public.support_requests enable row level security;
alter table public.messages enable row level security;
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

create policy messages_select on public.messages for select to authenticated
  using (
    recipient_username = public.my_username()
    or recipient_username = '*'
  );
create policy messages_insert_broadcast on public.messages for insert to authenticated
  with check (
    sender_username = public.my_username()
    and public.my_role() in ('admin', 'teacher')
    and recipient_username = '*'
    and kind = 'general'
    and support_request_id is null
  );

create function public.update_support_request_status(
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
