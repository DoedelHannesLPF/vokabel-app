import 'vocab.dart';

/// A vocab entry created by the user.
/// Stored separately from the seed data and merged at runtime.
class CustomVocab {
  final String id; // unique, e.g. "custom_<timestamp>"
  final String wordEs;
  final String wordEn;
  /// Either a selected topic id, or [kNoCollectionId] for uncategorized.
  final String collectionId;

  static const String kNoCollectionId = 'custom_uncategorized';
  static const String kCustomTopicId = 'custom_own';

  const CustomVocab({
    required this.id,
    required this.wordEs,
    required this.wordEn,
    required this.collectionId,
  });

  /// Expose as a [VocabSeed] so it works with all existing session logic.
  VocabSeed toSeed() => VocabSeed(
        id: id,
        topicId: kCustomTopicId,
        wordEn: wordEn,
        wordEs: wordEs,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'wordEs': wordEs,
        'wordEn': wordEn,
        'collectionId': collectionId,
      };

  factory CustomVocab.fromJson(Map<String, dynamic> json) => CustomVocab(
        id: (json['id'] as String?) ?? '',
        wordEs: (json['wordEs'] as String?) ?? '',
        wordEn: (json['wordEn'] as String?) ?? '',
        collectionId:
            (json['collectionId'] as String?) ?? kNoCollectionId,
      );
}
