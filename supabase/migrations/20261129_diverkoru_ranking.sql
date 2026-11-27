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
