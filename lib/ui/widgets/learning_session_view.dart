import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/vocab.dart';
import '../../state/app_controller.dart';
import '../widgets/vocab_card.dart';

class LearningSessionView extends StatefulWidget {
  final LearningModeType mode;
  final List<VocabSeed> seeds;
  final String title;

  const LearningSessionView({
    super.key,
    required this.mode,
    required this.seeds,
    required this.title,
  });

  @override
  State<LearningSessionView> createState() => _LearningSessionViewState();
}

class _LearningSessionViewState extends State<LearningSessionView> {
  Timer? _timer;
  late final List<VocabSeed> _shuffled;
  int _index = 0;
  bool _showTranslation = false;
  bool _seenIncrementedForCurrentVocab = false;
  bool _paused = false;
  bool _holdPaused = false; // long-press hold pause (no options sheet)
  bool _sessionComplete = false;

  /// Every vocab shown so far (for the history list, may contain duplicates if
  /// the user navigates back).
  final List<VocabSeed> _history = [];

  @override
  void initState() {
    super.initState();
    _shuffled = List<VocabSeed>.from(widget.seeds)..shuffle(Random());
    if (_shuffled.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<AppController>();
      controller.recordLearningDay(DateTime.now());
      _scheduleNextPhase(controller, immediately: false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _reverseDisplay => widget.mode == LearningModeType.reverse;

  void _scheduleNextPhase(AppController controller,
      {required bool immediately}) {
    _timer?.cancel();
    if (_shuffled.isEmpty) return;
    final speedMs = controller.profile?.speedMs ?? 900;

    if (immediately) {
      scheduleMicrotask(() {
        if (!mounted || _paused) return;
        _advancePhase(controller);
      });
      return;
    }

    _timer = Timer(Duration(milliseconds: speedMs), () {
      if (!mounted || _paused) return;
      _advancePhase(controller);
    });
  }

  void _advancePhase(AppController controller) {
    if (_shuffled.isEmpty) return;

    if (!_showTranslation) {
      // Show translation
      setState(() {
        _showTranslation = true;
        _seenIncrementedForCurrentVocab = false;
      });
      final seed = _shuffled[_index];
      if (!_seenIncrementedForCurrentVocab) {
        _seenIncrementedForCurrentVocab = true;
        controller.incrementSeen(seed.id);
      }
      _scheduleNextPhase(controller, immediately: false);
      return;
    }

    // Advance to next vocab
    setState(() {
      _showTranslation = false;
      _seenIncrementedForCurrentVocab = false;
    });
    _history.add(_shuffled[_index]);
    _index++;
    if (_index >= _shuffled.length) {
      _timer?.cancel();
      setState(() => _sessionComplete = true);
      return;
    }
    _scheduleNextPhase(controller, immediately: false);
  }

  /// Single tap: pause and open options sheet.
  Future<void> _openOptions(AppController controller) async {
    _holdPaused = false;
    _paused = true;
    _timer?.cancel();

    final seed = _shuffled[_index];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _VocabOptionsSheet(
        seed: seed,
        history: List.unmodifiable(_history),
        onJumpTo: (targetSeed) {
          Navigator.of(ctx).pop();
          _jumpTo(targetSeed);
        },
      ),
    );

    if (!mounted) return;
    _paused = false;
    _scheduleNextPhase(controller, immediately: false);
  }

  /// Jump back to a previously seen vocab (from options history dropdown).
  void _jumpTo(VocabSeed target) {
    final idx = _shuffled.indexOf(target);
    if (idx < 0) return;
    setState(() {
      _index = idx;
      _showTranslation = false;
      _seenIncrementedForCurrentVocab = false;
    });
    final controller = context.read<AppController>();
    _scheduleNextPhase(controller, immediately: false);
  }

  /// Double-tap: go back one vocab.
  void _goBack() {
    if (_index <= 0) return;
    final controller = context.read<AppController>();
    setState(() {
      _index--;
      _showTranslation = false;
      _seenIncrementedForCurrentVocab = false;
    });
    _scheduleNextPhase(controller, immediately: false);
  }

  /// Long-press start: pause without opening options.
  void _onHoldStart() {
    _timer?.cancel();
    setState(() {
      _paused = true;
      _holdPaused = true;
    });
  }

  /// Long-press end: resume.
  void _onHoldEnd() {
    if (!_holdPaused) return;
    setState(() {
      _holdPaused = false;
      _paused = false;
    });
    final controller = context.read<AppController>();
    _scheduleNextPhase(controller, immediately: false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();

    if (_shuffled.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('Keine Vokabeln verfügbar.')),
      );
    }

    if (_sessionComplete || _index >= _shuffled.length) {
      return _SessionEndScreen(
        title: widget.title,
        seeds: widget.seeds,
        mode: widget.mode,
      );
    }

    final seed = _shuffled[_index];
    final wordFront = _reverseDisplay ? seed.wordEs : seed.wordEn;
    final wordBack = _reverseDisplay ? seed.wordEn : seed.wordEs;

    // Progress indicator
    final progress = (_index + (_showTranslation ? 0.5 : 0)) / _shuffled.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: progress),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _timer?.cancel();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close),
          )
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openOptions(controller),
        onDoubleTap: _goBack,
        onLongPressStart: (_) => _onHoldStart(),
        onLongPressEnd: (_) => _onHoldEnd(),
        child: SafeArea(
          child: Center(
            child: VocabCard(
              frontText: wordFront,
              backText: wordBack,
              showTranslation: _showTranslation,
              paused: _holdPaused,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Options bottom sheet ────────────────────────────────────────────────────

class _VocabOptionsSheet extends StatelessWidget {
  final VocabSeed seed;
  final List<VocabSeed> history;
  final void Function(VocabSeed) onJumpTo;

  const _VocabOptionsSheet({
    required this.seed,
    required this.history,
    required this.onJumpTo,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final p = controller.progress[seed.id];
    if (p == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Optionen', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            '${seed.wordEn}  ↔  ${seed.wordEs}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: p.prioritized,
            onChanged: (v) => controller.togglePriority(seed.id, v),
            title: const Text('Priorisieren'),
          ),
          SwitchListTile(
            value: p.known,
            onChanged: (v) => controller.setKnown(seed.id, v),
            title: const Text('Gelernt'),
          ),
          if (history.isNotEmpty) ...[
            const Divider(height: 24),
            Text('Zurück zu einer früheren Vokabel',
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            _HistoryDropdown(history: history, onJumpTo: onJumpTo),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Weiter'),
          ),
        ],
      ),
    );
  }
}

class _HistoryDropdown extends StatefulWidget {
  final List<VocabSeed> history;
  final void Function(VocabSeed) onJumpTo;

  const _HistoryDropdown({required this.history, required this.onJumpTo});

  @override
  State<_HistoryDropdown> createState() => _HistoryDropdownState();
}

class _HistoryDropdownState extends State<_HistoryDropdown> {
  VocabSeed? _selected;

  @override
  Widget build(BuildContext context) {
    // Most recent first, deduplicated by id
    final seen = <String>{};
    final unique = widget.history.reversed
        .where((s) => seen.add(s.id))
        .toList();

    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<VocabSeed>(
                value: _selected,
                hint: const Text('Vokabel wählen…'),
                isExpanded: true,
                items: unique
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            '${s.wordEn} → ${s.wordEs}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selected = v),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          icon: const Icon(Icons.replay),
          tooltip: 'Zu dieser Vokabel springen',
          onPressed: _selected == null
              ? null
              : () => widget.onJumpTo(_selected!),
        ),
      ],
    );
  }
}

// ─── Session end screen ───────────────────────────────────────────────────────

class _SessionEndScreen extends StatelessWidget {
  final String title;
  final List<VocabSeed> seeds;
  final LearningModeType mode;

  const _SessionEndScreen({
    required this.title,
    required this.seeds,
    required this.mode,
  });

  void _restart(BuildContext context, {required bool shuffle}) {
    final next = shuffle
        ? (List<VocabSeed>.from(seeds)..shuffle(Random()))
        : List<VocabSeed>.from(seeds);

    // Replace this route with a fresh session.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LearningSessionView(
          mode: mode,
          seeds: next,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 72, color: cs.primary),
                const SizedBox(height: 16),
                Text(
                  'Session abgeschlossen!',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${seeds.length} Vokabeln durchgegangen.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.replay),
                    label: const Text('Wiederholen (gleiche Reihenfolge)'),
                    onPressed: () =>
                        _restart(context, shuffle: false),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Durchgemischt wiederholen'),
                    onPressed: () =>
                        _restart(context, shuffle: true),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Zurück zur Startseite'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
