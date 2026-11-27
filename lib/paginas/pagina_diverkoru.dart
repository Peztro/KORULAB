import 'package:flutter/material.dart';

import '../juegos/datos_juegos.dart';
import '../juegos/records_diverkoru.dart';
import '../juegos/sopa_letras.dart';
import '../tema/tema_korulab.dart';
import '../widgets/koru_mascota.dart';
import '../widgets/ui_koru.dart';
import 'diverkoru/juego_clasifica.dart';
import 'diverkoru/juego_gotas.dart';
import 'diverkoru/juego_sopa.dart';
import 'diverkoru/juego_trivia.dart';
import 'diverkoru/portada_juego.dart';

/// Los juegos de DiverKoru, con lo que muestra la portada de cada uno.
final fichasDiverKoru = <FichaJuego>[
  FichaJuego(
    titulo: 'Clasifica la basura',
    descripcion:
        'Separa en su caneca todos los residuos que puedas en '
        '$segundosClasifica segundos.',
    icono: Icons.recycling_rounded,
    comoJugar: [
      'Arrastra cada residuo a su caneca, o toca la caneca correcta.',
      'Blanca: aprovechables limpios y secos. Verde: orgánicos. '
          'Negra: no aprovechables.',
      'Cada error te quita $penalizacionClasifica segundos.',
      'El ranking cuenta los objetos bien separados.',
    ],
    modos: [
      ModoJuego(
        nombre: 'Clasificar',
        juego: JuegoDiverKoru.clasifica,
        crear: () => const JuegoClasifica(),
      ),
    ],
  ),
  FichaJuego(
    titulo: 'Trivia relámpago',
    descripcion: 'Responde preguntas ecológicas mientras te dure el reloj.',
    icono: Icons.bolt_rounded,
    comoJugar: [
      'Empiezas con 60 segundos.',
      'Cada acierto suma tiempo: 5 s al principio, luego 4 s y después 3 s.',
      'Cada fallo hace que el reloj corra más rápido; los aciertos lo '
          'vuelven a calmar.',
      'El ranking cuenta las respuestas correctas.',
    ],
    modos: [
      ModoJuego(
        nombre: 'Trivia',
        juego: JuegoDiverKoru.trivia,
        crear: () => const JuegoTrivia(),
      ),
    ],
  ),
  FichaJuego(
    titulo: 'Sopa de letras verde',
    descripcion:
        'Encuentra todas las palabras de la naturaleza lo más '
        'rápido que puedas.',
    icono: Icons.grid_on_rounded,
    comoJugar: [
      'Desliza el dedo sobre las letras para marcar cada palabra.',
      'Las palabras pueden estar en horizontal, vertical o diagonal, y '
          'también al revés.',
      'El ranking es por tiempo: gana quien la completa más rápido.',
      'Cada dificultad tiene su propio ranking.',
    ],
    modos: [
      for (final modo in ModoSopa.values)
        ModoJuego(
          nombre: modo.nombre,
          juego: modo.juego,
          detalle:
              '${modo.palabras} palabras · tablero de '
              '${modo.tamano}×${modo.tamano}',
          crear: () => JuegoSopa(modo: modo),
        ),
    ],
  ),
  FichaJuego(
    titulo: 'Salva las gotas',
    descripcion:
        'Atrapa el agua limpia con la planta y esquiva las gotas '
        'contaminadas.',
    icono: Icons.water_drop_rounded,
    comoJugar: [
      'Mueve la planta con el dedo.',
      'Agua: +1. Agua dorada: +1 corazón.',
      'Aceite −1 ❤, lluvia ácida −2 ❤ y petróleo −3 ❤.',
      'Cada gota de agua que cae al suelo te quita un corazón.',
      'El ranking cuenta las gotas salvadas.',
    ],
    modos: [
      ModoJuego(
        nombre: 'Gotas',
        juego: JuegoDiverKoru.gotas,
        crear: () => const JuegoGotas(),
      ),
    ],
  ),
];

/// Pestaña DiverKoru: minijuegos para aprender a cuidar el planeta.
class DiverKoruSection extends StatefulWidget {
  const DiverKoruSection({super.key});

  @override
  State<DiverKoruSection> createState() => _DiverKoruSectionState();
}

class _DiverKoruSectionState extends State<DiverKoruSection> {
  Map<JuegoDiverKoru, int> _records = const {};

  @override
  void initState() {
    super.initState();
    _cargarRecords();
  }

  Future<void> _cargarRecords() async {
    final records = await RecordsDiverKoru.leerTodos();
    if (mounted) setState(() => _records = records);
  }

  Future<void> _abrir(FichaJuego ficha, Color color) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PortadaJuego(ficha: ficha, color: color),
      ),
    );
    _cargarRecords();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    final colores = [koru.hoja, koru.oro, koru.agua, koru.tierra];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: koru.degradadoHero,
            borderRadius: BorderRadius.circular(KoruRadius.xl),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DiverKoru',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: koru.textoHero,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Juega, compite en el ranking de Korulab y aprende a '
                      'cuidar el planeta al mismo tiempo.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: koru.textoHero.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const KoruMascota(emocion: EmocionKoru.jugando, tamano: 96),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const SectionTitle('Juegos'),
        for (final (i, ficha) in fichasDiverKoru.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FeatureCard(
              title: ficha.titulo,
              subtitle: ficha.descripcion,
              icon: ficha.icono,
              color: colores[i % colores.length],
              trailing: _Record(ficha: ficha, records: _records),
              onTap: () => _abrir(ficha, colores[i % colores.length]),
            ),
          ),
      ],
    );
  }
}

/// Tu récord en la tarjeta del juego (en la sopa, el de la dificultad más
/// alta que hayas completado), o una flecha de "jugar" si aún no hay.
class _Record extends StatelessWidget {
  const _Record({required this.ficha, required this.records});
  final FichaJuego ficha;
  final Map<JuegoDiverKoru, int> records;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    final conRecord = [
      for (final modo in ficha.modos.reversed)
        if ((records[modo.juego] ?? 0) > 0) modo,
    ];
    if (conRecord.isEmpty) {
      return Icon(Icons.play_circle_fill_rounded, color: koru.hoja, size: 32);
    }
    final modo = conRecord.first;
    final texto = modo.juego.formatear(records[modo.juego]!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: koru.oro.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded, size: 16, color: koru.oro),
          const SizedBox(width: 4),
          Text(
            ficha.modos.length > 1 ? '$texto ${modo.nombre}' : texto,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
