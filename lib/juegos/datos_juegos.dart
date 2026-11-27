import 'dart:math';

export 'banco_trivia.dart';

/// Cada tabla de récords de DiverKoru: un juego, o un modo de un juego
/// (la sopa de letras tiene un récord por dificultad).
enum JuegoDiverKoru {
  clasifica,
  trivia,
  sopaFacil,
  sopaMedio,
  sopaDificil,
  gotas,
}

extension JuegoDiverKoruInfo on JuegoDiverKoru {
  /// Clave en el servidor (tabla diverkoru_records).
  String get clave => switch (this) {
    JuegoDiverKoru.clasifica => 'clasifica',
    JuegoDiverKoru.trivia => 'trivia',
    JuegoDiverKoru.sopaFacil => 'sopa_facil',
    JuegoDiverKoru.sopaMedio => 'sopa_medio',
    JuegoDiverKoru.sopaDificil => 'sopa_dificil',
    JuegoDiverKoru.gotas => 'gotas',
  };

  /// En la sopa gana el menor tiempo; en los demás, el mayor número.
  bool get menorEsMejor => switch (this) {
    JuegoDiverKoru.sopaFacil ||
    JuegoDiverKoru.sopaMedio ||
    JuegoDiverKoru.sopaDificil => true,
    _ => false,
  };

  /// Qué se cuenta, en plural.
  String get unidad => switch (this) {
    JuegoDiverKoru.clasifica => 'objetos separados',
    JuegoDiverKoru.trivia => 'respuestas correctas',
    JuegoDiverKoru.gotas => 'gotas salvadas',
    _ => 'tiempo',
  };

  /// Valor listo para mostrar: un número, o un tiempo m:ss en la sopa.
  String formatear(int valor) => menorEsMejor
      ? '${valor ~/ 60}:${(valor % 60).toString().padLeft(2, '0')}'
      : '$valor';
}

/// ¿[nuevo] mejora a [anterior] en [juego]? Un 0 es "sin récord".
bool esMejorRecord(JuegoDiverKoru juego, int nuevo, int anterior) {
  if (nuevo <= 0) return false;
  if (anterior <= 0) return true;
  return juego.menorEsMejor ? nuevo < anterior : nuevo > anterior;
}

// ---------------------------------------------------------------------------
// Clasifica la basura (código de colores de Colombia, Resolución 2184/2019)
// ---------------------------------------------------------------------------

enum Caneca { blanca, verde, negra }

extension CanecaInfo on Caneca {
  String get nombre => switch (this) {
    Caneca.blanca => 'Blanca',
    Caneca.verde => 'Verde',
    Caneca.negra => 'Negra',
  };

  String get contenido => switch (this) {
    Caneca.blanca => 'Aprovechables',
    Caneca.verde => 'Orgánicos',
    Caneca.negra => 'No aprovechables',
  };
}

class Residuo {
  const Residuo(this.emoji, this.nombre, this.caneca, this.pista);
  final String emoji;
  final String nombre;
  final Caneca caneca;

  /// Explicación corta que se muestra si el jugador se equivoca.
  final String pista;
}

