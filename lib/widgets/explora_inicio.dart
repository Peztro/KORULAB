import 'dart:math';

import 'package:flutter/material.dart';

import '../juegos/datos_juegos.dart';
import '../juegos/records_diverkoru.dart';
import '../paginas/pagina_curso.dart';
import '../paginas/pagina_retos_ecologicos.dart';
import '../paginas/pagina_ruta_eko.dart';
import '../paginas/pagina_tienda.dart';
import '../servicios/estadisticas_progreso.dart';
import '../tema/tema_korulab.dart';
import 'koru_mascota.dart';

/// Sección "¿Qué hacemos hoy?" del inicio del estudiante: Ruta Eko como
/// protagonista y mosaicos de Retos, Tienda y DiverKoru, cada uno con un
/// dato tuyo que invita a entrar.
class ExploraInicio extends StatefulWidget {
  const ExploraInicio({
    super.key,
    required this.username,
    required this.onAbrirDiverKoru,
  });

  final String username;

  /// Cambia a la pestaña DiverKoru.
  final VoidCallback onAbrirDiverKoru;

  @override
  State<ExploraInicio> createState() => _ExploraInicioState();
}

class _ExploraInicioState extends State<ExploraInicio> {
  final _records = RecordsDiverKoru.leerTodos();

  @override
  Widget build(BuildContext context) {
    final koru = context.koru;
    final username = widget.username;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Entrada(orden: 0, child: TarjetaRutaEko(username: username)),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Entrada(
                  orden: 1,
                  child: MosaicoExplora(
                    titulo: 'Retos',
                    dato:
                        '${EcoChallengesPage.cantidadRetos} retos para '
                        'cuidar el planeta hoy',
                    color: koru.agua,
                    emocion: EmocionKoru.leyendo,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EcoChallengesPage(username: username),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Entrada(
                  orden: 2,
                  child: ListenableBuilder(
                    listenable: progressStats,
                    builder: (context, _) => MosaicoExplora(
                      titulo: 'Tienda',
                      dato: datoTienda(progressStats.ekostrellas),
                      color: koru.oro,
                      emocion: EmocionKoru.tendero,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RewardShopPage(username: username),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Entrada(
          orden: 3,
          child: FutureBuilder<Map<JuegoDiverKoru, int>>(
            future: _records,
            builder: (context, snap) => MosaicoExplora(
              titulo: 'DiverKoru',
              dato: datoDiverKoru(snap.data ?? const {}),
              color: koru.tierra,
              emocion: EmocionKoru.jugando,
              ancho: true,
              onTap: widget.onAbrirDiverKoru,
            ),
          ),
        ),
      ],
    );
  }
}

/// Qué decir en el mosaico de la tienda según tus ekostrellas.
String datoTienda(int ekostrellas) {
  // Del más caro al más barato.
  const productos = [
    (RewardShopPage.streakProtectorPrice, 'un Protector de racha'),
    (RewardShopPage.starMultiplierPrice, 'un Doble de ekostrellas'),
    (RewardShopPage.secondChancePrice, 'un Segundo intento'),
    (RewardShopPage.hintPrice, 'una Pista'),
  ];
  for (final (precio, nombre) in productos) {
    if (ekostrellas >= precio) {
      return 'Tienes $ekostrellas ⭐ · te alcanza para $nombre';
    }
  }
  final (precio, nombre) = productos.last;
  return 'Te faltan ${precio - ekostrellas} ⭐ para $nombre';
}

/// Qué decir en el mosaico de DiverKoru según tus récords.
String datoDiverKoru(Map<JuegoDiverKoru, int> records) {
  final gotas = records[JuegoDiverKoru.gotas] ?? 0;
  if (gotas > 0) return 'Tu récord: $gotas gotas salvadas · ¿lo superas?';
  final trivia = records[JuegoDiverKoru.trivia] ?? 0;
  if (trivia > 0) return 'Tu récord en Trivia: $trivia · ¿lo superas?';
  final clasifica = records[JuegoDiverKoru.clasifica] ?? 0;
  if (clasifica > 0) return 'Separaste $clasifica objetos · ¿vas por más?';
  return '4 juegos y un ranking te esperan';
}

/// Tarjeta protagonista: dónde vas en Ruta Eko y un botón para continuar.
class TarjetaRutaEko extends StatefulWidget {
  const TarjetaRutaEko({super.key, required this.username});

  final String username;

  @override
  State<TarjetaRutaEko> createState() => _TarjetaRutaEkoState();
}

class _TarjetaRutaEkoState extends State<TarjetaRutaEko> {
  late Future<SenderoResumen> _carga = cargarSenderoResumen(widget.username);

  Future<void> _abrir(Widget pagina) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => pagina));
    // Al volver, por si avanzaste o cambió el sendero.
    if (mounted) {
      setState(() => _carga = cargarSenderoResumen(widget.username));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    final texto = koru.textoHero;
    return FutureBuilder<SenderoResumen>(
      future: _carga,
      builder: (context, snap) {
        final resumen = snap.data;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(KoruRadius.xl),
            onTap: () => _abrir(RutaEkoPage(username: widget.username)),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [koru.hoja, Color.lerp(koru.hoja, koru.agua, 0.7)!],
                ),
                borderRadius: BorderRadius.circular(KoruRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: koru.hoja.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -18,
                    top: -20,
                    child: Icon(
                      Icons.route_rounded,
                      size: 140,
                      color: texto.withValues(alpha: 0.10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: ListenableBuilder(
                      listenable: progressStats,
                      builder: (context, _) =>
                          _contenido(theme, texto, resumen, snap.hasError),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _contenido(
    ThemeData theme,
    Color texto,
    SenderoResumen? resumen,
    bool error,
  ) {
    final terminado = resumen?.terminado ?? false;
    final indice = resumen?.indiceActual;
    final (hechas, total) = resumen?.avanceActual ?? (0, 0);
    final curso = resumen?.cursoActual;

    String titulo;
    String detalle;
    if (resumen == null) {
      titulo = error ? 'Tu sendero te espera' : 'Cargando tu sendero…';
      detalle = 'Aprende sobre el planeta paso a paso.';
    } else if (resumen.total == 0) {
      titulo = 'El sendero se está preparando';
      detalle = 'Muy pronto tendrás unidades para recorrer.';
    } else if (terminado) {
      titulo = '¡Completaste el sendero! 🎉';
      detalle = 'Repasa tus unidades favoritas cuando quieras.';
    } else {
      titulo = 'Unidad ${indice! + 1} · ${resumen.tituloActual}';
      detalle = total > 0
          ? '$hechas de $total actividades · ¡sigue así!'
          : 'Lección de tu profe';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.route_rounded, color: texto, size: 22),
            const SizedBox(width: 6),
            Text(
              'RUTA EKO',
              style: theme.textTheme.labelLarge?.copyWith(
                color: texto,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            if (resumen != null && resumen.total > 0)
              Text(
                '${resumen.completadas}/${resumen.total} unidades',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: texto.withValues(alpha: 0.85),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (resumen != null && resumen.total > 0) ...[
          MiniSendero(estados: resumen.estados, colorTexto: texto),
          const SizedBox(height: 12),
        ],
        Text(
          titulo,
          style: theme.textTheme.titleLarge?.copyWith(color: texto),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          detalle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: texto.withValues(alpha: 0.9),
          ),
        ),
        if (total > 0) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: hechas / total,
              minHeight: 8,
              color: texto,
              backgroundColor: texto.withValues(alpha: 0.25),
            ),
          ),
        ],
        const SizedBox(height: 14),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: texto,
            foregroundColor: context.koru.hoja,
            minimumSize: const Size.fromHeight(48),
            textStyle: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          onPressed: () => _abrir(
            curso != null
                ? CoursePage(course: curso, courseIndex: -1)
                : RutaEkoPage(username: widget.username),
          ),
          icon: Icon(
            terminado ? Icons.map_rounded : Icons.play_arrow_rounded,
            size: 26,
          ),
          label: Text(
            terminado
                ? 'Ver mi sendero'
                : (resumen?.completadas ?? 0) == 0 && hechas == 0
                ? 'Empezar'
                : 'Continuar',
          ),
        ),
      ],
    );
  }
}

/// Sendero en miniatura: una parada por unidad (las hechas con ✓, la
/// actual latiendo y las demás con candado). Si hay muchas, muestra las
/// cercanas a la actual.
class MiniSendero extends StatefulWidget {
  const MiniSendero({
    super.key,
    required this.estados,
    required this.colorTexto,
  });

  final List<EstadoUnidadRuta> estados;
  final Color colorTexto;

  @override
  State<MiniSendero> createState() => _MiniSenderoState();
}

class _MiniSenderoState extends State<MiniSendero>
    with SingleTickerProviderStateMixin {
  static const _maximo = 7;

  late final AnimationController _latido = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _latido.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estados = widget.estados;
    final actual = estados.indexOf(EstadoUnidadRuta.actual);
    // Ventana de paradas alrededor de la actual.
    var desde = 0;
    if (estados.length > _maximo) {
      final centro = actual < 0 ? estados.length - 1 : actual;
      desde = (centro - _maximo ~/ 2).clamp(0, estados.length - _maximo);
    }
    final hasta = min(estados.length, desde + _maximo);
    final visibles = estados.sublist(desde, hasta);
    final c = widget.colorTexto;
    final koru = context.koru;

    return Row(
      children: [
        if (desde > 0) _puntos(c),
        for (final (i, estado) in visibles.indexed) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 3,
                color: c.withValues(
                  alpha: estado == EstadoUnidadRuta.bloqueada ? 0.3 : 0.8,
                ),
              ),
            ),
          switch (estado) {
            EstadoUnidadRuta.completada => _parada(
              c,
              Icon(Icons.check_rounded, size: 16, color: koru.hoja),
              relleno: c,
            ),
            EstadoUnidadRuta.actual => ScaleTransition(
              scale: Tween(begin: 0.9, end: 1.15).animate(
                CurvedAnimation(parent: _latido, curve: Curves.easeInOut),
              ),
              child: _parada(
                c,
                Text(
                  '${desde + i + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: koru.hoja,
                  ),
                ),
                relleno: koru.oro,
                tamano: 32,
              ),
            ),
            EstadoUnidadRuta.bloqueada => _parada(
              c,
              Icon(
                Icons.lock_rounded,
                size: 13,
                color: c.withValues(alpha: 0.7),
              ),
              relleno: c.withValues(alpha: 0.18),
            ),
          },
        ],
        if (hasta < estados.length) _puntos(c),
      ],
    );
  }

  Widget _parada(
    Color borde,
    Widget dentro, {
    required Color relleno,
    double tamano = 26,
  }) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: relleno,
        shape: BoxShape.circle,
        border: Border.all(color: borde, width: 2),
      ),
      alignment: Alignment.center,
      child: dentro,
    );
  }

  Widget _puntos(Color c) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      '…',
      style: TextStyle(color: c, fontWeight: FontWeight.w900),
    ),
  );
}

/// Mosaico de color con un Koru y un dato que invita a entrar.
class MosaicoExplora extends StatelessWidget {
  const MosaicoExplora({
    super.key,
    required this.titulo,
    required this.dato,
    required this.color,
    required this.emocion,
    required this.onTap,
    this.ancho = false,
  });

  final String titulo;
  final String dato;
  final Color color;
  final EmocionKoru emocion;
  final VoidCallback onTap;

  /// Ocupa todo el ancho (Koru a la derecha) en vez de media columna.
  final bool ancho;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final oscuro = Color.lerp(color, Colors.black, 0.25)!;
    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          titulo,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dato,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.95),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KoruRadius.l),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, oscuro],
            ),
            borderRadius: BorderRadius.circular(KoruRadius.l),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ancho
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    children: [
                      Expanded(child: textos),
                      KoruMascota(emocion: emocion, tamano: 84),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textos,
                      const SizedBox(height: 6),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: KoruMascota(emocion: emocion, tamano: 76),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// Entrada suave: aparece y sube un poco, una tarjeta tras otra.
class _Entrada extends StatelessWidget {
  const _Entrada({required this.orden, required this.child});

  final int orden;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + orden * 110),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 18),
          child: child,
        ),
      ),
    );
  }
}
