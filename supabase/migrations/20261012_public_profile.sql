-- Perfil público visible para cualquier usuario autenticado desde Korublog.
-- Solo expone datos no sensibles: sin correo, edad ni año de nacimiento.
create or replace function public.get_public_profile(p_username text)
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
