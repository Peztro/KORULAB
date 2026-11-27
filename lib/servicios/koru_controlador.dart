import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/koru_mascota.dart';

/// Cosas que pasan en la app y a las que Koru puede reaccionar.
enum EventoKoru {
  /// Al entrar a la pantalla de inicio (una vez por apertura de la app).
  bienvenida,
  leccionPerfecta,
  leccionBien,
  leccionRegular,
  leccionPracticar,
  avisoNuevo,

  /// Llegaron mensajes sin leer. Tocar el globo abre los chats.
  mensajeNuevo,

  /// Al tocar a Koru: un consejo ecológico.
  consejo,
}

/// Lo que Koru dice y la cara que pone.
@immutable
class MensajeKoru {
  const MensajeKoru(this.texto, this.emocion, {this.evento});

  final String texto;
  final EmocionKoru emocion;

  /// Por qué lo dijo. Permite que tocar el globo haga algo (por ejemplo,
  /// abrir los chats en [EventoKoru.mensajeNuevo]).
  final EventoKoru? evento;
}

/// De dónde salen las frases de Koru.
///
/// Hoy es [CatalogoFrasesKoru], escrito a mano. Para darle IA basta con otra
/// implementación que pida la frase a una Edge Function de Supabase (que a su
/// vez consulta al modelo) y asignarla a [KoruControlador.fuente].
abstract interface class FuenteFrasesKoru {
  Future<MensajeKoru?> frasePara(EventoKoru evento, Map<String, Object?> datos);
}

/// Frases escritas a mano, con variaciones para no repetirse.
class CatalogoFrasesKoru implements FuenteFrasesKoru {
  CatalogoFrasesKoru([Random? azar]) : _azar = azar ?? Random();

  final Random _azar;

  static const _frases = <EventoKoru, List<(String, EmocionKoru)>>{
    EventoKoru.bienvenida: [
      ('¡Hola, {nombre}! ¿Aprendemos algo nuevo hoy?', EmocionKoru.saludando),
      ('¡Qué bueno verte, {nombre}! 🌱', EmocionKoru.saludando),
      ('¡Hola, {nombre}! El planeta te estaba esperando 🌍', EmocionKoru.feliz),
    ],
    EventoKoru.leccionPerfecta: [
      (
        '¡Perfecto! Ni un solo error. ¡Eres increíble! 🏆',
        EmocionKoru.celebrando,
      ),
      ('¡Lección impecable! Me haces muy feliz 🐌✨', EmocionKoru.celebrando),
    ],
    EventoKoru.leccionBien: [
      ('¡Muy bien hecho! Ya casi la dominas 💚', EmocionKoru.feliz),
      ('¡Buen trabajo! Sigue así y será perfecta 🌿', EmocionKoru.feliz),
    ],
    EventoKoru.leccionRegular: [
      (
        'Vas por buen camino. Repasa lo que fallaste y vuelve a intentarlo.',
        EmocionKoru.pensando,
      ),
      (
        '¡Buen intento! A veces hay que ir despacio, como yo 🐌',
        EmocionKoru.pensando,
      ),
    ],
    EventoKoru.leccionPracticar: [
      (
        'No pasa nada, ¡equivocarse también es aprender! Inténtalo otra vez 💪',
        EmocionKoru.animando,
      ),
      ('Paso a paso se llega lejos. ¡Yo lo sé bien! 🐌', EmocionKoru.animando),
    ],
    EventoKoru.avisoNuevo: [
      ('¡Psst! Hay un aviso nuevo arriba 📣', EmocionKoru.feliz),
    ],
    EventoKoru.mensajeNuevo: [
      (
        '¡Tienes {chats} con mensajes nuevos! Tócame aquí para leerlos 💬',
        EmocionKoru.saludando,
      ),
      (
        '¡Psst, {nombre}! Te escribieron 📨 Toca aquí para ver tus chats.',
        EmocionKoru.feliz,
      ),
      (
        'Llegó un mensaje para ti 💌 ¿Lo vemos? Toca aquí.',
        EmocionKoru.saludando,
      ),
    ],
    EventoKoru.consejo: [
      (
        'Cierra el grifo mientras te cepillas: ahorras varios litros cada vez 💧',
        EmocionKoru.leyendo,
      ),
      ('Apaga la luz al salir de una habitación 💡', EmocionKoru.leyendo),
      (
        'Una botella reutilizable evita cientos de botellas de plástico al año ♻️',
        EmocionKoru.leyendo,
      ),
      (
        'Separar papel, plástico y orgánico ayuda muchísimo al reciclaje 🗑️',
        EmocionKoru.leyendo,
      ),
      (
        'Caminar o ir en bici en trayectos cortos limpia el aire 🚲',
        EmocionKoru.leyendo,
      ),
      (
        'Desconecta los cargadores que no uses: siguen gastando energía 🔌',
        EmocionKoru.leyendo,
      ),
      (
        'Las abejas polinizan gran parte de lo que comemos. ¡Cuidémoslas! 🐝',
        EmocionKoru.leyendo,
      ),
      (
        'Plantar un árbol da sombra, oxígeno y hogar a muchos animales 🌳',
        EmocionKoru.leyendo,
      ),
      ('tengo hambre', EmocionKoru.leyendo),
      ('tengo sed', EmocionKoru.leyendo),
    ],
  };

