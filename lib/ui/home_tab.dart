import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/seed_vocab.dart';
import '../models/vocab.dart';
import '../state/app_controller.dart';
import 'widgets/week_streak.dart';
import 'widgets/learning_session_view.dart';
import 'widgets/topic_label.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  void _startSession(
    BuildContext context, {
    required LearningModeType mode,
    required List<VocabSeed> seeds,
    required String title,
    required String emptyMessage,
  }) {
    if (seeds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emptyMessage)),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LearningSessionView(
          mode: mode,
          seeds: seeds,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final profile = controller.profile;
    final hasTopics = (profile?.selectedTopicIds.isNotEmpty ?? false);
    final selectedTopics = controller.selectedTopics;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Lernen', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (hasTopics) const WeekStreak() else _EmptyTopicsHint(),
        const SizedBox(height: 18),
        if (!hasTopics) ...[
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Bitte erst Themen in der Bibliothek auswählen.'),
                ),
              );
            },
            child: const Text('Themen auswählen'),
          ),
        ] else ...[
          // ── All selected sets ─────────────────────────────────────────
          Text('Alle ausgewählten Sets',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _ModeButton(
            title: 'Normal',
            subtitle: 'Englisch → Spanisch',
            countText:
                '${controller.getNormalModeSeeds().length} Vokabeln',
            onPressed: () => _startSession(
              context,
              mode: LearningModeType.normal,
              seeds: controller.getNormalModeSeeds(),
              title: 'Normaler Lernmodus',
              emptyMessage: 'Keine Vokabeln verfügbar.',
            ),
          ),
          const SizedBox(height: 10),
          _ModeButton(
            title: 'Umgekehrt',
            subtitle: 'Spanisch → Englisch',
            countText:
                '${controller.getNormalModeSeeds().length} Vokabeln',
            onPressed: () => _startSession(
              context,
              mode: LearningModeType.reverse,
              seeds: controller.getNormalModeSeeds(),
              title: 'Umgekehrter Lernmodus',
              emptyMessage: 'Keine Vokabeln verfügbar.',
            ),
          ),
          const SizedBox(height: 10),
          _ModeButton(
            title: 'Prioritäten',
            subtitle: 'Nur priorisierte Vokabeln',
            countText:
                '${controller.getPrioritiesModeSeeds().length} Vokabeln',
            onPressed: () => _startSession(
              context,
              mode: LearningModeType.priorities,
              seeds: controller.getPrioritiesModeSeeds(),
              title: 'Prioritäten-Modus',
              emptyMessage: 'Keine priorisierten Vokabeln vorhanden.',
            ),
          ),
          const SizedBox(height: 10),
          _ModeButton(
            title: 'Wiederholen (unsicher)',
            subtitle: 'Häufig gesehen, noch nicht gelernt',
            countText:
                '${controller.getReviewUnknownModeSeeds().length} Vokabeln',
            onPressed: () => _startSession(
              context,
              mode: LearningModeType.reviewUnknown,
              seeds: controller.getReviewUnknownModeSeeds(),
              title: 'Wiederholen (unsicher)',
              emptyMessage: 'Noch keine passenden Vokabeln vorhanden.',
            ),
          ),
          const SizedBox(height: 24),

          // ── Per-topic cards ──────────────────────────────────────────
          Text('Vokabelsets',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Starte ein ganzes Thema oder einen einzelnen Chapter.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ...selectedTopics.map(
            (topic) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TopicSetCard(
                topic: topic,
                controller: controller,
                onStart: (mode, seeds, title) => _startSession(
                  context,
                  mode: mode,
                  seeds: seeds,
                  title: title,
                  emptyMessage:
                      'Keine Vokabeln in „${topic.label}" verfügbar.',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Topic card with chapter expansion ──────────────────────────────────────

class _TopicSetCard extends StatefulWidget {
  final TopicDef topic;
  final AppController controller;
  final void Function(LearningModeType, List<VocabSeed>, String) onStart;

  const _TopicSetCard({
    required this.topic,
    required this.controller,
    required this.onStart,
  });

  @override
  State<_TopicSetCard> createState() => _TopicSetCardState();
}

class _TopicSetCardState extends State<_TopicSetCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final topic = widget.topic;
    final chapters = controller.chaptersForTopic(topic.id);
    final activeCount = controller.countTopicSeeds(topic.id);
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header row ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TopicLabel(
                        topic: topic,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text('$activeCount aktive Vokabeln',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(Icons.library_books_outlined, color: cs.primary),
              ],
            ),
            const SizedBox(height: 10),

            // ── Full-topic mode chips ────────────────────────────────
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _ModeChip(
                  label: 'Normal',
                  onPressed: () => widget.onStart(
                    LearningModeType.normal,
                    controller.getNormalModeSeeds(topicId: topic.id),
                    '${topic.label} · Normal',
                  ),
                ),
                _ModeChip(
                  label: 'Umgekehrt',
                  onPressed: () => widget.onStart(
                    LearningModeType.reverse,
                    controller.getNormalModeSeeds(topicId: topic.id),
                    '${topic.label} · Umgekehrt',
                  ),
                ),
                _ModeChip(
                  label: 'Prioritäten',
                  onPressed: () => widget.onStart(
                    LearningModeType.priorities,
                    controller.getPrioritiesModeSeeds(topicId: topic.id),
                    '${topic.label} · Prioritäten',
                  ),
                ),
                _ModeChip(
                  label: 'Unsicher',
                  onPressed: () => widget.onStart(
                    LearningModeType.reviewUnknown,
                    controller.getReviewUnknownModeSeeds(
                        topicId: topic.id),
                    '${topic.label} · Unsicher',
                  ),
                ),
              ],
            ),

            // ── Chapter toggle ───────────────────────────────────────
            if (chapters.length > 1) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  children: [
                    Text(
                      'Chapter (${chapters.length})',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: cs.primary),
                    ),
                    Icon(
                      _expanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 18,
                      color: cs.primary,
                    ),
                  ],
                ),
              ),
              if (_expanded) ...[
                const SizedBox(height: 8),
                ...chapters.map((ch) {
                  final done = controller.isChapterComplete(ch);
                  final active = controller.chapterActiveSeeds(ch);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _ChapterRow(
                      chapter: ch,
                      isComplete: done,
                      activeCount: active.length,
                      onStart: (mode) => widget.onStart(
                        mode,
                        active,
                        '${ch.displayName} · ${_modeLabel(mode)}',
                      ),
                    ),
                  );
                }),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _modeLabel(LearningModeType m) => switch (m) {
        LearningModeType.normal => 'Normal',
        LearningModeType.reverse => 'Umgekehrt',
        LearningModeType.priorities => 'Prioritäten',
        LearningModeType.reviewUnknown => 'Unsicher',
      };
}

