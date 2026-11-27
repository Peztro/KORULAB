import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../servicio_notificaciones.dart';

/// Push que llega con la app cerrada o en segundo plano. Los chats llegan
/// solo con datos (de quién y qué dice) y aquí se arma la notificación:
/// plegada dice "Mensaje nuevo" y desplegada muestra remitente y mensaje.
/// Android la ejecuta aparte, así que debe ser una función de primer nivel.
@pragma('vm:entry-point')
Future<void> manejarPushEnSegundoPlano(RemoteMessage m) async {
  if (m.data['tipo'] != 'chat') return;
  await NotificationService.mostrarMensajeNuevo(
    remitente: m.data['remitente_nombre'] ?? 'Alguien',
    texto: m.data['texto'] ?? '',
    mensajeId: int.tryParse(m.data['mensaje_id'] ?? ''),
  );
}

/// Notificaciones push con Firebase Cloud Messaging (FCM).
///
/// Cada teléfono tiene un "token" (su dirección de notificaciones). Al
/// iniciar sesión se guarda en Supabase con [registrar]; cuando llega un
/// mensaje privado o un aviso, la Edge Function `enviar-push` manda la
/// notificación a esos tokens y Android la muestra aunque Korulab esté
/// cerrada. Al cerrar sesión, [olvidar] borra el token para que ese
/// teléfono deje de recibir lo de la cuenta.
///
/// Con la app abierta, Firebase no muestra nada por su cuenta. Los chats y
/// avisos los muestra `NotificationService` (que escucha en vivo); las
/// solicitudes de amistad y los comentarios de Korublog los muestra
/// [_enPrimerPlano].
abstract final class ServicioPush {
  static bool _listo = false;
  static StreamSubscription<String>? _renovacion;
  static StreamSubscription<RemoteMessage>? _primerPlano;
  static final _locales = FlutterLocalNotificationsPlugin();
  static int _siguienteId = 50000;

  /// Tipos que solo llegan por push (nadie más los muestra con la app
  /// abierta).
  static const _soloPorPush = {'amistad', 'korublog'};

  /// Solo Android tiene Firebase configurado (google-services.json).
  static bool get _soportado =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Arranca Firebase. Se llama una vez al abrir la app.
  static Future<void> iniciar() async {
    if (!_soportado || _listo) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(manejarPushEnSegundoPlano);
      // El canal "messages" debe existir antes de que llegue el primer push
      // con la app cerrada.
      await _locales
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
      _primerPlano ??= FirebaseMessaging.onMessage.listen(_enPrimerPlano);
      _listo = true;
    } catch (e) {
      debugPrint('No se pudo iniciar Firebase: $e');
    }
  }

  static Future<void> _enPrimerPlano(RemoteMessage m) async {
    final notificacion = m.notification;
    if (notificacion == null || !_soloPorPush.contains(m.data['tipo'])) return;
    try {
      await _locales.show(
        id: _siguienteId++,
        title: notificacion.title,
        body: notificacion.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'messages',
            'Mensajes',
            channelDescription: 'Avisos y comunicados de Korulab',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      debugPrint('No se pudo mostrar la notificación: $e');
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
