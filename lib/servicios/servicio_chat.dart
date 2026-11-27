import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../modelos/chat.dart';
import '../modelos/imagen_perfil.dart';
import '../servicio_bd.dart';

/// Amigos y mensajes privados sobre Supabase.
/// Las reglas (quién puede escribir a quién) están en la base de datos:
/// supabase/migrations/20261126_amigos_y_chats.sql.
class ServicioChat {
  ServicioChat._();

  static SupabaseClient get _db => Supabase.instance.client;

  static String? get miId => _db.auth.currentUser?.id;

  static List<Map<String, dynamic>> _filas(dynamic data) => [
    for (final fila in data as List) Map<String, dynamic>.from(fila as Map),
  ];

  // ── Amigos ────────────────────────────────────────────────────────────

  static Future<List<Amistad>> misAmistades() async {
    final data = await _db.rpc('my_friendships');
    return _filas(data).map(Amistad.desdeFila).toList();
  }

  /// Busca personas por @usuario o nombre (sin incluirte a ti).
  static Future<List<Contacto>> buscar(String texto) async {
    final limpio = texto.trim().replaceFirst(RegExp(r'^@+'), '');
    if (limpio.length < 2) return [];
    // Evita que comodines del usuario alteren el filtro.
    final patron = '%${limpio.replaceAll(RegExp(r'[%_,()]'), '')}%';
    final data = await _db
        .from('public_profiles')
        .select('id, username, display_name, profile_photo, role')
        .or('username.ilike.$patron,display_name.ilike.$patron')
        .neq('id', miId ?? '')
        .order('username')
        .limit(30);
    return _filas(data).map(Contacto.desdeFila).toList();
  }

  static Future<List<Contacto>> profesores() async {
    final data = await _db
        .from('public_profiles')
        .select('id, username, display_name, profile_photo, role')
        .eq('role', DBService.roleTeacher)
        .neq('id', miId ?? '')
        .order('display_name');
    return _filas(data).map(Contacto.desdeFila).toList();
  }

  static Future<Contacto?> contactoPorUsuario(String username) async {
    final data = await _db
        .from('public_profiles')
        .select('id, username, display_name, profile_photo, role')
        .eq('username', DBService.normalizeUsername(username))
        .limit(1);
    final filas = _filas(data);
    return filas.isEmpty ? null : Contacto.desdeFila(filas.first);
  }

  /// Envía una solicitud. Devuelve un texto para mostrar al usuario.
  static Future<String> enviarSolicitud(String username) async {
    final resultado = await _db.rpc(
      'send_friend_request',
      params: {'p_username': DBService.normalizeUsername(username)},
    );
    return switch (resultado) {
      'sent' => 'Solicitud enviada a @$username.',
      'accepted' => '¡Ahora tú y @$username son amigos!',
      'pending' => 'Ya le enviaste una solicitud a @$username.',
      'friends' => 'Tú y @$username ya son amigos.',
      'self' => 'No puedes agregarte a ti mismo.',
      _ => 'No se encontró a @$username.',
    };
  }

  static Future<void> responderSolicitud(int id, {required bool aceptar}) => _db
      .rpc('respond_friend_request', params: {'p_id': id, 'p_accept': aceptar});

  /// Cancela una solicitud enviada o elimina a un amigo.
  static Future<void> eliminarAmistad(int id) =>
      _db.from('friendships').delete().eq('id', id);

  static RelacionAmistad relacionCon(String contactoId, List<Amistad> todas) {
    for (final a in todas) {
      if (a.contacto.id != contactoId) continue;
      if (a.aceptada) return RelacionAmistad.amigos;
      return a.entrante ? RelacionAmistad.recibida : RelacionAmistad.enviada;
    }
    return RelacionAmistad.ninguna;
  }

  // ── Mensajes ──────────────────────────────────────────────────────────

  static Future<List<Conversacion>> misConversaciones() async {
    final data = await _db.rpc('my_conversations');
    return _filas(data).map(Conversacion.desdeFila).toList();
  }

  /// Últimos [limite] mensajes con [otroId], del más antiguo al más nuevo.
  static Future<List<MensajeDirecto>> mensajesCon(
    String otroId, {
    int limite = 200,
  }) async {
    final yo = miId;
    if (yo == null) return [];
    final data = await _db
        .from('direct_messages')
        .select()
        .or(
          'and(sender_id.eq.$yo,recipient_id.eq.$otroId),'
          'and(sender_id.eq.$otroId,recipient_id.eq.$yo)',
        )
        .order('created_at', ascending: false)
        .limit(limite);
    return _filas(
      data,
    ).map(MensajeDirecto.desdeFila).toList().reversed.toList();
  }

