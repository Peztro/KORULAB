import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/course_catalog.dart';
import '../db_service.dart';
import '../models/course_models.dart';
import '../pages/reward_shop_page.dart';

// Gestor de estadísticas del usuario - rastrear respuestas correctas, lecciones completadas, racha diaria y ekostrellas
class ProgressStats extends ChangeNotifier {
  int _correctAnswers = 0;
  int _totalAnswers = 0;
  int _completedLessons = 0;
  int _dailyStreak = 0;
  int _ekostrellas = 0;
  int _hintCredits = 0;
  int _streakProtectors = 0;
  int _starMultipliers = 0;
  int _secondChances = 0;
  DateTime? _lastLessonDate;
  String? _progressUsername;
  bool _courseProgressLoaded = false;
  final Set<String> _completedActivityIds = {};

  int get correctAnswers => _correctAnswers;
  int get totalAnswers => _totalAnswers;
  int get completedLessons => _completedLessons;
  int get dailyStreak => _dailyStreak;
  int get ekostrellas => _ekostrellas;
  int get hintCredits => _hintCredits;
  int get streakProtectors => _streakProtectors;
  int get starMultipliers => _starMultipliers;
  int get secondChances => _secondChances;
  int get completedActivities => _completedActivityIds.length;
  bool get isCourseProgressLoaded => _courseProgressLoaded;
  int get totalLessons =>
      courses.fold<int>(0, (sum, course) => sum + course.activities.length);

  int get accuracyPercent =>
      _totalAnswers > 0 ? (_correctAnswers * 100 ~/ _totalAnswers) : 0;
  double get accuracyRatio =>
      _totalAnswers > 0 ? _correctAnswers / _totalAnswers : 0.0;

  Future<int> loadCourseProgress(String username) async {
    if (_progressUsername == username) return 0;
    _progressUsername = username;
    _courseProgressLoaded = false;
    _completedActivityIds.clear();
    _correctAnswers = 0;
    _totalAnswers = 0;
    _completedLessons = 0;
    _ekostrellas = 0;
    _dailyStreak = 0;
    _hintCredits = 0;
    _streakProtectors = 0;
    _starMultipliers = 0;
    _secondChances = 0;
    _lastLessonDate = null;
    notifyListeners();

    var activatedProtectors = 0;
    try {
      await DBService.pullProgress(username);
      final preferences = await SharedPreferences.getInstance();
      if (_progressUsername == username) {
        _completedActivityIds.addAll(
          preferences.getStringList('korulab_course_progress_$username') ?? [],
        );
        _ekostrellas = preferences.getInt('korulab_eko_stars_$username') ?? 0;
        _correctAnswers =
            preferences.getInt('korulab_correct_answers_$username') ?? 0;
        _totalAnswers =
            preferences.getInt('korulab_total_answers_$username') ?? 0;
        _completedLessons =
            preferences.getInt('korulab_completed_lessons_$username') ?? 0;
        _dailyStreak =
            preferences.getInt('korulab_daily_streak_$username') ?? 0;
        _hintCredits =
            preferences.getInt('korulab_hint_credits_$username') ?? 0;
        _streakProtectors =
            preferences.getInt('korulab_streak_protectors_$username') ?? 0;
        _starMultipliers =
            preferences.getInt('korulab_star_multipliers_$username') ?? 0;
        _secondChances =
            preferences.getInt('korulab_second_chances_$username') ?? 0;
        final savedDate = preferences.getString(
          'korulab_last_lesson_$username',
        );
        _lastLessonDate = savedDate == null
            ? null
            : DateTime.tryParse(savedDate);

        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final hadMissedDays =
            _lastLessonDate != null &&
            todayDate.difference(_lastLessonDate!).inDays > 1;
        activatedProtectors = _activateMissedDayProtectors(todayDate);
        if (hadMissedDays) await _saveUserProgress();
      }
    } catch (_) {
    } finally {
      if (_progressUsername == username) {
        _courseProgressLoaded = true;
        notifyListeners();
      }
    }
    return activatedProtectors;
  }

