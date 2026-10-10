drop policy if exists private_select on public.profile_private;
create policy private_select on public.profile_private for select to authenticated
  using (id = auth.uid());
