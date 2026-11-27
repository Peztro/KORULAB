import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Notificaciones push con Firebase Cloud Messaging (FCM).
///
/// Cada teléfono tiene un "token" (su dirección de notificaciones). Al
/// iniciar sesión se guarda en Supabase con [registrar]; cuando llega un
/// mensaje privado o un aviso, la Edge Function `enviar-push` manda la
/// notificación a esos tokens y Android la muestra aunque Korulab esté
/// cerrada. Al cerrar sesión, [olvidar] borra el token para que ese
/// teléfono deje de recibir lo de la cuenta.
///
/// Con la app abierta, las notificaciones las sigue mostrando
/// `NotificationService` (que escucha en vivo), así que aquí no se repiten.
abstract final class ServicioPush {
  static bool _listo = false;
  static StreamSubscription<String>? _renovacion;

  /// Solo Android tiene Firebase configurado (google-services.json).
  static bool get _soportado =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Arranca Firebase. Se llama una vez al abrir la app.
  static Future<void> iniciar() async {
    if (!_soportado || _listo) return;
    try {
      await Firebase.initializeApp();
      // El canal "messages" debe existir antes de que llegue el primer push
      // con la app cerrada.
      await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'messages',
              'Mensajes',
              description: 'Avisos y comunicados de Korulab',
              importance: Importance.high,
            ),
          );
      _listo = true;
    } catch (e) {
      debugPrint('No se pudo iniciar Firebase: $e');
    }
  }

  /// Guarda el token de este teléfono para la cuenta con sesión iniciada.
  static Future<void> registrar() async {
    if (!_soportado) return;
    await iniciar();
    if (!_listo) return;
    try {
      final mensajeria = FirebaseMessaging.instance;
      await mensajeria.requestPermission();
      final token = await mensajeria.getToken();
      if (token != null) await _guardar(token);
      await _renovacion?.cancel();
      _renovacion = mensajeria.onTokenRefresh.listen(
        (nuevo) => unawaited(_guardar(nuevo)),
      );
    } catch (e) {
      debugPrint('No se pudo registrar el teléfono para notificaciones: $e');
    }
  }

  static Future<void> _guardar(String token) async {
    if (Supabase.instance.client.auth.currentUser == null) return;
    await Supabase.instance.client.rpc(
      'registrar_token_push',
      params: {'p_token': token, 'p_plataforma': 'android'},
    );
  }

  /// Al cerrar sesión: este teléfono deja de recibir notificaciones de la
  /// cuenta. Debe llamarse antes de cerrar la sesión en Supabase.
  static Future<void> olvidar() async {
    if (!_soportado || !_listo) return;
    try {
      await _renovacion?.cancel();
      _renovacion = null;
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await Supabase.instance.client.rpc(
          'borrar_token_push',
          params: {'p_token': token},
        );
      }
    } catch (e) {
      debugPrint('No se pudo olvidar el token de notificaciones: $e');
    }
  }
}