const residuos = <Residuo>[
  // Blanca: limpios y secos, se pueden reciclar.
  Residuo(
    '🧴',
    'Botella plástica limpia',
    Caneca.blanca,
    'El plástico limpio se recicla.',
  ),
  Residuo('📰', 'Periódico', Caneca.blanca, 'El papel seco se recicla.'),
  Residuo(
    '📦',
    'Caja de cartón',
    Caneca.blanca,
    'El cartón limpio se recicla.',
  ),
  Residuo('🥫', 'Lata vacía', Caneca.blanca, 'Los metales se reciclan.'),
  Residuo(
    '🍾',
    'Botella de vidrio',
    Caneca.blanca,
    'El vidrio se recicla una y otra vez.',
  ),
  Residuo(
    '🫙',
    'Frasco de vidrio',
    Caneca.blanca,
    'El vidrio se recicla una y otra vez.',
  ),
  Residuo('📄', 'Hoja de papel', Caneca.blanca, 'El papel seco se recicla.'),
  // Verde: restos de comida y de plantas.
  Residuo(
    '🍌',
    'Cáscara de banano',
    Caneca.verde,
    'Los restos de comida son orgánicos.',
  ),
  Residuo(
    '🍎',
    'Corazón de manzana',
    Caneca.verde,
    'Los restos de comida son orgánicos.',
  ),
  Residuo(
    '🥚',
    'Cáscaras de huevo',
    Caneca.verde,
    'Las cáscaras de huevo sirven para compost.',
  ),
  Residuo('🍂', 'Hojas secas', Caneca.verde, 'Las hojas secas son orgánicas.'),
  Residuo(
    '🥕',
    'Restos de verduras',
    Caneca.verde,
    'Los restos de comida son orgánicos.',
  ),
  Residuo('☕', 'Borra de café', Caneca.verde, 'La borra de café es orgánica.'),
  // Negra: no se pueden aprovechar.
  Residuo(
    '🧻',
    'Papel higiénico usado',
    Caneca.negra,
    'El papel sucio ya no se puede reciclar.',
  ),
  Residuo(
    '🍕',
    'Caja de pizza con grasa',
    Caneca.negra,
    'El cartón con grasa ya no se recicla.',
  ),
  Residuo(
    '😷',
    'Tapabocas usado',
    Caneca.negra,
    'Los tapabocas usados van a la negra.',
  ),
  Residuo(
    '🍬',
    'Envoltura de dulce',
    Caneca.negra,
    'Las envolturas metalizadas no se reciclan.',
  ),
  Residuo(
    '🧽',
    'Esponja vieja',
    Caneca.negra,
    'Las esponjas usadas no se aprovechan.',
  ),
  Residuo(
    '🥛',
    'Caja de leche limpia',
    Caneca.blanca,
    'Los envases de tetrapak limpios se reciclan.',
  ),
  Residuo(
    '🧃',
    'Caja de jugo limpia',
    Caneca.blanca,
    'Los envases de tetrapak limpios se reciclan.',
  ),
  Residuo('📓', 'Cuaderno viejo', Caneca.blanca, 'El papel limpio se recicla.'),
  Residuo('📚', 'Revistas', Caneca.blanca, 'El papel limpio se recicla.'),
  Residuo('✉️', 'Sobre de papel', Caneca.blanca, 'El papel limpio se recicla.'),
  Residuo(
    '🛍️',
    'Bolsa plástica limpia',
    Caneca.blanca,
    'El plástico limpio se recicla.',
  ),
  Residuo(
    '🥤',
    'Vaso plástico limpio',
    Caneca.blanca,
    'El plástico limpio se recicla.',
  ),
  Residuo(
    '🪣',
    'Balde plástico roto',
    Caneca.blanca,
    'El plástico rígido se recicla.',
  ),
  Residuo('🔩', 'Tornillos', Caneca.blanca, 'Los metales se reciclan.'),
  Residuo(
    '🥄',
    'Cuchara metálica vieja',
    Caneca.blanca,
    'Los metales se reciclan.',
  ),
  Residuo(
    '🎁',
    'Caja de regalo de cartón',
    Caneca.blanca,
    'El cartón limpio se recicla.',
  ),
  Residuo(
    '🗃️',
    'Caja de archivo de cartón',
    Caneca.blanca,
    'El cartón limpio se recicla.',
  ),
  Residuo(
    '🥫',
    'Lata de atún lavada',
    Caneca.blanca,
    'Los metales se reciclan.',
  ),
  Residuo(
    '🧴',
    'Frasco de champú vacío',
    Caneca.blanca,
    'El plástico limpio se recicla.',
  ),
  Residuo('🔑', 'Llave vieja', Caneca.blanca, 'Los metales se reciclan.'),
  Residuo('📎', 'Clips', Caneca.blanca, 'Los metales se reciclan.'),
  Residuo(
    '🥔',
    'Cáscaras de papa',
    Caneca.verde,
    'Los restos de comida son orgánicos.',
  ),
  Residuo(
    '🍊',
    'Cáscara de naranja',
    Caneca.verde,
    'Los restos de comida son orgánicos.',
  ),
  Residuo(
    '🥑',
    'Cáscara y pepa de aguacate',
    Caneca.verde,
    'Los restos de comida son orgánicos.',
  ),
  Residuo(
    '🍞',
    'Pan viejo',
    Caneca.verde,
    'Los restos de comida son orgánicos.',
  ),
  Residuo(
    '🍚',
    'Arroz que sobró',
    Caneca.verde,
    'Los restos de comida son orgánicos.',
  ),
  Residuo(
    '🥀',
    'Flores marchitas',
    Caneca.verde,
    'Los restos de plantas son orgánicos.',
  ),
  Residuo(
    '🌿',
    'Pasto cortado',
    Caneca.verde,
    'Los restos de plantas son orgánicos.',
  ),
  Residuo(
    '🪵',
    'Ramitas secas',
    Caneca.verde,
    'Los restos de plantas son orgánicos.',
  ),
  Residuo(
    '🍍',
    'Cáscara de piña',
    Caneca.verde,
    'Los restos de comida son orgánicos.',
  ),
  Residuo(
    '🥭',
    'Cáscara de mango',
    Caneca.verde,
    'Los restos de comida son orgánicos.',
  ),
  Residuo(
    '🌽',
    'Tusa de mazorca',
    Caneca.verde,
    'Los restos de comida son orgánicos.',
  ),
  Residuo(
    '🍉',
    'Cáscara de sandía',
    Caneca.verde,
    'Los restos de comida son orgánicos.',
  ),
  Residuo(
    '🍋',
    'Cáscara de limón',
    Caneca.verde,
    'Los restos de comida son orgánicos.',
  ),
  Residuo(
    '🥬',
    'Hojas de lechuga',
    Caneca.verde,
    'Los restos de comida son orgánicos.',
  ),
  Residuo(
    '🍅',
    'Tomate dañado',
    Caneca.verde,
    'Los restos de comida son orgánicos.',
  ),
  Residuo(
    '🧅',
    'Cáscara de cebolla',
    Caneca.verde,
    'Los restos de comida son orgánicos.',
  ),
  Residuo(
    '🍟',
    'Paquete de papas fritas',
    Caneca.negra,
    'Los empaques metalizados no se reciclan.',
  ),
  Residuo(
    '🍫',
    'Envoltura de chocolatina',
    Caneca.negra,
    'Los empaques metalizados no se reciclan.',
  ),
  Residuo(
    '👶',
    'Pañal usado',
    Caneca.negra,
    'Los pañales usados van a la negra.',
  ),
  Residuo(
    '🍽️',
    'Plato desechable sucio',
    Caneca.negra,
    'Lo que está sucio de comida ya no se recicla.',
  ),
  Residuo(
    '🥡',
    'Icopor sucio de comida',
    Caneca.negra,
    'El icopor sucio no se recicla.',
  ),
  Residuo(
    '🪥',
    'Cepillo de dientes viejo',
    Caneca.negra,
    'Los cepillos de dientes no se aprovechan.',
  ),
  Residuo(
    '🩹',
    'Curita usada',
    Caneca.negra,
    'Lo que tocó una herida va a la negra.',
  ),
  Residuo(
    '🍭',
    'Envoltura de chupeta',
    Caneca.negra,
    'Los empaques metalizados no se reciclan.',
  ),
  Residuo(
    '🧹',
    'Basura de barrer',
    Caneca.negra,
    'El polvo y la basura de barrer no se aprovechan.',
  ),
  Residuo(
    '🎀',
    'Papel de regalo metalizado',
    Caneca.negra,
    'El papel metalizado no se recicla.',
  ),
  Residuo(
    '🪞',
    'Espejo roto',
    Caneca.negra,
    'Los espejos no se reciclan como el vidrio.',
  ),
  Residuo(
    '🧾',
    'Recibo de papel térmico',
    Caneca.negra,
    'El papel térmico de los recibos no se recicla.',
  ),
  Residuo(
    '🍔',
    'Servilleta con grasa',
    Caneca.negra,
    'Las servilletas sucias no se reciclan.',
  ),
  Residuo(
    '🧤',
    'Guantes desechables usados',
    Caneca.negra,
    'Los guantes usados van a la negra.',
  ),
  Residuo(
    '🍿',
    'Bolsa de crispetas con grasa',
    Caneca.negra,
    'El papel con grasa ya no se recicla.',
  ),
  Residuo('🎈', 'Globo reventado', Caneca.negra, 'Los globos no se reciclan.'),
];