class _ChapterRow extends StatelessWidget {
  final VocabChapter chapter;
  final bool isComplete;
  final int activeCount;
  final void Function(LearningModeType) onStart;

  const _ChapterRow({
    required this.chapter,
    required this.isComplete,
    required this.activeCount,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isComplete
            ? cs.primaryContainer.withAlpha(120)
            : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (isComplete)
            Icon(Icons.check_circle_outline, size: 16, color: cs.primary)
          else
            Icon(Icons.radio_button_unchecked,
                size: 16, color: cs.outlineVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chapter.displayName,
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  isComplete
                      ? 'Abgeschlossen'
                      : '$activeCount aktive Vokabeln',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (!isComplete)
            Wrap(
              spacing: 4,
              children: [
                _SmallChip(
                  label: 'EN→ES',
                  onPressed: () => onStart(LearningModeType.normal),
                ),
                _SmallChip(
                  label: 'ES→EN',
                  onPressed: () => onStart(LearningModeType.reverse),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SmallChip({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label,
          style: Theme.of(context).textTheme.labelSmall),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _ModeChip({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.play_arrow, size: 16),
      onPressed: onPressed,
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final String countText;
  final VoidCallback onPressed;

  const _ModeButton({
    required this.title,
    required this.subtitle,
    required this.countText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(countText,
                style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 6),
            const Icon(Icons.play_arrow_outlined),
          ],
        ),
        onTap: onPressed,
      ),
    );
  }
}

class _EmptyTopicsHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Keine Themen ausgewählt.'),
          const SizedBox(height: 6),
          Text(
            'Öffne die Bibliothek und wähle mindestens einen Themenbereich, damit Lernmodi funktionieren.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
