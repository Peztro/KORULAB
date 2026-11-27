import 'dart:async';

import 'package:flutter/material.dart';
import '../tema/tema_korulab.dart';
import '../servicios/koru_controlador.dart';
import '../widgets/celebracion.dart';
import '../widgets/koru_mascota.dart';
import '../widgets/ui_koru.dart';
import '../modelos/modelos_curso.dart';
import '../paginas/pagina_completar.dart';
import '../paginas/pagina_relacionar.dart';
import '../paginas/pagina_memoria.dart';
import '../paginas/pagina_quiz.dart';
import '../paginas/pagina_ordenar.dart';
import '../servicios/estadisticas_progreso.dart';

String _activityLabel(ActivityType t) {
  switch (t) {
    case ActivityType.quiz:
      return 'Quiz';
    case ActivityType.matching:
      return 'Relacionar';
    case ActivityType.memory:
      return 'Memoria';
    case ActivityType.fillBlank:
      return 'Completar';
    case ActivityType.sorting:
      return 'Ordenar';
  }
}

IconData _activityIcon(ActivityType t) {
  switch (t) {
    case ActivityType.quiz:
      return Icons.quiz_rounded;
    case ActivityType.matching:
      return Icons.compare_arrows_rounded;
    case ActivityType.memory:
      return Icons.grid_view_rounded;
    case ActivityType.fillBlank:
      return Icons.edit_note_rounded;
    case ActivityType.sorting:
      return Icons.format_list_numbered_rounded;
  }
}

Color _activityColor(BuildContext context, ActivityType t) {
  final koru = context.koru;
  switch (t) {
    case ActivityType.quiz:
      return koru.agua;
    case ActivityType.matching:
      return koru.tierra;
    case ActivityType.memory:
      return koru.oro;
    case ActivityType.fillBlank:
      return koru.hoja;
    case ActivityType.sorting:
      return koru.fuego;
  }
}

// Página de detalle del curso - muestra todas las actividades de un curso específico
class CoursePage extends StatelessWidget {
  final Course course;
  final int courseIndex;

  const CoursePage({
    required this.course,
    required this.courseIndex,
    super.key,
  });

