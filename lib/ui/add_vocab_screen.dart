import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/custom_vocab.dart';
import '../state/app_controller.dart';

class AddVocabScreen extends StatefulWidget {
  const AddVocabScreen({super.key});

  @override
  State<AddVocabScreen> createState() => _AddVocabScreenState();
}

class _AddVocabScreenState extends State<AddVocabScreen> {
  final _searchCtrl = TextEditingController();
  List<({String topicLabel, String wordEn, String wordEs})> _searchResults = [];
  bool _searched = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search() {
    final controller = context.read<AppController>();
    final raw = controller.searchBySpanish(_searchCtrl.text);
    setState(() {
      _searched = true;
      _searchResults = raw
          .map((r) => (
                topicLabel: r.topicLabel,
                wordEn: r.seed.wordEn,
                wordEs: r.seed.wordEs,
              ))
          .toList();
    });
  }

  Future<void> _openAddDialog(String prefillEs) async {
    final controller = context.read<AppController>();
    await showDialog<void>(
      context: context,
      builder: (ctx) => _AddVocabDialog(
        prefillEs: prefillEs,
        controller: controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Vokabel hinzufügen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Spanische Vokabel eingeben und prüfen ob sie schon vorhanden ist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      labelText: 'Spanisch (z.B. "hablar")',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _search,
                  child: const Text('Prüfen'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_searched) ...[
              if (_searchResults.isNotEmpty) ...[
                Text(
                  'Bereits vorhanden in:',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: cs.primary),
                ),
                const SizedBox(height: 8),
                ..._searchResults.map(
                  (r) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text('${r.wordEs}  →  ${r.wordEn}'),
                    subtitle: Text(r.topicLabel),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Trotzdem als eigene Vokabel hinzufügen'),
                  onPressed: () =>
                      _openAddDialog(_searchCtrl.text.trim()),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: cs.onPrimaryContainer),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Nicht gefunden. Du kannst sie als eigene Vokabel hinzufügen.',
                          style: TextStyle(color: cs.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Hinzufügen'),
                  onPressed: () =>
                      _openAddDialog(_searchCtrl.text.trim()),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Add vocab dialog ─────────────────────────────────────────────────────────

class _AddVocabDialog extends StatefulWidget {
  final String prefillEs;
  final AppController controller;

  const _AddVocabDialog({
    required this.prefillEs,
    required this.controller,
  });

  @override
  State<_AddVocabDialog> createState() => _AddVocabDialogState();
}

class _AddVocabDialogState extends State<_AddVocabDialog> {
  late final TextEditingController _esCtrl;
  final TextEditingController _enCtrl = TextEditingController();
  String _collectionId = CustomVocab.kNoCollectionId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _esCtrl = TextEditingController(text: widget.prefillEs);
  }

  @override
  void dispose() {
    _esCtrl.dispose();
    _enCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final es = _esCtrl.text.trim();
    final en = _enCtrl.text.trim();
    if (es.isEmpty || en.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte beide Felder ausfüllen.')),
      );
      return;
    }
    setState(() => _saving = true);

    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final vocab = CustomVocab(
      id: id,
      wordEs: es,
      wordEn: en,
      collectionId: _collectionId,
    );
    await widget.controller.addCustomVocab(vocab);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final collections = widget.controller.availableCollections;

    return AlertDialog(
      title: const Text('Eigene Vokabel'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _esCtrl,
              decoration: const InputDecoration(
                labelText: 'Spanisch',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _enCtrl,
              decoration: const InputDecoration(
                labelText: 'Englisch (Übersetzung)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Sammlung',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _collectionId,
                  isExpanded: true,
                  items: collections
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.label,
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _collectionId = v);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Speichern'),
        ),
      ],
    );
  }
}