/// Duración de una partida de Clasifica y segundos que cuesta equivocarse
/// (así no sirve tocar canecas al azar).
const segundosClasifica = 60;
const penalizacionClasifica = 3;

// ---------------------------------------------------------------------------
// Trivia relámpago
// ---------------------------------------------------------------------------

class PreguntaTrivia {
  const PreguntaTrivia(this.pregunta, this.correcta, this.incorrectas);
  final String pregunta;
  final String correcta;
  final List<String> incorrectas;

  /// Opciones en orden aleatorio.
  List<String> opciones(Random azar) =>
      [correcta, ...incorrectas]..shuffle(azar);
}

/// Reloj de la Trivia relámpago, casi infinita.
///
/// * Empiezas con [inicial] segundos.
/// * Cada acierto suma tiempo: 5 s en los primeros 15, luego 4 s hasta los
///   30 y después 3 s. Leer y responder toma unos segundos, así que al
///   principio vas ganando tiempo y, con los aciertos, cuesta cada vez más.
/// * Cada fallo acelera el reloj un 25 % (hasta el doble). Los aciertos lo
///   van calmando de nuevo (−10 % cada uno), así un mal momento no te hunde.
class RelojTrivia {
  RelojTrivia({this.inicial = 60}) : restante = inicial.toDouble();