  int _activateMissedDayProtectors(DateTime today) {
    final lastLesson = _lastLessonDate;
    if (lastLesson == null) return 0;

    final missedDays = today.difference(lastLesson).inDays - 1;
    if (missedDays <= 0) return 0;

    final activated = _streakProtectors < missedDays
        ? _streakProtectors
        : missedDays;
    _streakProtectors -= activated;
    if (activated == missedDays) {
      _dailyStreak += missedDays;
    } else {
      _dailyStreak = 0;
    }
    _lastLessonDate = today.subtract(const Duration(days: 1));
    return activated;
  }

  bool isCourseUnlocked(int courseIndex) {
    for (var index = 0; index < courseIndex; index++) {
      for (
        var activityIndex = 0;
        activityIndex < courses[index].activities.length;
        activityIndex++
      ) {
        if (!_completedActivityIds.contains('$index:$activityIndex')) {
          return false;
        }
      }
    }
    return true;
  }

  // Actividades de cursos de profesores -> id de progreso.
  final Map<LessonActivity, String> customActivityIds = {};

  bool isActivityUnlocked(LessonActivity activity) {
    final customId = customActivityIds[activity];
    if (customId != null) {
      final parts = customId.split(':');
      if (parts.length != 2) return true;
      final targetCourse = int.tryParse(parts[0]);
      final targetActivity = int.tryParse(parts[1]);
      if (targetCourse == null ||
          targetActivity == null ||
          targetCourse >= courses.length) {
        return true;
      }
      for (var courseIndex = 0; courseIndex <= targetCourse; courseIndex++) {
        final end = courseIndex == targetCourse
            ? targetActivity
            : courses[courseIndex].activities.length;
        for (var activityIndex = 0; activityIndex < end; activityIndex++) {
          if (!_completedActivityIds.contains('$courseIndex:$activityIndex')) {
            return false;
          }
        }
      }
      return true;
    }
    for (var courseIndex = 0; courseIndex < courses.length; courseIndex++) {
      for (
        var activityIndex = 0;
        activityIndex < courses[courseIndex].activities.length;
        activityIndex++
      ) {
        final currentActivity = courses[courseIndex].activities[activityIndex];
        if (identical(currentActivity, activity)) return true;
        if (!_completedActivityIds.contains('$courseIndex:$activityIndex')) {
          return false;
        }
      }
    }
    return false;
  }

  String _activityProgressId(LessonActivity activity) {
    final customId = customActivityIds[activity];
    if (customId != null) return customId;
    for (var courseIndex = 0; courseIndex < courses.length; courseIndex++) {
      final activityIndex = courses[courseIndex].activities.indexOf(activity);
      if (activityIndex >= 0) return '$courseIndex:$activityIndex';
    }
    return activity.title;
  }

