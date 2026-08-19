import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/app_controller.dart';

class WeekStreak extends StatelessWidget {
  const WeekStreak({super.key});

  String _toIsoDate(DateTime dt) {
    final d = DateTime(dt.year, dt.month, dt.day);
    return d.toIso8601String().split('T').first;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final datesIso = controller.learningDatesIso;

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1)); // Monday

    final dayIsLearned = <bool>[];
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      dayIsLearned.add(datesIso.contains(_toIsoDate(date)));
    }

    final learnedCount = dayIsLearned.where((e) => e).length;

    final cs = Theme.of(context).colorScheme;
    const labels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Diese Woche: $learnedCount',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(7, (i) {
            final learned = dayIsLearned[i];
            return Expanded(
              child: Column(
                children: [
                  Text(
                    labels[i],
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 18,
                    decoration: BoxDecoration(
                      color: learned ? cs.primary : cs.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

