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
