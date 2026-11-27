import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korulab/modelos/imagen_perfil.dart';

void main() {
  group('ImagenPerfil.desde', () {
    test('una URL de Storage se usa tal cual y no hay que subirla', () {
      const url =
          'https://x.supabase.co/storage/v1/object/public/profile-images/u/avatar?v=1';
      final imagen = ImagenPerfil.desde(url)!;
      expect(imagen.url, url);
      expect(imagen.pendienteDeSubir, isFalse);
      expect(imagen.provider, isA<NetworkImage>());
    });

    test(
      'un valor base64 antiguo se decodifica y queda pendiente de subir',
      () {
        final bytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]);
        final imagen = ImagenPerfil.desde(base64Encode(bytes))!;
        expect(imagen.bytes, bytes);
        expect(imagen.pendienteDeSubir, isTrue);
        expect(imagen.provider, isA<MemoryImage>());
      },
    );

    test('acepta bytes y devuelve la misma ImagenPerfil si ya lo es', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final imagen = ImagenPerfil.desde(bytes)!;
      expect(imagen.bytes, same(bytes));
      expect(ImagenPerfil.desde(imagen), same(imagen));
    });

    test('valores vacíos o inválidos dan null', () {
      expect(ImagenPerfil.desde(null), isNull);
      expect(ImagenPerfil.desde(''), isNull);
      expect(ImagenPerfil.desde(Uint8List(0)), isNull);
      expect(ImagenPerfil.desde('esto no es base64!!'), isNull);
      expect(ImagenPerfil.desde(42), isNull);
    });
  });

  group('ImagenPerfil.tipoMime', () {
    Uint8List b(List<int> v) => Uint8List.fromList(v);

    test('reconoce los formatos de imagen habituales', () {
      expect(
        ImagenPerfil.tipoMime(b([0x89, 0x50, 0x4E, 0x47, 0])),
        'image/png',
      );
      expect(ImagenPerfil.tipoMime(b([0xFF, 0xD8, 0xFF, 0xE0])), 'image/jpeg');
      expect(ImagenPerfil.tipoMime(b([0x47, 0x49, 0x46, 0x38])), 'image/gif');
      expect(
        ImagenPerfil.tipoMime(
          b([0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50]),
        ),
        'image/webp',
      );
    });

    test('devuelve un tipo genérico para bytes desconocidos o cortos', () {
      expect(
        ImagenPerfil.tipoMime(b([1, 2, 3, 4])),
        'application/octet-stream',
      );
      expect(ImagenPerfil.tipoMime(b([0x89])), 'application/octet-stream');
    });
  });
}
