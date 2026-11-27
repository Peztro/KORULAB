import 'package:flutter/material.dart';

import '../tema/tema_korulab.dart';
import '../widgets/koru_mascota.dart';
import '../widgets/ui_koru.dart';

/// Pestaña DiverKoru: aquí vivirán los juegos. Por ahora, "Próximamente".
class DiverKoruSection extends StatelessWidget {
  const DiverKoruSection({super.key});

  /// Ideas de juegos para mostrar como adelanto. Se pueden cambiar libremente
  /// cuando se decidan los juegos reales.
  static const _juegos = <(IconData, String, String)>[
    (
      Icons.recycling_rounded,
      'Clasifica la basura',
      'Arrastra cada residuo a su contenedor antes de que se acabe el tiempo.',
    ),
    (
      Icons.bolt_rounded,
      'Trivia relámpago',
      'Responde preguntas ecológicas lo más rápido que puedas.',
    ),
    (
      Icons.grid_on_rounded,
      'Sopa de letras verde',
      'Encuentra palabras sobre naturaleza escondidas en el tablero.',
    ),
    (
      Icons.water_drop_rounded,
      'Salva las gotas',
      'Atrapa el agua antes de que se desperdicie.',
    ),
  ];

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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'PRÓXIMAMENTE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: koru.textoHero,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'DiverKoru',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: koru.textoHero,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Muy pronto podrás jugar y aprender a cuidar el '
                      'planeta al mismo tiempo. ¡Koru está preparando '
                      'los juegos!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: koru.textoHero.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const KoruMascota(emocion: EmocionKoru.pensando, tamano: 96),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const SectionTitle('Lo que viene'),
        for (final (i, (icono, titulo, descripcion)) in _juegos.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Opacity(
              opacity: 0.7,
              child: FeatureCard(
                title: titulo,
                subtitle: descripcion,
                icon: icono,
                color: colores[i % colores.length],
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Pronto',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () => ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text('"$titulo" llegará muy pronto 🐌')),
                  ),
              ),
            ),
          ),
      ],
    );
  }
}