  final int inicial;
  double restante;

  /// Qué tan rápido corre el reloj (1 = normal).
  double ritmo = 1;
  int aciertos = 0;
  int fallos = 0;

  static const ritmoMaximo = 2.0;

  bool get agotado => restante <= 0;

  /// Segundos que suma el próximo acierto.
  int get premio => aciertos < 15
      ? 5
      : aciertos < 30
      ? 4
      : 3;

  void avanzar(double segundos) {
    restante = max(0, restante - segundos * ritmo);
  }

  /// Registra un acierto y devuelve los segundos ganados.
  int acierto() {
    final ganado = premio;
    aciertos++;
    restante += ganado;
    ritmo = max(1, ritmo - 0.1);
    return ganado;
  }

  void fallo() {
    fallos++;
    ritmo = min(ritmoMaximo, ritmo + 0.25);
  }
}

// ---------------------------------------------------------------------------
// Salva las gotas
// ---------------------------------------------------------------------------

const vidasGotas = 3;

/// Tipos de gota en Salva las gotas.
enum TipoGota { agua, aceite, acida, petroleo, dorada }

extension TipoGotaInfo on TipoGota {
  String get nombre => switch (this) {
    TipoGota.agua => 'Agua',
    TipoGota.aceite => 'Aceite',
    TipoGota.acida => 'Lluvia ácida',
    TipoGota.petroleo => 'Petróleo',
    TipoGota.dorada => 'Agua dorada',
  };

  /// Vidas que suma (o resta) al atraparla.
  int get vidasAlAtrapar => switch (this) {
    TipoGota.agua => 0,
    TipoGota.aceite => -1,
    TipoGota.acida => -2,
    TipoGota.petroleo => -3,
    TipoGota.dorada => 1,
  };

  /// Puntos al atraparla.
  int get puntosAlAtrapar => switch (this) {
    TipoGota.agua || TipoGota.dorada => 1,
    _ => 0,
  };

  /// Solo el agua limpia cuesta una vida si cae al suelo.
  bool get cuestaVidaSiCae => this == TipoGota.agua;

  bool get esMala => vidasAlAtrapar < 0;
}

/// Velocidad de caída (fracción de la altura por segundo) según los puntos.
/// Sube poco a poco con una curva suave y se acerca a 0,85 sin llegar.
/// Puntos → velocidad: 0 → 0,25 · 10 → 0,32 · 50 → 0,53 · 100 → 0,68.
double velocidadGotas(int puntos) => 0.25 + 0.6 * (1 - exp(-puntos / 80));

/// Segundos entre una gota y la siguiente según los puntos, con la misma
/// curva suave. Puntos → segundos: 0 → 1,2 · 10 → 1,11 · 50 → 0,85 ·
/// 100 → 0,66 (nunca baja de 0,45).
double intervaloGotas(int puntos) => 0.45 + 0.75 * exp(-puntos / 80);

/// Bordes por donde pueden caer las gotas (fracción del ancho).
const _bordeIzquierdo = 0.06;
const _bordeDerecho = 0.94;

/// Separación mínima entre dos gotas buenas seguidas: crece con los puntos
/// para obligar a moverse más. Puntos → separación: 0 → 0,15 · 10 → 0,22 ·
/// 50 → 0,35 · 100 → 0,47 (nunca pasa de 0,6).
double separacionGotasBuenas(int puntos) =>
    0.15 + 0.45 * (1 - exp(-puntos / 60));

/// Una gota que hay que soltar: tipo, posición horizontal y altura inicial
/// (negativa = un poco por encima de la pantalla).
typedef GotaNueva = ({TipoGota tipo, double x, double y});

