-- Permite que Ruta Eko reciba cursos y lecciones nuevas o modificadas en tiempo real.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'teacher_lessons'
  ) then
    alter publication supabase_realtime add table public.teacher_lessons;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'teacher_courses'
  ) then
    alter publication supabase_realtime add table public.teacher_courses;
  end if;
end $$;
