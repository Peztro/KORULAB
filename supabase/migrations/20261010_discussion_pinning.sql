alter table public.discussion_spaces
  add column if not exists is_pinned boolean not null default false;

create or replace function public.guard_discussion_pin_update() returns trigger
language plpgsql set search_path = public as $$
begin
  if old.is_pinned is distinct from new.is_pinned
     and not public.is_admin() then
    raise exception 'Solo los administradores pueden fijar discusiones.';
  end if;
  return new;
end $$;

drop trigger if exists guard_discussion_pin_update on public.discussion_spaces;
create trigger guard_discussion_pin_update
  before update of is_pinned on public.discussion_spaces
  for each row execute function public.guard_discussion_pin_update();

create or replace function public.set_discussion_pinned(
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

revoke all on function public.set_discussion_pinned(bigint, boolean) from public;
grant execute on function public.set_discussion_pinned(bigint, boolean) to authenticated;
