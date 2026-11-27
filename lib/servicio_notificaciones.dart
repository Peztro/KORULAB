import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Muestra una notificación del sistema cuando llega un mensaje nuevo
/// (comunicados generales, avisos de PQRS y mensajes privados).
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static RealtimeChannel? _channel;
  static String? _listeningFor;
  static int _nextId = 0;

  /// Id de la persona cuyo chat está abierto; sus mensajes no se notifican.
  static String? chatAbiertoCon;

  static const _androidDetails = AndroidNotificationDetails(
    'messages',
    'Mensajes',
    channelDescription: 'Avisos y comunicados de Korulab',
    importance: Importance.high,
    priority: Priority.high,
  );

  static Future<void> init() async {
    if (_initialized || kIsWeb) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    _initialized = true;
  }

  static Future<void> startListening(String username) async {
    await stopListening();
    if (kIsWeb) return;
    try {
      await init();
    } catch (error) {
      debugPrint('No se pudieron iniciar las notificaciones: $error');
      return;
    }
    final handle = username.trim().toLowerCase();
    final client = Supabase.instance.client;
    _listeningFor = handle;
    _channel = client
        .channel('messages-$handle')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) => _onMessage(payload.newRecord, handle),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'direct_messages',
          callback: (payload) => _onDirectMessage(payload.newRecord),
        )
        .subscribe();
  }

  static Future<void> stopListening({String? onlyFor}) async {
    if (onlyFor != null && onlyFor.trim().toLowerCase() != _listeningFor) {
      return;
    }
    final channel = _channel;
    _channel = null;
    _listeningFor = null;
    if (channel != null) {
      await Supabase.instance.client.removeChannel(channel);
    }
  }

  static void _onMessage(Map<String, dynamic> row, String handle) {
    final recipient = (row['recipient_username'] as String? ?? '')
        .toLowerCase();
    final sender = (row['sender_username'] as String? ?? '').toLowerCase();
    if (sender == handle || (recipient != handle && recipient != '*')) return;
    _plugin.show(
      id: _nextId++,
      title: row['title'] as String? ?? 'Nuevo mensaje',
      body: row['message'] as String? ?? '',
      notificationDetails: const NotificationDetails(
        android: _androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Mensaje privado: avisa solo si va dirigido al usuario actual.
  static Future<void> _onDirectMessage(Map<String, dynamic> row) async {
    final client = Supabase.instance.client;
    final me = client.auth.currentUser?.id;
    if (me == null || row['recipient_id'] != me) return;
    if (row['sender_id'] == chatAbiertoCon) return;
    var sender = 'Nuevo mensaje';
    try {
      final profile = await client
          .from('public_profiles')
          .select('username, display_name')
          .eq('id', row['sender_id'] as String)
          .maybeSingle();
      if (profile != null) {
        final name = (profile['display_name'] as String?)?.trim() ?? '';
        sender = name.isNotEmpty ? name : '@${profile['username']}';
      }
    } catch (error) {
      debugPrint('No se pudo obtener el remitente: $error');
    }
    await _plugin.show(
      id: _nextId++,
      title: sender,
      body: _textoMensaje(row),
      notificationDetails: const NotificationDetails(
        android: _androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static String _textoMensaje(Map<String, dynamic> row) {
    final body = (row['body'] as String? ?? '').trim();
    if (row['image_path'] == null) return body;
    return body.isEmpty ? '📷 Foto' : '📷 $body';
  }
}
