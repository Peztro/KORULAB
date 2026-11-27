import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tema/tema_korulab.dart';
import 'koru_mascota.dart';

/// Guía de bienvenida en la que Koru se presenta. Sale la primera vez que
/// un estudiante entra y se puede repetir desde Ajustes.
class MascotaGuia {
  static String _key(String username) => 'mascota_intro_vista_$username';

  static Future<void> mostrarSiEsPrimeraVez(
    BuildContext context,
    String username,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_key(username)) ?? false) return;
    if (!context.mounted) return;
    await prefs.setBool(_key(username), true);
    if (!context.mounted) return;
    await mostrar(context);
  }

  static Future<void> mostrar(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _MascotaGuiaDialog(),
    );
  }
}

class _Paso {
  final String titulo;
  final String mensaje;
  final EmocionKoru emocion;
  const _Paso(this.titulo, this.mensaje, this.emocion);
}

const _pasos = [
  _Paso(
    '¡Hola, soy Koru!',
    'Seré tu guía en Korulab. Aprenderemos juntos a cuidar el planeta.',
    EmocionKoru.saludando,
  ),
  _Paso(
    'Lecciones y Ruta Eko',
    'En Inicio encuentras la Ruta Eko: un camino de unidades. Completa '
        'actividades para avanzar y mantener tu racha 🔥',
    EmocionKoru.feliz,
  ),
  _Paso(
    'Retos, tienda y comunidad',
    'Gana ekostrellas y canjéalas en la tienda. Descubre trucos verdes en Konsejos, '
        'comparte ideas en Korublog ¡y escríbeles a tus amigos!',
    EmocionKoru.feliz,
  ),
  _Paso(
    'Siempre estaré cerca',
    'Me verás en la esquina de Inicio. Tócame cuando quieras y te daré un '
        'consejo para cuidar el planeta 🌱',
    EmocionKoru.feliz,
  ),
];

class _MascotaGuiaDialog extends StatefulWidget {
  const _MascotaGuiaDialog();

  @override
  State<_MascotaGuiaDialog> createState() => _MascotaGuiaDialogState();
}

class _MascotaGuiaDialogState extends State<_MascotaGuiaDialog> {
  int _paso = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    final paso = _pasos[_paso];
    final esUltimo = _paso == _pasos.length - 1;
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera con el degradado de la marca y Koru.
          Container(
            height: 190,
            decoration: BoxDecoration(gradient: koru.degradadoHero),
            alignment: Alignment.center,
            child: KoruMascota(emocion: paso.emocion, tamano: 150),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Column(
                    key: ValueKey(_paso),
                    children: [
                      Text(
                        paso.titulo,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        paso.mensaje,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _pasos.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _paso ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _paso
                              ? koru.hoja
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (!esUltimo)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Omitir'),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        if (esUltimo) {
                          Navigator.pop(context);
                        } else {
                          setState(() => _paso++);
                        }
                      },
                      child: Text(esUltimo ? '¡Empezar!' : 'Siguiente'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
