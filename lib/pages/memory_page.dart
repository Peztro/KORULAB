import 'dart:async';
import 'package:flutter/material.dart';
import '../feedback_service.dart';
import '../models/course_models.dart';
import '../pages/course_page.dart';
import '../services/progress_stats.dart';

// ─────────────────────────────────────────────
//  3. MEMORY CARD GAME PAGE
// ─────────────────────────────────────────────
class MemoryPage extends StatefulWidget {
  final MemoryActivity activity;
  const MemoryPage({super.key, required this.activity});

  @override
  State<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends State<MemoryPage> {
  late List<MemoryItem> cardItems;
  List<int> selectedIndices = [];
  int score = 0;
  int incorrectAttempts = 0;
  bool completed = false;
  bool busy = false;
  bool _reportedCompletion = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    final cards = widget.activity.cards;
    final doubled = <MemoryCard>[];
    for (final card in cards) {
      doubled.add(card);
      doubled.add(card);
    }
    doubled.shuffle();

    cardItems = doubled.map((c) => MemoryItem(card: c)).toList();
    selectedIndices.clear();
    score = 0;
    incorrectAttempts = 0;
    completed = false;
    busy = false;
    _reportedCompletion = false;
  }

  void _onCardTap(int index) {
    if (busy || cardItems[index].isFlipped || cardItems[index].isMatched)
      return;

    setState(() {
      cardItems[index].isFlipped = true;
      selectedIndices.add(index);
    });

    if (selectedIndices.length == 2) {
      final firstIdx = selectedIndices[0];
      final secondIdx = selectedIndices[1];
      final firstCard = cardItems[firstIdx].card;
      final secondCard = cardItems[secondIdx].card;

      if (firstCard.label == secondCard.label) {
        setState(() {
          cardItems[firstIdx].isMatched = true;
          cardItems[secondIdx].isMatched = true;
          selectedIndices.clear();
          score++;
          if (score == widget.activity.cards.length) {
            completed = true;
            if (!_reportedCompletion) {
              _reportedCompletion = true;
              progressStats.reportLessonResult(
                widget.activity.cards.length,
                widget.activity.cards.length,
                activity: widget.activity,
                incorrectAttempts: incorrectAttempts,
              );
            }
          }
        });
      } else {
        setState(() {
          incorrectAttempts++;
          unawaited(vibrateOnWrongAnswer());
          busy = true;
        });
        Timer(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              cardItems[firstIdx].isFlipped = false;
              cardItems[secondIdx].isFlipped = false;
              selectedIndices.clear();
              busy = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.activity.title),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: completed
            ? ResultScreen(
                score: widget.activity.cards.length,
                total: widget.activity.cards.length,
                incorrectAttempts: incorrectAttempts,
                onRetry: _reset,
                activityName: widget.activity.title,
              )
            : Column(
                children: [
                  Text(
                    'Encuentra las parejas de iconos ecológicos.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: cardItems.length,
                      itemBuilder: (context, index) {
                        final item = cardItems[index];
                        final showFace = item.isFlipped || item.isMatched;

                        return GestureDetector(
                          onTap: () => _onCardTap(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: showFace
                                  ? theme.colorScheme.primaryContainer
                                        .withOpacity(0.2)
                                  : theme.colorScheme.surfaceContainerHighest
                                        .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: showFace
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.outlineVariant,
                                width: 2,
                              ),
                              boxShadow: showFace
                                  ? [
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.2),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: showFace
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          item.card.emoji,
                                          style: const TextStyle(fontSize: 32),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item.card.label,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    )
                                  : Icon(
                                      Icons.eco,
                                      size: 36,
                                      color: theme.colorScheme.primaryContainer,
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class MemoryItem {
  final MemoryCard card;
  bool isFlipped = false;
  bool isMatched = false;
  MemoryItem({
    required this.card,
    this.isFlipped = false,
    this.isMatched = false,
  });
}
