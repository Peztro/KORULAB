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
