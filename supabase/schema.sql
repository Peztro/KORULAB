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
  resolved_at timestamptz,
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
  using (id = auth.uid());

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
  if request_row.status = 'Resuelta' then
    raise exception 'Esta PQRS ya está resuelta y no puede cambiar de estado.';
  end if;
  if request_row.status = p_status then
    return;
  end if;

  update public.support_requests
  set status = p_status,
      resolved_at = case when p_status = 'Resuelta' then now() else null end
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

-- Fotos de perfil y banners en Storage ---------------------------------------
-- Cada usuario solo escribe en profile-images/<user id>/.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'profile-images',
  'profile-images',
  true,
  5 * 1024 * 1024,
  array['image/png', 'image/jpeg', 'image/webp', 'image/gif']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- El bucket es público para leer; solo el dueño escribe en su carpeta.
-- Leer la fila propia es necesario para subir con upsert.
drop policy if exists profile_images_select on storage.objects;
create policy profile_images_select on storage.objects for select to authenticated
  using (
    bucket_id = 'profile-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists profile_images_insert on storage.objects;
create policy profile_images_insert on storage.objects for insert to authenticated
  with check (
    bucket_id = 'profile-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists profile_images_update on storage.objects;
create policy profile_images_update on storage.objects for update to authenticated
  using (
    bucket_id = 'profile-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'profile-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists profile_images_delete on storage.objects;
create policy profile_images_delete on storage.objects for delete to authenticated
  using (
    bucket_id = 'profile-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Las URLs solo pueden apuntar a este bucket, para que nadie ponga en su
-- perfil una imagen externa (por ejemplo, un píxel de rastreo).
-- Los valores base64 antiguos no empiezan por http y siguen siendo válidos.
alter table public.profiles drop constraint if exists profiles_image_urls_check;
alter table public.profiles add constraint profiles_image_urls_check check (
  (profile_photo is null or profile_photo !~ '^https?://'
    or profile_photo like 'https://rnsxdjmywwweqkrxasjg.supabase.co/storage/v1/object/public/profile-images/%')
  and
  (banner is null or banner !~ '^https?://'
    or banner like 'https://rnsxdjmywwweqkrxasjg.supabase.co/storage/v1/object/public/profile-images/%')
);

-- Espacios iniciales de la comunidad ---------------------------------------------
insert into public.discussion_spaces (title, description, author, author_handle) values
  ('Ideas para cuidar el planeta', 'Comparte acciones sencillas que podemos aplicar cada día.', 'KoruCol', 'korucol'),
  ('Preguntas sobre las lecciones', 'Ayuda a otros usuarios y resuelve tus dudas.', 'KoruCol', 'korucol');
insert into public.discussion_replies (discussion_id, author, author_handle, message)
  select id, 'KoruCol', 'korucol', '¡Todas las ideas son bienvenidas!'
  from public.discussion_spaces where title = 'Ideas para cuidar el planeta';

-- Para crear el primer administrador: registra tu cuenta en la app y luego ejecuta
--   update public.profiles set role = 'admin' where username = 'TU_USUARIO';

-- Amigos y mensajes privados ----------------------------------------------
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

-- Imágenes en los chats privados ----------------------------------------
-- Columna para la imagen; el texto pasa a ser opcional si hay imagen.
alter table public.direct_messages
  add column if not exists image_path text;

alter table public.direct_messages
  drop constraint if exists direct_messages_body_check;
alter table public.direct_messages
  alter column body set default '';
alter table public.direct_messages
  drop constraint if exists direct_messages_contenido_check;
alter table public.direct_messages
  add constraint direct_messages_contenido_check check (
    length(body) <= 2000
    and (length(trim(body)) > 0 or image_path is not null)
  );

-- La imagen debe estar en la carpeta de quien envía.
drop policy if exists direct_messages_insert on public.direct_messages;
create policy direct_messages_insert on public.direct_messages for insert to authenticated
  with check (
    sender_id = auth.uid()
    and read_at is null
    and public.can_message(recipient_id)
    and (image_path is null or image_path like auth.uid()::text || '/%')
  );

-- Bucket privado -------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'chat-images',
  'chat-images',
  false,
  5 * 1024 * 1024,
  array['image/png', 'image/jpeg', 'image/webp', 'image/gif']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Subir: solo en tu carpeta.
drop policy if exists chat_images_insert on storage.objects;
create policy chat_images_insert on storage.objects for insert to authenticated
  with check (
    bucket_id = 'chat-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Ver: tus propias subidas o las imágenes de mensajes que te enviaron.
drop policy if exists chat_images_select on storage.objects;
create policy chat_images_select on storage.objects for select to authenticated
  using (
    bucket_id = 'chat-images'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or exists (
        select 1 from public.direct_messages m
        where m.image_path = storage.objects.name
          and (m.sender_id = auth.uid() or m.recipient_id = auth.uid())
      )
    )
  );

-- Borrar: solo tus propias subidas.
drop policy if exists chat_images_delete on storage.objects;
create policy chat_images_delete on storage.objects for delete to authenticated
  using (
    bucket_id = 'chat-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- La lista de chats muestra "📷 Foto" cuando el último mensaje es una imagen.
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
    select distinct on (partner) partner, body, image_path, created_at, sender_id
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
    case
      when l.image_path is not null and length(trim(l.body)) = 0 then '📷 Foto'
      when l.image_path is not null then '📷 ' || l.body
      else l.body
    end,
    l.created_at,
    l.sender_id = auth.uid(),
    coalesce(u.total, 0)
  from last_message l
  join public.profiles p on p.id = l.partner
  left join unread u on u.partner = l.partner
  order by l.created_at desc
$$;

-- Amistades automáticas por rol -----------------------------------------
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
-- Ranking global de DiverKoru.
--
-- Guarda el mejor puntaje de cada cuenta en cada juego. Nadie escribe ni lee
-- la tabla directamente: se usa con dos funciones.
--   * registrar_record_diverkoru: guarda el puntaje si supera el anterior.
--   * ranking_diverkoru: los mejores estudiantes de un juego, más tu puesto.
-- En el ranking solo aparecen estudiantes; cualquier cuenta puede verlo.

create table if not exists public.diverkoru_records (
  user_id uuid not null references public.profiles(id) on delete cascade,
  juego text not null check (juego in ('clasifica', 'trivia', 'sopa', 'gotas')),
  puntos int not null check (puntos between 0 and 100000),
  logrado_en timestamptz not null default now(),
  primary key (user_id, juego)
);

create index if not exists diverkoru_records_juego_puntos
  on public.diverkoru_records (juego, puntos desc, logrado_en);

-- Sin políticas: la tabla solo se usa a través de las funciones de abajo.
alter table public.diverkoru_records enable row level security;

-- Guarda p_puntos si superan tu récord. Devuelve tu mejor puntaje.
create or replace function public.registrar_record_diverkoru(
  p_juego text,
  p_puntos int
)
returns int
language plpgsql security definer set search_path = public as $$
declare
  yo uuid := auth.uid();
  mejor int;
begin
  if yo is null then
    raise exception 'No autenticado';
  end if;
  if p_puntos is null or p_puntos < 0 or p_puntos > 100000 then
    raise exception 'Puntaje no válido';
  end if;

  insert into public.diverkoru_records (user_id, juego, puntos)
  values (yo, p_juego, p_puntos)
  on conflict (user_id, juego) do update
    set puntos = excluded.puntos, logrado_en = now()
    where public.diverkoru_records.puntos < excluded.puntos;

  select puntos into mejor
  from public.diverkoru_records
  where user_id = yo and juego = p_juego;
  return mejor;
end $$;

-- Los p_limite mejores estudiantes de p_juego, y tu fila aunque no estés
-- entre ellos (soy_yo = true). Empates: gana quien lo logró primero.
create or replace function public.ranking_diverkoru(
  p_juego text,
  p_limite int default 10
)
returns table (
  posicion bigint,
  username text,
  display_name text,
  profile_photo text,
  puntos int,
  soy_yo boolean
)
language sql stable security definer set search_path = public as $$
  with tabla as (
    select
      row_number() over (order by r.puntos desc, r.logrado_en asc) as posicion,
      p.username,
      p.display_name,
      p.profile_photo,
      r.puntos,
      r.user_id = auth.uid() as soy_yo
    from public.diverkoru_records r
    join public.profiles p on p.id = r.user_id
    where r.juego = p_juego
      and p.role = 'student'
  )
  select * from tabla
  where posicion <= least(greatest(coalesce(p_limite, 10), 1), 50)
     or soy_yo
  order by posicion
$$;

revoke all on function public.registrar_record_diverkoru(text, int) from public, anon;
revoke all on function public.ranking_diverkoru(text, int) from public, anon;
grant execute on function public.registrar_record_diverkoru(text, int) to authenticated;
grant execute on function public.ranking_diverkoru(text, int) to authenticated;
-- Ranking global de DiverKoru para todos los juegos.
--
-- Reemplaza a 20261129_diverkoru_ranking.sql (no hace falta haberlo
-- ejecutado: este archivo crea lo que falte).
--
-- Juegos y qué se guarda en "puntos":
--   * clasifica     objetos bien separados   (gana el mayor)
--   * trivia        respuestas correctas      (gana el mayor)
--   * gotas         gotas salvadas            (gana el mayor)
--   * sopa_facil, sopa_medio, sopa_dificil
--                   segundos en completarla   (gana el MENOR)
-- En el ranking solo aparecen estudiantes; cualquier cuenta puede verlo.

create table if not exists public.diverkoru_records (
  user_id uuid not null references public.profiles(id) on delete cascade,
  juego text not null,
  puntos int not null check (puntos between 0 and 100000),
  logrado_en timestamptz not null default now(),
  primary key (user_id, juego)
);

-- Clasifica y Trivia cambiaron de reglas y la sopa ahora va por modos:
-- sus marcas viejas ya no sirven. Salva las gotas se conserva.
delete from public.diverkoru_records where juego <> 'gotas';

alter table public.diverkoru_records
  drop constraint if exists diverkoru_records_juego_check;
alter table public.diverkoru_records
  add constraint diverkoru_records_juego_check check (juego in (
    'clasifica', 'trivia', 'gotas', 'sopa_facil', 'sopa_medio', 'sopa_dificil'
  ));

create index if not exists diverkoru_records_juego_puntos
  on public.diverkoru_records (juego, puntos desc, logrado_en);

-- Sin políticas: la tabla solo se usa a través de las funciones de abajo.
alter table public.diverkoru_records enable row level security;

-- ¿En este juego gana el menor valor (tiempo)?
create or replace function public.diverkoru_menor_es_mejor(p_juego text)
returns boolean
language sql immutable as $$
  select p_juego like 'sopa\_%'
$$;

-- Guarda p_puntos si mejoran tu récord. Devuelve tu mejor marca.
create or replace function public.registrar_record_diverkoru(
  p_juego text,
  p_puntos int
)
returns int
language plpgsql security definer set search_path = public as $$
declare
  yo uuid := auth.uid();
  menor boolean := public.diverkoru_menor_es_mejor(p_juego);
  mejor int;
begin
  if yo is null then
    raise exception 'No autenticado';
  end if;
  if p_puntos is null or p_puntos <= 0 or p_puntos > 100000 then
    raise exception 'Marca no válida';
  end if;

  insert into public.diverkoru_records (user_id, juego, puntos)
  values (yo, p_juego, p_puntos)
  on conflict (user_id, juego) do update
    set puntos = excluded.puntos, logrado_en = now()
    where (menor and excluded.puntos < public.diverkoru_records.puntos)
       or (not menor and excluded.puntos > public.diverkoru_records.puntos);

  select puntos into mejor
  from public.diverkoru_records
  where user_id = yo and juego = p_juego;
  return mejor;
end $$;

-- Los p_limite mejores estudiantes de p_juego, y tu fila aunque no estés
-- entre ellos (soy_yo = true). Empates: gana quien lo logró primero.
create or replace function public.ranking_diverkoru(
  p_juego text,
  p_limite int default 10
)
returns table (
  posicion bigint,
  username text,
  display_name text,
  profile_photo text,
  puntos int,
  soy_yo boolean
)
language sql stable security definer set search_path = public as $$
  with tabla as (
    select
      row_number() over (
        order by
          case when public.diverkoru_menor_es_mejor(p_juego) then r.puntos end asc,
          case when not public.diverkoru_menor_es_mejor(p_juego) then r.puntos end desc,
          r.logrado_en asc
      ) as posicion,
      p.username,
      p.display_name,
      p.profile_photo,
      r.puntos,
      r.user_id = auth.uid() as soy_yo
    from public.diverkoru_records r
    join public.profiles p on p.id = r.user_id
    where r.juego = p_juego
      and p.role = 'student'
  )
  select * from tabla
  where posicion <= least(greatest(coalesce(p_limite, 10), 1), 50)
     or soy_yo
  order by posicion
$$;

revoke all on function public.registrar_record_diverkoru(text, int) from public, anon;
revoke all on function public.ranking_diverkoru(text, int) from public, anon;
grant execute on function public.registrar_record_diverkoru(text, int) to authenticated;
grant execute on function public.ranking_diverkoru(text, int) to authenticated;
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
-- El progreso de aprendizaje es privado en el perfil público.
--
-- Las lecciones completadas, la racha y la cantidad de respuestas en
-- Korublog solo se entregan si quien mira es la misma persona, un profesor o
-- un administrador. A los demás les llegan vacías (null) y "ver_progreso"
-- vale false, así la app sabe que debe ocultarlas.

create or replace function public.get_public_profile(p_username text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  handle text := lower(trim(both '@' from trim(p_username)));
  mi_rol text;
  mi_usuario text;
  ve boolean;
  result jsonb;
begin
  if auth.uid() is null then
    raise exception 'Debes iniciar sesión.';
  end if;

  select role, username into mi_rol, mi_usuario
  from public.profiles where id = auth.uid();
  ve := coalesce(mi_rol in ('teacher', 'admin'), false)
        or coalesce(mi_usuario = handle, false);

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
    'ver_progreso', ve,
    'completed_lessons', case when ve then coalesce(
      jsonb_array_length(up.data -> 'korulab_course_progress_'), 0) end,
    'daily_streak', case when ve then
      coalesce((up.data ->> 'korulab_daily_streak_')::int, 0) end,
    'posts_count', (
      select count(*) from public.discussion_spaces d
      where d.author_handle = p.username),
    'replies_count', case when ve then (
      select count(*) from public.discussion_replies r
      where r.author_handle = p.username) end
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
