-- Imágenes en los chats privados.
--
-- Las fotos van a un bucket PRIVADO: solo las ven las dos personas de la
-- conversación, con enlaces firmados de duración limitada.
-- Ruta de cada archivo: chat-images/<id de quien envía>/<nombre>.
-- Requiere 20261126_amigos_y_chats.sql.

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
