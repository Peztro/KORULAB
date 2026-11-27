-- La app sube las fotos con "upsert" (sobrescribir si ya existe). Para eso
-- Supabase Storage exige, además de insertar y actualizar, poder LEER la fila
-- del archivo en storage.objects. Sin esta política la subida falla con
-- "new row violates row-level security policy".
--
-- Solo da lectura de los metadatos de los archivos propios; las imágenes ya
-- son públicas por URL porque el bucket es público.

drop policy if exists profile_images_select on storage.objects;
create policy profile_images_select on storage.objects for select to authenticated
  using (
    bucket_id = 'profile-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
