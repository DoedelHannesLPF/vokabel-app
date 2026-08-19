import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_controller.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final profile = controller.profile;
    final cs = Theme.of(context).colorScheme;
    if (profile == null) {
      return const Center(child: Text('Kein Account geladen.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text(
            'Account & Einstellungen',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text('Angemeldet als:', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            profile.username,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Geschwindigkeit',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Aktuell: ${profile.speedMs} ms',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Slider(
                  value: profile.speedMs.toDouble(),
                  min: 400,
                  max: 2000,
                  divisions: 16,
                  label: '${profile.speedMs} ms',
                  onChanged: (v) async {
                    final rounded = v.round().clamp(400, 2000);
                    await controller.setSpeedMs(rounded);
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  'Review-Schwelle:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Vokabeln gelten als „unsicher“ ab ${profile.reviewSeenThreshold} Sichtungen (wenn nicht als gelernt markiert).',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistiken (aktive Themen)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Text('Aktive Vokabeln: ${controller.countSelectedSeeds()}'),
                Text('Priorisiert: ${controller.countPrioritizedSelected()}'),
                Text('Gelernt: ${controller.countKnownSelected()}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gelernte Vokabeln',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Hake eine Vokabel ab, um sie wieder in Sessions zu trainieren.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                ..._buildKnownVocabList(context, controller),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Lernfortschritt zurücksetzen?'),
                  content: const Text(
                    'Dadurch werden Sichtungen/Markierungen für alle Vokabeln dieses Accounts gelöscht.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Abbrechen'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Zurücksetzen'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await controller.resetProgress();
              }
            },
            child: const Text('Lernfortschritt zurücksetzen'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              await controller.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildKnownVocabList(BuildContext context, AppController controller) {
    final cs = Theme.of(context).colorScheme;
    final known = controller.getKnownVocabs();
    if (known.isEmpty) {
      return [
        Text(
          'Noch keine Vokabeln als gelernt markiert.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      ];
    }

    return known.map((seed) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('${seed.wordEn} → ${seed.wordEs}'),
        subtitle: Text(controller.topicLabel(seed.topicId)),
        trailing: IconButton(
          icon: const Icon(Icons.replay),
          tooltip: 'Wieder lernen',
          onPressed: () => controller.setKnown(seed.id, false),
        ),
      );
    }).toList();
  }
}

