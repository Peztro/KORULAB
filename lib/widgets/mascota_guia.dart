import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  const _Paso(this.titulo, this.mensaje);
}

const _pasos = [
  _Paso(
    '¡Hola, soy Koru!',
    'Seré tu guía en KORULAB. Aprenderemos juntos a cuidar el planeta.',
  ),
  _Paso(
    'Lecciones y Ruta Eko',
    'En Inicio encuentras tus lecciones y la Ruta Eko. Completa actividades para avanzar y mantener tu racha.',
  ),
  _Paso(
    'Retos, tienda y comunidad',
    'Gana ekostrellas con los retos ecológicos, canjéalas en la tienda y comparte ideas en Korucol y Korublog.',
  ),
];

class _MascotaGuiaDialog extends StatefulWidget {
  const _MascotaGuiaDialog();

  @override
  State<_MascotaGuiaDialog> createState() => _MascotaGuiaDialogState();
}

class _MascotaGuiaDialogState extends State<_MascotaGuiaDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);
  int _paso = 0;

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paso = _pasos[_paso];
    final esUltimo = _paso == _pasos.length - 1;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _bounce,
              builder: (_, child) => Transform.translate(
                offset: Offset(
                  0,
                  -8 * Curves.easeInOut.transform(_bounce.value),
                ),
                child: child,
              ),
              child: Image.asset('assets/images/koru_base.png', height: 140),
            ),
            const SizedBox(height: 12),
            Text(
              paso.titulo,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              paso.mensaje,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pasos.length; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _paso ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _paso
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
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
    );
  }
}
