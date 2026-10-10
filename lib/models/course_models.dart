import 'package:flutter/material.dart';
import '../data/course_catalog.dart';

// Convierte un id de progreso ("curso:actividad") en un nombre legible.
String describeActivityId(String id) {
  final parts = id.split(':');
  if (parts.length == 2) {
    final c = int.tryParse(parts[0]);
    final a = int.tryParse(parts[1]);
    if (c != null &&
        a != null &&
        c < courses.length &&
        a < courses[c].activities.length) {
      return '${courses[c].title} · ${courses[c].activities[a].title}';
    }
  }
  return id;
}

// Representa un curso con su título, ícono y lista de actividades de aprendizaje
class Course {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<LessonActivity> activities;

  Course({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.activities,
  });
}

// Clase abstracta base para todas las actividades educativas (quiz, matching, memory, etc)
abstract class LessonActivity {
  final String title;
  final ActivityType type;
  const LessonActivity({required this.title, required this.type});
}

enum ActivityType { quiz, matching, memory, fillBlank, sorting }

// Actividad de tipo cuestionario múltiple - los usuarios responden preguntas seleccionando opciones
class QuizActivity extends LessonActivity {
  final List<Question> questions;
  const QuizActivity({required super.title, required this.questions})
    : super(type: ActivityType.quiz);
}

// Representa una pregunta individual con opciones y respuesta correcta
class Question {
  final String prompt;
  final List<String> options;
  final int answerIndex;
  const Question({
    required this.prompt,
    required this.options,
    required this.answerIndex,
  });
}

// Actividad de relacionar - los usuarios emparejan términos con sus definiciones
class MatchingActivity extends LessonActivity {
  final List<MatchPair> pairs;
  const MatchingActivity({required super.title, required this.pairs})
    : super(type: ActivityType.matching);
}

// Representa un par de término y definición para actividades de relacionar
class MatchPair {
  final String term;
  final String definition;
  const MatchPair({required this.term, required this.definition});
}

// Actividad de memoria - juego tipo memorama para recordar parejas de elementos
class MemoryActivity extends LessonActivity {
  final List<MemoryCard> cards;
  const MemoryActivity({required super.title, required this.cards})
    : super(type: ActivityType.memory);
}

// Representa una tarjeta individual en el juego de memoria con emoji y etiqueta
class MemoryCard {
  final String emoji;
  final String label;
  const MemoryCard({required this.emoji, required this.label});
}

// Actividad de completar espacios - los usuarios rellenan los blancos en oraciones
class FillBlankActivity extends LessonActivity {
  final List<FillBlankQuestion> questions;
  const FillBlankActivity({required super.title, required this.questions})
    : super(type: ActivityType.fillBlank);
}

// Representa una pregunta de espacios en blanco con opciones de respuesta
class FillBlankQuestion {
  final String sentence; // uses ___ for blank
  final List<String> options;
  final int answerIndex;
  const FillBlankQuestion({
    required this.sentence,
    required this.options,
    required this.answerIndex,
  });
}

// Actividad de ordenamiento - los usuarios deben ordenar elementos en la secuencia correcta
class SortingActivity extends LessonActivity {
  final String instruction;
  final List<String> correctOrder;
  const SortingActivity({
    required super.title,
    required this.instruction,
    required this.correctOrder,
  }) : super(type: ActivityType.sorting);
}