  static Future<MensajeDirecto> enviarMensaje(
    String otroId,
    String texto,
  ) async {
    final fila = await _db
        .from('direct_messages')
        .insert({
          'sender_id': miId,
          'recipient_id': otroId,
          'body': texto.trim(),
        })
        .select()
        .single();
    return MensajeDirecto.desdeFila(fila);
  }

  static const _bucketImagenes = 'chat-images';

  /// Sube [bytes] al bucket privado y envía el mensaje con la imagen.
  static Future<MensajeDirecto> enviarImagen(
    String otroId,
    Uint8List bytes, {
    String texto = '',
  }) async {
    final yo = miId;
    if (yo == null) throw StateError('Debes iniciar sesión.');
    final tipo = ImagenPerfil.tipoMime(bytes);
    final extension = switch (tipo) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/gif' => 'gif',
      _ => 'jpg',
    };
    final ruta = '$yo/${DateTime.now().microsecondsSinceEpoch}.$extension';
    await _db.storage
        .from(_bucketImagenes)
        .uploadBinary(
          ruta,
          bytes,
          fileOptions: FileOptions(
            contentType: tipo == 'application/octet-stream'
                ? 'image/jpeg'
                : tipo,
          ),
        );
    try {
      final fila = await _db
          .from('direct_messages')
          .insert({
            'sender_id': yo,
            'recipient_id': otroId,
            'body': texto.trim(),
            'image_path': ruta,
          })
          .select()
          .single();
      return MensajeDirecto.desdeFila(fila);
    } catch (_) {
      // Si el mensaje no se pudo guardar, no dejamos la imagen huérfana.
      unawaited(
        _db.storage.from(_bucketImagenes).remove([ruta]).catchError((Object e) {
          debugPrint('No se pudo borrar la imagen huérfana: $e');
          return <FileObject>[];
        }),
      );
      rethrow;
    }
  }

  // Enlaces firmados ya generados, para no pedirlos en cada redibujado.
  static final Map<String, ({String url, DateTime vence})> _urls = {};

  /// Enlace temporal (1 hora) para ver una imagen del chat.
  static Future<String> urlImagen(String ruta) async {
    final guardada = _urls[ruta];
    if (guardada != null &&
        guardada.vence.isAfter(
          DateTime.now().add(const Duration(minutes: 5)),
        )) {
      return guardada.url;
    }
    final url = await _db.storage
        .from(_bucketImagenes)
        .createSignedUrl(ruta, 3600);
    _urls[ruta] = (
      url: url,
      vence: DateTime.now().add(const Duration(hours: 1)),
    );
    return url;
  }

  static Future<bool> puedeEscribirA(String otroId) async {
    final resultado = await _db.rpc('can_message', params: {'p_other': otroId});
    return resultado == true;
  }

  static Future<void> marcarLeidos(String otroId) async {
    try {
      await _db.rpc('mark_conversation_read', params: {'p_partner': otroId});
    } catch (e) {
      debugPrint('No se pudieron marcar como leídos: $e');
    }
  }

  /// Solicitudes recibidas y mensajes sin leer.
  static Future<({int solicitudes, int noLeidos})> pendientes() async {
    try {
      final data = _filas(await _db.rpc('my_pending_counts'));
      if (data.isEmpty) return (solicitudes: 0, noLeidos: 0);
      return (
        solicitudes: (data.first['requests'] as num?)?.toInt() ?? 0,
        noLeidos: (data.first['unread'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('No se pudieron contar los pendientes: $e');
      return (solicitudes: 0, noLeidos: 0);
    }
  }

  /// Escucha mensajes nuevos y cambios de amistad que te afectan.
  /// Llama a [alCambiar] con cada mensaje nuevo (o null si fue una amistad).
  static RealtimeChannel escuchar(
    String nombreCanal,
    void Function(MensajeDirecto? mensaje) alCambiar,
  ) {
    return _db
        .channel(nombreCanal)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'direct_messages',
          callback: (payload) {
            try {
              alCambiar(MensajeDirecto.desdeFila(payload.newRecord));
            } catch (e) {
              debugPrint('Mensaje en tiempo real no válido: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'friendships',
          callback: (_) => alCambiar(null),
        )
        .subscribe();
  }

  static Future<void> dejarDeEscuchar(RealtimeChannel canal) =>
      _db.removeChannel(canal);
}
