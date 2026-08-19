import 'package:flutter/material.dart';

import '../../data/seed_vocab.dart';

class TopicLabel extends StatelessWidget {
  final TopicDef topic;
  final TextStyle? style;
  final double iconSize;

  const TopicLabel({
    super.key,
    required this.topic,
    this.style,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textStyle = style ?? Theme.of(context).textTheme.titleMedium;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(topic.icon, size: iconSize, color: cs.primary),
        const SizedBox(width: 10),
        Flexible(child: Text(topic.label, style: textStyle)),
      ],
    );
  }
}
