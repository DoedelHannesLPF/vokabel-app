class VocabSeed {
  final String id;
  final String topicId;
  final String wordEn;
  final String wordEs;

  const VocabSeed({
    required this.id,
    required this.topicId,
    required this.wordEn,
    required this.wordEs,
  });
}

class VocabProgress {
  final int seenCount;
  final bool prioritized;
  final bool known;
  final bool removed;

  const VocabProgress({
    required this.seenCount,
    required this.prioritized,
    required this.known,
    required this.removed,
  });

  factory VocabProgress.initial() => const VocabProgress(
        seenCount: 0,
        prioritized: false,
        known: false,
        removed: false,
      );

  VocabProgress copyWith({
    int? seenCount,
    bool? prioritized,
    bool? known,
    bool? removed,
  }) {
    return VocabProgress(
      seenCount: seenCount ?? this.seenCount,
      prioritized: prioritized ?? this.prioritized,
      known: known ?? this.known,
      removed: removed ?? this.removed,
    );
  }

  Map<String, dynamic> toJson() => {
        'seenCount': seenCount,
        'prioritized': prioritized,
        'known': known,
        'removed': removed,
      };

  factory VocabProgress.fromJson(Map<String, dynamic> json) => VocabProgress(
        seenCount: (json['seenCount'] as num?)?.toInt() ?? 0,
        prioritized: (json['prioritized'] as bool?) ?? false,
        known: (json['known'] as bool?) ?? false,
        removed: (json['removed'] as bool?) ?? false,
      );
}

