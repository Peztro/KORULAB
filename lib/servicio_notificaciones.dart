import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Muestra una notificación del sistema cuando llega un mensaje nuevo
/// (comunicados generales o avisos de PQRS dirigidos al usuario).
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static RealtimeChannel? _channel;
  static String? _listeningFor;
  static int _nextId = 0;

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
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
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
    final recipient = (row['recipient_username'] as String? ?? '').toLowerCase();
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
}