  @override
  Future<MensajeKoru?> frasePara(
    EventoKoru evento,
    Map<String, Object?> datos,
  ) async {
    final opciones = _frases[evento];
    if (opciones == null || opciones.isEmpty) return null;
    final (plantilla, emocion) = opciones[_azar.nextInt(opciones.length)];
    var texto = plantilla;
    datos.forEach((clave, valor) {
      texto = texto.replaceAll('{$clave}', '${valor ?? ''}');
    });
    // Si falta un dato (p. ej. el nombre), limpia el hueco que queda.
    texto = texto
        .replaceAll(RegExp(r'\{\w+\}'), '')
        .replaceAll(RegExp(r' ,'), ',')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        // "¡Hola, !" → "¡Hola!"
        .replaceAllMapped(RegExp(r',\s*([!?.])'), (m) => m[1]!);
    return MensajeKoru(texto.trim(), emocion);
  }
}

/// Estado central de Koru: qué dice, qué cara pone y si está activo.
///
/// Cualquier pantalla le avisa de lo que pasa con [reaccionar]; la mascota
/// flotante lo escucha y muestra el globo. Si la mascota no está a la vista,
/// el mensaje espera a que vuelva a estarlo.
class KoruControlador extends ChangeNotifier {
  KoruControlador({FuenteFrasesKoru? fuente})
    : fuente = fuente ?? CatalogoFrasesKoru();

  static final KoruControlador instancia = KoruControlador();

  static const _claveActivo = 'korulab_koru_activo';

  /// Tiempo mínimo entre mensajes que Koru dice por su cuenta.
  static const separacionMinima = Duration(seconds: 40);

  FuenteFrasesKoru fuente;

  bool _activo = true;
  bool _visible = false;
  bool _saludado = false;
  MensajeKoru? _mensaje;
  MensajeKoru? _pendiente;
  Duration _duracionPendiente = const Duration(seconds: 7);
  DateTime? _ultimo;
  Timer? _temporizador;

  /// Si el usuario quiere ver a Koru (se cambia en Ajustes).
  bool get activo => _activo;

  /// Lo que Koru está diciendo ahora (null si está callado).
  MensajeKoru? get mensaje => _mensaje;

  /// Cara de Koru: la del mensaje actual o, en reposo, feliz.
  EmocionKoru get emocion => _mensaje?.emocion ?? EmocionKoru.feliz;

  Future<void> cargarPreferencias() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _activo = prefs.getBool(_claveActivo) ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('No se pudo leer la preferencia de Koru: $e');
    }
  }

  Future<void> cambiarActivo(bool valor) async {
    _activo = valor;
    if (!valor) callar();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_claveActivo, valor);
    } catch (e) {
      debugPrint('No se pudo guardar la preferencia de Koru: $e');
    }
  }

  /// La mascota flotante avisa si está a la vista o no.
  void cambiarVisible(bool visible) {
    _visible = visible;
    if (!visible) {
      // Lo que estaba diciendo se guarda para cuando vuelva.
      if (_mensaje != null) _pendiente ??= _mensaje;
      _temporizador?.cancel();
      _mensaje = null;
      notifyListeners();
      return;
    }
    final pendiente = _pendiente;
    if (pendiente != null) {
      _pendiente = null;
      _mostrar(pendiente, _duracionPendiente);
    }
  }

  /// Koru reacciona a algo que pasó en la app.
  ///
  /// [importante]: se dice aunque haya hablado hace poco (p. ej. al terminar
  /// una lección). Los demás eventos respetan [separacionMinima].
  Future<void> reaccionar(
    EventoKoru evento, {
    Map<String, Object?> datos = const {},
    bool importante = false,
  }) async {
    if (!_activo) return;
    if (evento == EventoKoru.bienvenida) {
      if (_saludado) return;
      _saludado = true;
    }
    final ahora = DateTime.now();
    if (!importante &&
        evento != EventoKoru.consejo &&
        _ultimo != null &&
        ahora.difference(_ultimo!) < separacionMinima) {
      return;
    }
    MensajeKoru? frase;
    try {
      frase = await fuente.frasePara(evento, datos);
    } catch (e) {
      debugPrint('Koru no encontró qué decir: $e');
    }
    if (frase == null) return;
    decir(
      MensajeKoru(frase.texto, frase.emocion, evento: evento),
      duracion: evento == EventoKoru.consejo
          ? const Duration(seconds: 9)
          : const Duration(seconds: 7),
    );
  }

  /// Muestra [mensaje] durante [duracion]. Si Koru no está a la vista, lo
  /// guarda para cuando vuelva.
  void decir(
    MensajeKoru mensaje, {
    Duration duracion = const Duration(seconds: 7),
  }) {
    if (!_activo) return;
    _ultimo = DateTime.now();
    if (!_visible) {
      _pendiente = mensaje;
      _duracionPendiente = duracion;
      return;
    }
    _mostrar(mensaje, duracion);
  }

  void _mostrar(MensajeKoru mensaje, Duration duracion) {
    _temporizador?.cancel();
    _mensaje = mensaje;
    notifyListeners();
    _temporizador = Timer(duracion, callar);
  }

  void callar() {
    _temporizador?.cancel();
    if (_mensaje == null) return;
    _mensaje = null;
    notifyListeners();
  }

  /// Olvida el saludo y lo pendiente (al cerrar sesión o cambiar de cuenta).
  void reiniciar() {
    _saludado = false;
    _pendiente = null;
    _ultimo = null;
    callar();
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }
}
