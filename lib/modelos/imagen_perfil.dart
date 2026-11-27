import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// Foto de perfil o banner.
///
/// Puede venir de tres sitios:
/// - una URL pública de Supabase Storage (lo normal a partir de ahora),
/// - un valor base64 antiguo guardado en la tabla `profiles`,
/// - bytes recién elegidos en la galería que aún no se han subido.
///
/// Las imágenes con [bytes] se suben a Storage la próxima vez que se guarda
/// el perfil, así que las fotos antiguas en base64 se migran solas.
@immutable
class ImagenPerfil {
  const ImagenPerfil.url(String this.url) : bytes = null;
  const ImagenPerfil.bytes(Uint8List this.bytes) : url = null;

  final String? url;
  final Uint8List? bytes;

  /// Hay que subirla a Storage antes de guardarla en la base de datos.
  bool get pendienteDeSubir => bytes != null;

  ImageProvider get provider =>
      bytes != null ? MemoryImage(bytes!) : NetworkImage(url!);

  /// Interpreta lo que llega de la base de datos o de SharedPreferences.
  static ImagenPerfil? desde(Object? valor) {
    if (valor is ImagenPerfil) return valor;
    if (valor is Uint8List)
      return valor.isEmpty ? null : ImagenPerfil.bytes(valor);
    if (valor is! String || valor.isEmpty) return null;
    if (valor.startsWith('http://') || valor.startsWith('https://')) {
      return ImagenPerfil.url(valor);
    }
    try {
      final decoded = base64Decode(valor);
      return decoded.isEmpty ? null : ImagenPerfil.bytes(decoded);
    } on FormatException {
      return null;
    }
  }

  /// Tipo MIME según la firma de los bytes (PNG, JPEG, WebP o GIF).
  static String tipoMime(Uint8List bytes) {
    bool empiezaCon(List<int> firma) =>
        bytes.length >= firma.length &&
        Iterable.generate(firma.length).every((i) => bytes[i] == firma[i]);
    if (empiezaCon(const [0x89, 0x50, 0x4E, 0x47])) return 'image/png';
    if (empiezaCon(const [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
    if (empiezaCon(const [0x47, 0x49, 0x46])) return 'image/gif';
    if (bytes.length >= 12 &&
        empiezaCon(const [0x52, 0x49, 0x46, 0x46]) &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return 'application/octet-stream';
  }

  @override
  bool operator ==(Object other) =>
      other is ImagenPerfil &&
      other.url == url &&
      identical(other.bytes, bytes);

  @override
  int get hashCode =>
      Object.hash(url, bytes == null ? null : identityHashCode(bytes));
}