  Widget _buildActivityPage(LessonActivity activity) {
    if (activity is QuizActivity) return QuizPage(activity: activity);
    if (activity is MatchingActivity) return MatchingPage(activity: activity);
    if (activity is MemoryActivity) return MemoryPage(activity: activity);
    if (activity is FillBlankActivity) return FillBlankPage(activity: activity);
    if (activity is SortingActivity) return SortingPage(activity: activity);
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unidad')),
      body: AnimatedBuilder(
        animation: progressStats,
        builder: (context, _) {
          final theme = Theme.of(context);
          final koru = context.koru;
          final total = course.activities.length;
          final done = course.activities
              .where(progressStats.isActivityCompleted)
              .length;
          final ratio = total > 0 ? done / total : 0.0;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: koru.degradadoHero,
                  borderRadius: BorderRadius.circular(KoruRadius.xl),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: koru.textoHero,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            course.subtitle.isNotEmpty
                                ? course.subtitle
                                : 'Completa todas las actividades para dominar este tema.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: koru.textoHero.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$done de $total actividades',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: koru.textoHero,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: ratio,
                              strokeWidth: 7,
                              strokeCap: StrokeCap.round,
                              color: koru.textoHero,
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          Text(
                            '${(ratio * 100).round()}%',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: koru.textoHero,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const SectionTitle('Actividades'),
              for (final (index, activity) in course.activities.indexed)
                _ActivityStep(
                  number: index + 1,
                  activity: activity,
                  isLast: index == course.activities.length - 1,
                  onOpen: () {
                    if (!progressStats.isActivityUnlocked(activity)) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              'Completa la actividad $index para continuar.',
                            ),
                          ),
                        );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _buildActivityPage(activity),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Paso de la lista de actividades: número con línea de conexión y tarjeta.
class _ActivityStep extends StatelessWidget {
  const _ActivityStep({
    required this.number,
    required this.activity,
    required this.isLast,
    required this.onOpen,
  });

  final int number;
  final LessonActivity activity;
  final bool isLast;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    final color = _activityColor(context, activity.type);
    final isUnlocked = progressStats.isActivityUnlocked(activity);
    final isCompleted = progressStats.isActivityCompleted(activity);

    final markerColor = isCompleted
        ? koru.hoja
        : isUnlocked
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final markerForeground = isCompleted
        ? theme.colorScheme.onPrimary
        : isUnlocked
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(top: 22),
                  decoration: BoxDecoration(
                    color: markerColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isCompleted
                      ? Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: markerForeground,
                        )
                      : Text(
                          '$number',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: markerForeground,
                          ),
                        ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? koru.hoja.withValues(alpha: 0.5)
                            : theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Opacity(
                opacity: isUnlocked ? 1 : 0.6,
                child: FeatureCard(
                  title: activity.title,
                  subtitle: _activityLabel(activity.type),
                  icon: _activityIcon(activity.type),
                  color: color,
                  onTap: onOpen,
                  trailing: Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : isUnlocked
                        ? Icons.play_circle_fill_rounded
                        : Icons.lock_rounded,
                    size: 28,
                    color: isCompleted || isUnlocked
                        ? koru.hoja
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SHARED: RESULT SCREEN
// ─────────────────────────────────────────────
class ResultScreen extends StatefulWidget {
  final int score;
  final int total;
  final int incorrectAttempts;
  final VoidCallback onRetry;
  final String activityName;

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    this.incorrectAttempts = 0,
    required this.onRetry,
    required this.activityName,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

/// Nivel del resultado: decide estrellas, mensaje y animación.
enum _Nivel { perfecto, bien, regular, practicar }

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  // Entrada: mascota, título, estrellas y datos, escalonados.
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  // Movimiento continuo de la mascota (rebote o balanceo).
  late final AnimationController _bucle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    // Koru lo comentará al volver a Inicio.
    unawaited(
      KoruControlador.instancia.reaccionar(switch (_nivel) {
        _Nivel.perfecto => EventoKoru.leccionPerfecta,
        _Nivel.bien => EventoKoru.leccionBien,
        _Nivel.regular => EventoKoru.leccionRegular,
        _Nivel.practicar => EventoKoru.leccionPracticar,
      }, importante: true),
    );
  }

  @override
  void dispose() {
    _entrada.dispose();
    _bucle.dispose();
    super.dispose();
  }

  double get _precision {
    final intentos = widget.score + widget.incorrectAttempts;
    return intentos > 0 ? widget.score / intentos : 0.0;
  }

  _Nivel get _nivel {
    final pct = _precision;
    if (pct >= 1.0) return _Nivel.perfecto;
    if (pct >= 0.7) return _Nivel.bien;
    if (pct >= 0.4) return _Nivel.regular;
    return _Nivel.practicar;
  }

  Animation<double> _tramo(
    double inicio,
    double fin, [
    Curve curva = Curves.easeOutCubic,
  ]) => CurvedAnimation(
    parent: _entrada,
    curve: Interval(inicio, fin, curve: curva),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    final nivel = _nivel;
    final pct = _precision;
    final sinAnimaciones = MediaQuery.of(context).disableAnimations;

    final (
      String titulo,
      String mensaje,
      int estrellas,
      Color acento,
    ) = switch (nivel) {
      _Nivel.perfecto => (
        '¡Perfecto!',
        'Ni un solo error. ¡Eres un guardián del planeta!',
        3,
        koru.oro,
      ),
      _Nivel.bien => (
        '¡Muy bien!',
        'Vas por buen camino. Un poco más y será perfecto.',
        2,
        koru.hoja,
      ),
      _Nivel.regular => (
        '¡Buen intento!',
        'Repasa lo que fallaste y vuelve a probar.',
        1,
        koru.agua,
      ),
      _Nivel.practicar => (
        '¡Sigue practicando!',
        'Cada intento hace crecer lo que sabes. ¡Tú puedes!',
        0,
        koru.tierra,
      ),
    };

    final lluvia = switch (nivel) {
      _Nivel.perfecto => TipoCelebracion.confeti,
      _Nivel.bien => TipoCelebracion.hojas,
      _Nivel.regular => TipoCelebracion.chispas,
      _Nivel.practicar => null,
    };

    // La animación la pone esta pantalla; KoruMascota solo elige la pose.
    final mascota = KoruMascota(
      emocion: switch (nivel) {
        _Nivel.perfecto => EmocionKoru.celebrando,
        _Nivel.bien => EmocionKoru.feliz,
        _Nivel.regular => EmocionKoru.pensando,
        _Nivel.practicar => EmocionKoru.animando,
      },
      tamano: 156,
      animar: false,
    );

    // Movimiento de la mascota según el nivel.
    Widget mascotaAnimada = AnimatedBuilder(
      animation: Listenable.merge([_entrada, _bucle]),
      child: mascota,
      builder: (context, child) {
        final aparece = Curves.elasticOut.transform(
          _tramo(0.0, 0.55).value.clamp(0.0, 1.0),
        );
        final t = Curves.easeInOut.transform(_bucle.value);
        final (double dy, double angulo) = switch (nivel) {
          _Nivel.perfecto => (-14 * t, 0.0), // rebota
          _Nivel.bien => (-7 * t, 0.0), // pequeños saltos
          _Nivel.regular => (-3 * t, 0.0),
          _Nivel.practicar => (0.0, (t - 0.5) * 0.16), // se balancea
        };
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: angulo,
            child: Transform.scale(scale: aparece, child: child),
          ),
        );
      },
    );
    if (sinAnimaciones) mascotaAnimada = mascota;

    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Halo de color detrás de la mascota.
                      ScaleTransition(
                        scale: _tramo(0.0, 0.6),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                acento.withValues(alpha: 0.32),
                                acento.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (nivel == _Nivel.practicar)
                        Positioned(
                          bottom: 6,
                          right: 22,
                          child: _BroteCreciendo(
                            progreso: _tramo(0.45, 1.0),
                            color: koru.hoja,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: mascotaAnimada,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _Estrellas(
                  ganadas: estrellas,
                  entrada: _entrada,
                  color: koru.oro,
                  vacia: theme.colorScheme.outline,
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _tramo(0.25, 0.55),
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(_tramo(0.25, 0.6)),
                    child: Column(
                      children: [
                        Text(titulo, style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 6),
                        Text(
                          mensaje,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.activityName,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                FadeTransition(
                  opacity: _tramo(0.5, 0.8),
                  child: Row(
                    children: [
                      _DatoAnimado(
                        valor: widget.score,
                        sufijo: '/${widget.total}',
                        etiqueta: 'correctas',
                        icono: Icons.check_circle_rounded,
                        color: koru.hoja,
                      ),
                      const SizedBox(width: 10),
                      _DatoAnimado(
                        valor: (pct * 100).round(),
                        sufijo: '%',
                        etiqueta: 'precisión',
                        icono: Icons.track_changes_rounded,
                        color: koru.agua,
                      ),
                      const SizedBox(width: 10),
                      _DatoAnimado(
                        valor: widget.incorrectAttempts,
                        etiqueta: widget.incorrectAttempts == 1
                            ? 'error'
                            : 'errores',
                        icono: Icons.close_rounded,
                        color: koru.fuego,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                FadeTransition(
                  opacity: _tramo(0.65, 1.0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: nivel == _Nivel.perfecto
                            ? FilledButton.icon(
                                icon: const Icon(Icons.arrow_back_rounded),
                                label: const Text('Volver a la unidad'),
                                onPressed: () => Navigator.pop(context),
                              )
                            : FilledButton.icon(
                                icon: const Icon(Icons.replay_rounded),
                                label: const Text('Intentar de nuevo'),
                                onPressed: widget.onRetry,
                              ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: nivel == _Nivel.perfecto
                            ? OutlinedButton.icon(
                                icon: const Icon(Icons.replay_rounded),
                                label: const Text('Repetir'),
                                onPressed: widget.onRetry,
                              )
                            : OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Volver a la unidad'),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (lluvia != null && !sinAnimaciones)
          Positioned.fill(
            child: LluviaCelebracion(
              tipo: lluvia,
              colores: switch (lluvia) {
                TipoCelebracion.confeti => [
                  koru.oro,
                  koru.hoja,
                  koru.agua,
                  koru.fuego,
                  const Color(0xFFFF6FA8),
                ],
                TipoCelebracion.hojas => [
                  koru.hoja,
                  const Color(0xFF8BC34A),
                  const Color(0xFF2E7D32),
                ],
                TipoCelebracion.chispas => [koru.oro, koru.agua],
              },
            ),
          ),
      ],
    );
  }
}

/// Tres estrellas que aparecen una tras otra; las ganadas, rellenas.
class _Estrellas extends StatelessWidget {
  const _Estrellas({
    required this.ganadas,
    required this.entrada,
    required this.color,
    required this.vacia,
  });

  final int ganadas;
  final AnimationController entrada;
  final Color color;
  final Color vacia;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.only(
              left: 6,
              right: 6,
              // La del centro un poco más alta, como un podio.
              bottom: i == 1 ? 10 : 0,
            ),
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: entrada,
                curve: Interval(
                  0.35 + i * 0.12,
                  0.6 + i * 0.12,
                  curve: Curves.elasticOut,
                ),
              ),
              child: Icon(
                i < ganadas ? Icons.star_rounded : Icons.star_outline_rounded,
                size: i == 1 ? 54 : 44,
                color: i < ganadas ? color : vacia,
                shadows: i < ganadas
                    ? [
                        Shadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 16,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

/// Dato que cuenta desde 0 hasta su valor.
class _DatoAnimado extends StatelessWidget {
  const _DatoAnimado({
    required this.valor,
    required this.etiqueta,
    required this.icono,
    required this.color,
    this.sufijo = '',
  });

  final int valor;
  final String sufijo;
  final String etiqueta;
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(KoruRadius.m),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(icono, color: color),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: valor.toDouble()),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text(
                '${v.round()}$sufijo',
                style: theme.textTheme.titleLarge,
              ),
            ),
            Text(
              etiqueta,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Brote que crece junto a la mascota cuando hay que seguir practicando.
class _BroteCreciendo extends StatelessWidget {
  const _BroteCreciendo({required this.progreso, required this.color});

  final Animation<double> progreso;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progreso,
      builder: (context, _) {
        final t = progreso.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(
            alignment: Alignment.bottomCenter,
            scale: 0.3 + 0.7 * Curves.easeOutBack.transform(t.clamp(0, 1)),
            child: Icon(Icons.spa_rounded, size: 38, color: color),
          ),
        );
      },
    );
  }
}
