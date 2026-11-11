import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Pide confirmación antes de salir de una lección en curso.
class LeaveLessonGuard extends StatelessWidget {
  final bool active;
  final Widget child;
  const LeaveLessonGuard({super.key, required this.active, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !active,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Estás seguro?'),
            content: const Text(
              'Si sales ahora perderás el progreso de esta lección.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Continuar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salir'),
              ),
            ],
          ),
        );
        if (leave == true) navigator.pop();
      },
      child: child,
    );
  }
}

/// Notificación inferior con "Incorrecto" y la respuesta correcta.
void showWrongAnswerNotice(BuildContext context, String correctAnswer) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: Colors.red.shade800,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Incorrecto',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            'Respuesta correcta: $correctAnswer',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    ),
  );
}

/// Vibración de duración media (300 ms) al responder mal.
Future<void> vibrateOnWrongAnswer() async {
  try {
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(duration: 300);
    } else {
      await HapticFeedback.heavyImpact();
    }
  } catch (_) {
    // La vibración nunca debe interrumpir la lección.
  }
}
