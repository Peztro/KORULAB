-- Fotos de perfil y banners en Supabase Storage en lugar de base64 en la tabla.
--
-- La app sube cada imagen a profile-images/<user id>/avatar y
-- profile-images/<user id>/banner, y guarda su URL pública en las columnas
-- de siempre (profiles.profile_photo y profiles.banner). Las filas antiguas
-- en base64 siguen funcionando: la app las muestra y las sube a Storage la
-- próxima vez que el usuario guarda su perfil.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'profile-images',
  'profile-images',
  true,
  5 * 1024 * 1024,
  array['image/png', 'image/jpeg', 'image/webp', 'image/gif']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- El bucket es público para leer; solo el dueño escribe en su carpeta.
drop policy if exists profile_images_insert on storage.objects;
create policy profile_images_insert on storage.objects for insert to authenticated
  with check (
    bucket_id = 'profile-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists profile_images_update on storage.objects;
create policy profile_images_update on storage.objects for update to authenticated
  using (
    bucket_id = 'profile-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'profile-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists profile_images_delete on storage.objects;
create policy profile_images_delete on storage.objects for delete to authenticated
  using (
    bucket_id = 'profile-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Las URLs solo pueden apuntar a este bucket, para que nadie ponga en su
-- perfil una imagen externa (por ejemplo, un píxel de rastreo).
-- Los valores base64 antiguos no empiezan por http y siguen siendo válidos.
alter table public.profiles drop constraint if exists profiles_image_urls_check;
alter table public.profiles add constraint profiles_image_urls_check check (
  (profile_photo is null or profile_photo !~ '^https?://'
    or profile_photo like 'https://rnsxdjmywwweqkrxasjg.supabase.co/storage/v1/object/public/profile-images/%')
  and
  (banner is null or banner !~ '^https?://'
    or banner like 'https://rnsxdjmywwweqkrxasjg.supabase.co/storage/v1/object/public/profile-images/%')
);
