import 'package:flutter/material.dart';

class VocabCard extends StatelessWidget {
  final String frontText;
  final String backText;
  final bool showTranslation;
  final bool paused;

  const VocabCard({
    super.key,
    required this.frontText,
    required this.backText,
    required this.showTranslation,
    required this.paused,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(18),
          color: paused
              ? cs.surfaceContainerHighest.withAlpha(180)
              : cs.surfaceContainerHighest,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (paused)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pause_circle_outline,
                            size: 18, color: cs.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(
                          'Pausiert',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                Text(
                  showTranslation ? backText : frontText,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: showTranslation ? cs.primary : null,
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