/// Curva que va de 0 a 1 a medida que suben los puntos (a partir de 2).
/// Puntos → valor: 2 → 0 · 10 → 0,33 · 20 → 0,59 · 40 → 0,85.
double _rampa(int puntos) => puntos < 2 ? 0 : 1 - exp(-(puntos - 2) / 20);

/// Probabilidad de que una gota buena venga acompañada de una mala pegada.
double probabilidadPareja(int puntos) => 0.40 * _rampa(puntos);

/// Probabilidad de que, en vez de agua, caiga una gota mala sola.
double probabilidadMalaSuelta(int puntos) => 0.30 * _rampa(puntos);

/// Tipo de gota mala según los puntos: el aceite desde el principio, la
/// lluvia ácida desde 10 y el petróleo desde 20 (las fuertes, más raras).
TipoGota tipoMalo(int puntos, Random azar) {
  final opciones = [
    (TipoGota.aceite, 3),
    if (puntos >= 10) (TipoGota.acida, 2),
    if (puntos >= 20) (TipoGota.petroleo, 1),
  ];
  final total = opciones.fold(0, (s, o) => s + o.$2);
  var r = azar.nextInt(total);
  for (final (tipo, peso) in opciones) {
    if (r < peso) return tipo;
    r -= peso;
  }
  return TipoGota.aceite;
}

/// Decide qué gotas soltar en este momento.
///
/// * A veces cae una mala sola, muchas veces justo donde está [objetivo]
///   (la gota buena más baja, a la que va el jugador).
/// * Si no, cae agua (o, rara vez, agua dorada) lejos de [ultimaBuena], y a
///   veces una mala pegada a ella: al mismo tiempo, un poco antes o un poco
///   después, así no hay un patrón fijo que esquivar.
List<GotaNueva> planearGotas({
  required int puntos,
  required double? ultimaBuena,
  required double? objetivo,
  required Random azar,
}) {
  double alAzar(double desde, double hasta) =>
      desde + azar.nextDouble() * (hasta - desde);
  double dentro(double x) => x.clamp(_bordeIzquierdo, _bordeDerecho);

  if (azar.nextDouble() < probabilidadMalaSuelta(puntos)) {
    final x = objetivo != null && azar.nextBool()
        ? dentro(objetivo + alAzar(-0.08, 0.08))
        : alAzar(_bordeIzquierdo, _bordeDerecho);
    return [(tipo: tipoMalo(puntos, azar), x: x, y: -0.05)];
  }

  final buena = (
    tipo: puntos >= 10 && azar.nextDouble() < 0.015
        ? TipoGota.dorada
        : TipoGota.agua,
    x: _lejosDe(ultimaBuena, puntos, azar),
    y: -0.05,
  );
  if (azar.nextDouble() >= probabilidadPareja(puntos)) return [buena];

  // Mala pegada a la buena, a un lado, más arriba o más abajo.
  final lado = azar.nextBool() ? 1 : -1;
  var x = buena.x + lado * alAzar(0.07, 0.13);
  if (x < _bordeIzquierdo || x > _bordeDerecho) {
    x = buena.x - lado * alAzar(0.07, 0.13);
  }
  return [
    buena,
    (
      tipo: tipoMalo(puntos, azar),
      x: dentro(x),
      y: -0.05 + alAzar(-0.12, 0.08),
    ),
  ];
}

/// Posición de una gota buena: al menos [separacionGotasBuenas] lejos de la
/// anterior buena.
double _lejosDe(double? ultimaBuena, int puntos, Random azar) {
  double alAzar(double desde, double hasta) =>
      desde + azar.nextDouble() * (hasta - desde);
  if (ultimaBuena == null) return alAzar(_bordeIzquierdo, _bordeDerecho);
  final sep = separacionGotasBuenas(puntos);
  final izquierda = max((ultimaBuena - sep) - _bordeIzquierdo, 0.0);
  final derecha = max(_bordeDerecho - (ultimaBuena + sep), 0.0);
  if (izquierda == 0 && derecha == 0) {
    // No cabe la separación completa: al borde más lejano.
    return ultimaBuena < 0.5 ? _bordeDerecho : _bordeIzquierdo;
  }
  if (azar.nextDouble() * (izquierda + derecha) < izquierda) {
    return alAzar(_bordeIzquierdo, ultimaBuena - sep);
  }
  return alAzar(ultimaBuena + sep, _bordeDerecho);
}
