alter table public.profiles
  add column if not exists gender text
  check (gender in ('female', 'male', 'non_binary', 'unspecified'));
