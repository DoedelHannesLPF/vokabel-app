import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/seed_vocab.dart';
import '../models/user_folder.dart';
import '../models/vocab.dart';
import '../state/app_controller.dart';
import 'add_vocab_screen.dart';
import 'widgets/topic_label.dart';

Future<String?> _promptName(
    BuildContext context, String title, String hint) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _NameDialog(title: title, hint: hint),
  );
}

class _NameDialog extends StatefulWidget {
  final String title;
  final String hint;

  const _NameDialog({required this.title, required this.hint});

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.hint,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Abbrechen')),
        FilledButton(
            onPressed: () => Navigator.of(context).pop(_ctrl.text.trim()),
            child: const Text('Erstellen')),
      ],
    );
  }
}

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab>
    with SingleTickerProviderStateMixin {
  bool _onlyActive = false;
  bool _fabOpen = false;

  void _toggleFab() => setState(() => _fabOpen = !_fabOpen);
  void _closeFab() { if (_fabOpen) setState(() => _fabOpen = false); }

  Future<void> _createFolder() async {
    _closeFab();
    final controller = context.read<AppController>();
    final name = await _promptName(context, 'Neuer Ordner', 'Ordnername');
    if (name != null && name.isNotEmpty) {
      await controller.createFolder(name);
    }
  }

  void _openAddVocab() {
    _closeFab();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddVocabScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final selected = controller.selectedTopicIds.toSet();
    final folders = controller.folders;

    final visibleTopics = _onlyActive
        ? controller.topics.where((t) => selected.contains(t.id)).toList()
        : controller.topics;

    return Scaffold(
      floatingActionButton: _SpeedDial(
        open: _fabOpen,
        onToggle: _toggleFab,
        onCreateFolder: _createFolder,
        onAddVocab: _openAddVocab,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
            Text('Bibliothek',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              'Wähle Themenbereiche aus. Klappe ein Thema auf, um seine Chapter zu sehen.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),

            // ── Filter bar ────────────────────────────────────────────
            Row(
              children: [
                FilterChip(
                  label: const Text('Nur aktivierte'),
                  selected: _onlyActive,
                  onSelected: (v) => setState(() => _onlyActive = v),
                  avatar: _onlyActive
                      ? null
                      : const Icon(Icons.filter_list, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── User folders ──────────────────────────────────────────
            if (folders.isNotEmpty) ...[
              Text('Ordner',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...folders.map((f) => _FolderTile(
                    folder: f,
                    controller: controller,
                    allTopics: controller.topics,
                    selected: selected,
                  )),
              const SizedBox(height: 16),
              Text('Alle Themenbereiche',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
            ],

            // ── Topics list ───────────────────────────────────────────
            if (visibleTopics.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Keine aktiven Themen.\nAktiviere Themenbereiche über die Checkbox.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ...visibleTopics.map((t) {
                final isSelected = selected.contains(t.id);
                return _TopicTile(
                  topic: t,
                  isSelected: isSelected,
                  controller: controller,
                  onToggleSelected: (v) async {
                    final newSelected = List<String>.from(selected);
                    if (v == true) {
                      newSelected.add(t.id);
                    } else {
                      newSelected.remove(t.id);
                    }
                    await controller.setSelectedTopics(newSelected);
                  },
                );
              }),
            const SizedBox(height: 14),
            _StatsCard(controller: controller),
          ],
        ),
          if (_fabOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeFab,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.black.withValues(alpha: 0.35)),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Speed-dial FAB ──────────────────────────────────────────────────────────

class _SpeedDial extends StatelessWidget {
  final bool open;
  final VoidCallback onToggle;
  final VoidCallback onCreateFolder;
  final VoidCallback onAddVocab;

  const _SpeedDial({
    required this.open,
    required this.onToggle,
    required this.onCreateFolder,
    required this.onAddVocab,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (open) ...[
          _MiniAction(
            icon: Icons.create_new_folder_outlined,
            label: 'Ordner erstellen',
            onTap: onCreateFolder,
          ),
          const SizedBox(height: 10),
          _MiniAction(
            icon: Icons.text_fields_outlined,
            label: 'Vokabel hinzufügen',
            onTap: onAddVocab,
          ),
          const SizedBox(height: 14),
        ],
        FloatingActionButton.extended(
          heroTag: 'library_fab',
          icon: AnimatedRotation(
            turns: open ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
          label: const Text('Erstellen'),
          onPressed: onToggle,
        ),
      ],
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MiniAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(label,
                style: Theme.of(context).textTheme.labelMedium),
          ),
        ),
        const SizedBox(width: 10),
        FloatingActionButton.small(
          heroTag: label,
          onPressed: onTap,
          child: Icon(icon),
        ),
      ],
    );
  }
}

// ─── Folder tile ──────────────────────────────────────────────────────────────

class _FolderTile extends StatelessWidget {
  final UserFolder folder;
  final AppController controller;
  final List<TopicDef> allTopics;
  final Set<String> selected;

  const _FolderTile({
    required this.folder,
    required this.controller,
    required this.allTopics,
    required this.selected,
  });

  Future<void> _addTopic(BuildContext context) async {
    // Topics not yet in this folder
    final available = allTopics
        .where((t) => !folder.topicIds.contains(t.id))
        .toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine weiteren Themenbereiche verfügbar.')),
      );
      return;
    }

    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Themenbereich hinzufügen'),
        children: available
            .map((t) => SimpleDialogOption(
                  onPressed: () => Navigator.of(ctx).pop(t.id),
                  child: TopicLabel(topic: t),
                ))
            .toList(),
      ),
    );
    if (chosen != null) {
      await controller.addTopicToFolder(folder.id, chosen);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('„${folder.name}" löschen?'),
        content: const Text('Der Ordner wird gelöscht. Die Themenbereiche bleiben erhalten.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Löschen')),
        ],
      ),
    );
    if (ok == true) await controller.deleteFolder(folder.id);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final assignedTopics = allTopics
        .where((t) => folder.topicIds.contains(t.id))
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.folder_outlined),
        title: Text(folder.name),
        subtitle: Text('${assignedTopics.length} Themenbereiche'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add topic button
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: cs.primary),
              tooltip: 'Themenbereich hinzufügen',
              onPressed: () => _addTopic(context),
            ),
            // Delete folder
            IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error),
              tooltip: 'Ordner löschen',
              onPressed: () => _confirmDelete(context),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          if (assignedTopics.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Noch keine Themenbereiche. Tippe auf + um einen hinzuzufügen.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            )
          else
            ...assignedTopics.map((t) {
              final isSelected = selected.contains(t.id);
              return Column(
                children: [
                  _TopicTile(
                    topic: t,
                    isSelected: isSelected,
                    controller: controller,
                    onToggleSelected: (v) async {
                      final newSelected =
                          List<String>.from(selected);
                      if (v == true) {
                        newSelected.add(t.id);
                      } else {
                        newSelected.remove(t.id);
                      }
                      await controller.setSelectedTopics(newSelected);
                    },
                    trailingExtra: IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          size: 18),
                      tooltip: 'Aus Ordner entfernen',
                      onPressed: () => controller
                          .removeTopicFromFolder(folder.id, t.id),
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

// ─── Topic tile with chapter expansion ──────────────────────────────────────

class _TopicTile extends StatelessWidget {
  final TopicDef topic;
  final bool isSelected;
  final AppController controller;
  final ValueChanged<bool?> onToggleSelected;
  /// Optional extra widget shown at the end of the tile header (e.g. remove button).
  final Widget? trailingExtra;

  const _TopicTile({
    required this.topic,
    required this.isSelected,
    required this.controller,
    required this.onToggleSelected,
    this.trailingExtra,
  });

  @override
  Widget build(BuildContext context) {
    final chapters = controller.chaptersForTopic(topic.id);
    final totalSeeds =
        chapters.fold<int>(0, (s, c) => s + c.seeds.length);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: onToggleSelected,
        ),
        title: TopicLabel(topic: topic),
        subtitle: Text('$totalSeeds Vokabeln · ${chapters.length} Chapter'),
        // Show remove-from-folder button before the expand arrow when provided.
        trailing: trailingExtra != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  trailingExtra!,
                  const Icon(Icons.expand_more),
                ],
              )
            : null,
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        children: chapters
            .map((ch) => _ChapterExpansionTile(
                  chapter: ch,
                  controller: controller,
                ))
            .toList(),
      ),
    );
  }
}

