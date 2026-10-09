create or replace function public.admin_delete_user(p_username text)
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