  Future<void> _saveUserProgress() async {
    final username = _progressUsername;
    if (username == null) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList(
        'korulab_course_progress_$username',
        _completedActivityIds.toList(),
      );
      await preferences.setInt(
        'korulab_correct_answers_$username',
        _correctAnswers,
      );
      await preferences.setInt(
        'korulab_total_answers_$username',
        _totalAnswers,
      );
      await preferences.setInt(
        'korulab_completed_lessons_$username',
        _completedLessons,
      );
      await preferences.setInt('korulab_eko_stars_$username', _ekostrellas);
      await preferences.setInt('korulab_daily_streak_$username', _dailyStreak);
      await preferences.setInt('korulab_hint_credits_$username', _hintCredits);
      await preferences.setInt(
        'korulab_streak_protectors_$username',
        _streakProtectors,
      );
      await preferences.setInt(
        'korulab_star_multipliers_$username',
        _starMultipliers,
      );
      await preferences.setInt(
        'korulab_second_chances_$username',
        _secondChances,
      );
      final lastLesson = _lastLessonDate;
      if (lastLesson != null) {
        await preferences.setString(
          'korulab_last_lesson_$username',
          lastLesson.toIso8601String(),
        );
      }
    } catch (_) {}
    unawaited(DBService.pushProgress(username));
  }

  bool buyHint() {
    if (!_courseProgressLoaded || _ekostrellas < RewardShopPage.hintPrice) {
      return false;
    }
    _ekostrellas -= RewardShopPage.hintPrice;
    _hintCredits++;
    unawaited(_saveUserProgress());
    notifyListeners();
    return true;
  }

  bool buyStreakProtector() {
    if (!_courseProgressLoaded ||
        _ekostrellas < RewardShopPage.streakProtectorPrice) {
      return false;
    }
    _ekostrellas -= RewardShopPage.streakProtectorPrice;
    _streakProtectors++;
    unawaited(_saveUserProgress());
    notifyListeners();
    return true;
  }

  bool buyStarMultiplier() {
    if (!_courseProgressLoaded ||
        _ekostrellas < RewardShopPage.starMultiplierPrice) {
      return false;
    }
    _ekostrellas -= RewardShopPage.starMultiplierPrice;
    _starMultipliers++;
    unawaited(_saveUserProgress());
    notifyListeners();
    return true;
  }

  bool buySecondChance() {
    if (!_courseProgressLoaded ||
        _ekostrellas < RewardShopPage.secondChancePrice) {
      return false;
    }
    _ekostrellas -= RewardShopPage.secondChancePrice;
    _secondChances++;
    unawaited(_saveUserProgress());
    notifyListeners();
    return true;
  }

  bool useHint() {
    if (_hintCredits <= 0) return false;
    _hintCredits--;
    unawaited(_saveUserProgress());
    notifyListeners();
    return true;
  }

  bool useSecondChance() {
    if (_secondChances <= 0) return false;
    _secondChances--;
    unawaited(_saveUserProgress());
    notifyListeners();
    return true;
  }

  bool isTeacherLessonCompleted(int lessonId) {
    return _completedActivityIds.contains('teacher:$lessonId');
  }

  bool isActivityCompleted(LessonActivity activity) {
    return _completedActivityIds.contains(_activityProgressId(activity));
  }

  bool completeTeacherLesson(int lessonId) {
    if (!_courseProgressLoaded ||
        !_completedActivityIds.add('teacher:$lessonId')) {
      return false;
    }
    _recordLessonDay();
    _correctAnswers++;
    _totalAnswers++;
    _completedLessons++;
    if (_starMultipliers > 0) {
      _starMultipliers--;
      _ekostrellas += 100;
    } else {
      _ekostrellas += 50;
    }
    unawaited(_saveUserProgress());
    notifyListeners();
    return true;
  }

  void _recordLessonDay() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (_lastLessonDate == todayDate) return;
    if (_lastLessonDate == null) {
      _dailyStreak = 1;
    } else {
      _activateMissedDayProtectors(todayDate);
      final daysSinceLastLesson = todayDate.difference(_lastLessonDate!).inDays;
      _dailyStreak = daysSinceLastLesson == 1 && _dailyStreak > 0
          ? _dailyStreak + 1
          : 1;
    }
    _lastLessonDate = todayDate;
  }

  void reportLessonResult(
    int correct,
    int total, {
    required LessonActivity activity,
    int incorrectAttempts = 0,
  }) {
    _recordLessonDay();
    _correctAnswers += correct;
    _totalAnswers += correct + incorrectAttempts;
    _completedLessons += 1;
    final earnedStars = total > 0 ? (correct * 50 ~/ total) : 0;
    if (_starMultipliers > 0) {
      _starMultipliers--;
      _ekostrellas += earnedStars * 2;
    } else {
      _ekostrellas += earnedStars;
    }
    _completedActivityIds.add(_activityProgressId(activity));
    unawaited(_saveUserProgress());
    notifyListeners();
  }
}

final progressStats = ProgressStats();