// ─── Chapter tile with vocab list ───────────────────────────────────────────

class _ChapterExpansionTile extends StatelessWidget {
  final VocabChapter chapter;
  final AppController controller;

  const _ChapterExpansionTile({
    required this.chapter,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDone = controller.isChapterComplete(chapter);
    final knownCount =
        chapter.seeds.where((s) => controller.progress[s.id]?.known == true).length;

    return ExpansionTile(
      leading: isDone
          ? Icon(Icons.check_circle_outline, color: cs.primary)
          : Icon(Icons.radio_button_unchecked, color: cs.outlineVariant),
      title: Text(chapter.displayName),
      subtitle: Text('$knownCount / ${chapter.seeds.length} gelernt'),
      childrenPadding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      children: chapter.seeds
          .map((seed) => _VocabRow(seed: seed, controller: controller))
          .toList(),
    );
  }
}

// ─── Single vocab row ────────────────────────────────────────────────────────

class _VocabRow extends StatelessWidget {
  final VocabSeed seed;
  final AppController controller;

  const _VocabRow({required this.seed, required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = controller.progress[seed.id];
    if (p == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${seed.wordEn}  →  ${seed.wordEs}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: p.known ? cs.primary : null,
                  ),
            ),
          ),
          _IconToggle(
            icon: Icons.star_outline,
            activeColor: cs.primary,
            active: p.prioritized,
            tooltip: p.prioritized ? 'Priorisiert' : 'Priorisieren',
            onTap: () => controller.togglePriority(seed.id, !p.prioritized),
          ),
          _IconToggle(
            icon: Icons.check_circle_outline,
            activeColor: cs.primary,
            active: p.known,
            tooltip: p.known ? 'Gelernt' : 'Als gelernt markieren',
            onTap: () => controller.setKnown(seed.id, !p.known),
          ),
        ],
      ),
    );
  }
}

class _IconToggle extends StatelessWidget {
  final IconData icon;
  final Color activeColor;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  const _IconToggle({
    required this.icon,
    required this.activeColor,
    required this.active,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(icon, color: active ? activeColor : cs.outlineVariant),
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}

// ─── Stats card ──────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final AppController controller;

  const _StatsCard({required this.controller});

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
          Text('Auswahl-Status',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Aktive Vokabeln: ${controller.countSelectedSeeds()}'),
          Text('Priorisiert: ${controller.countPrioritizedSelected()}'),
          Text('Gelernt: ${controller.countKnownSelected()}'),
        ],
      ),
    );
  }
}
