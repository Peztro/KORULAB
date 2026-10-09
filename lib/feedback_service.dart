import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

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
