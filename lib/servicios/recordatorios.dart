import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../servicio_notificaciones.dart';
import 'estadisticas_progreso.dart';

/// Un recordatorio que el teléfono mostrará a una hora dada.
@immutable
class Recordatorio {
  const Recordatorio(this.id, this.cuando, this.titulo, this.cuerpo);
  final int id;
  final DateTime cuando;
  final String titulo;
  final String cuerpo;
}

/// Hora del recordatorio de racha (una vez al día, si no has estudiado).
const horaRacha = 19;

/// Horas de las sugerencias: cada 8 horas, sin la de la madrugada (1:00)
/// para no despertar a nadie.
const horasSugerencias = [9, 17];

/// Cuántos días hacia adelante se programan. Se renuevan cada vez que se
/// abre la app; si alguien deja de entrar, dejan de llegar al cabo de esos
/// días (no se insiste para siempre).
const diasProgramados = 7;

const _idRacha = 9000;
const _idSugerencia = 9100;

/// Sugerencias para usar las herramientas de Korulab.
const sugerenciasKorulab = <(String, String)>[
  ('🎮 ¡Diviértete con DiverKoru!', 'Supera tu récord en Salva las gotas.'),
  (
    '♻️ ¿Sabes dónde va cada residuo?',
    'Ponte a prueba en Clasifica la basura.',
  ),
  (
    '⚡ Trivia relámpago',
    '¿Cuántas preguntas ecológicas respondes antes de que se acabe el reloj?',
  ),
  (
    '🔤 Sopa de letras verde',
    'Encuentra las palabras escondidas y bate tu tiempo récord.',
  ),
  ('🛣️ Tu Ruta Eko te espera', 'Sigue avanzando, una unidad a la vez.'),
  ('🌱 Retos ecológicos', 'Hay pequeñas acciones para cuidar el planeta hoy.'),
  ('📖 Ekonsejos de Koru', 'Descubre trucos verdes para tu día a día.'),
  ('💬 Korublog', 'Mira qué están compartiendo tus compañeros.'),
  ('🏆 Ranking de Korulab', '¿Quién va primero en DiverKoru? Entra y compite.'),
  ('🛍️ La tienda de Koru', 'Canjea tus ekostrellas por pistas y ayudas.'),
  ('🐌 Koru te extraña', 'Pásate un ratito por Korulab, ¡te tiene un consejo!'),
  (
    '👋 Escríbele a tus amigos',
    'Comparte lo que aprendiste en tus chats de Korulab.',
  ),
];

/// Recordatorios de los próximos días a partir de [ahora].
///
/// * Racha: uno al día a las [horaRacha], salvo hoy si ya estudiaste.
/// * Sugerencias: en cada hora de [horasSugerencias], sin repetirse seguidas.
/// Los que ya pasaron no se incluyen.
List<Recordatorio> planearRecordatorios({
  required DateTime ahora,
  required int racha,
  required bool estudioHoy,
  required Random azar,
  int dias = diasProgramados,
}) {
  final lista = <Recordatorio>[];
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);

  for (var d = 0; d < dias; d++) {
    final dia = hoy.add(Duration(days: d));
    final cuando = DateTime(dia.year, dia.month, dia.day, horaRacha);
    if (!cuando.isAfter(ahora)) continue;
    if (d == 0 && estudioHoy) continue;
    final (titulo, cuerpo) = d == 0
        ? racha > 0
              ? (
                  '🔥 ¡No pierdas tu racha de $racha '
                      '${racha == 1 ? 'día' : 'días'}!',
                  'Completa una actividad hoy en Korulab para mantenerla.',
                )
              : (
                  '🌱 ¡Empieza tu racha hoy!',
                  'Una actividad cortita en Korulab basta para empezar.',
                )
        : (
            '🔥 ¿Ya cuidaste tu racha hoy?',
            'Haz una actividad en Korulab y sigue sumando días.',
          );
    lista.add(Recordatorio(_idRacha + d, cuando, titulo, cuerpo));
  }

  final mazo = <(String, String)>[];
  (String, String)? anterior;
  for (var d = 0; d < dias; d++) {
    final dia = hoy.add(Duration(days: d));
    for (final (i, hora) in horasSugerencias.indexed) {
      final cuando = DateTime(dia.year, dia.month, dia.day, hora);
      if (!cuando.isAfter(ahora)) continue;
      if (mazo.isEmpty) {
        mazo.addAll([...sugerenciasKorulab]..shuffle(azar));
        // Que la primera del mazo nuevo no repita la última que salió.
        if (mazo.last == anterior && mazo.length > 1) {
          mazo.insert(0, mazo.removeLast());
        }
      }
      final (titulo, cuerpo) = anterior = mazo.removeLast();
      lista.add(
        Recordatorio(
          _idSugerencia + d * horasSugerencias.length + i,
          cuando,
          titulo,
          cuerpo,
        ),
      );
    }
  }
  return lista;
}

/// Programa en el teléfono los recordatorios de racha y las sugerencias.
/// Funcionan sin internet y aunque la app esté cerrada.
abstract final class Recordatorios {
  static const _clave = 'korulab_recordatorios';
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _detalles = NotificationDetails(
    android: AndroidNotificationDetails(
      'recordatorios',
      'Recordatorios',
      channelDescription: 'Racha diaria y sugerencias de Korulab',
      importance: Importance.defaultImportance,
    ),
  );

  /// Si el usuario quiere recibirlos (se cambia en Ajustes).
  static Future<bool> activados() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_clave) ?? true;
  }

  static Future<void> cambiar(bool activar) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_clave, activar);
    await actualizar();
  }

  /// Vuelve a programar todo según el progreso actual (o lo cancela si
  /// están desactivados).
  static Future<void> actualizar() async {
    if (kIsWeb) return;
    try {
      await cancelarTodos();
      if (!await activados()) return;
      await NotificationService.init();
      final plan = planearRecordatorios(
        ahora: DateTime.now(),
        racha: progressStats.dailyStreak,
        estudioHoy: progressStats.estudioHoy,
        azar: Random(),
      );
      for (final r in plan) {
        await _plugin.zonedSchedule(
          id: r.id,
          title: r.titulo,
          body: r.cuerpo,
          // Se guarda como instante exacto; da igual la zona horaria.
          scheduledDate: tz.TZDateTime.from(r.cuando, tz.UTC),
          notificationDetails: _detalles,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('No se pudieron programar los recordatorios: $e');
    }
  }

  /// Borra todos los recordatorios programados (al cerrar sesión, etc.).
  static Future<void> cancelarTodos() async {
    if (kIsWeb) return;
    try {
      for (var d = 0; d < diasProgramados; d++) {
        await _plugin.cancel(id: _idRacha + d);
        for (var i = 0; i < horasSugerencias.length; i++) {
          await _plugin.cancel(
            id: _idSugerencia + d * horasSugerencias.length + i,
          );
        }
      }
    } catch (e) {
      debugPrint('No se pudieron cancelar los recordatorios: $e');
    }
  }
}
