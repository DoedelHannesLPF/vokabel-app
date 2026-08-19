import 'package:flutter/material.dart';

import '../data/app_storage.dart';
import '../data/seed_vocab.dart';
import '../models/custom_vocab.dart';
import '../models/user_folder.dart';
import '../models/user_profile.dart';
import '../models/vocab.dart';

enum LearningModeType {
  normal,
  reverse,
  priorities,
  reviewUnknown,
}

/// A deterministic sub-group of 30 vocab items within one topic.
class VocabChapter {
  final String topicId;
  final String topicLabel;
  final int index; // 0-based
  final List<VocabSeed> seeds;

  const VocabChapter({
    required this.topicId,
    required this.topicLabel,
    required this.index,
    required this.seeds,
  });

  /// Roman numeral label, e.g. "I", "II", "III", …
  String get romanIndex => _toRoman(index + 1);

  String get displayName => '$topicLabel $romanIndex';

  static const _romans = [
    (1000, 'M'), (900, 'CM'), (500, 'D'), (400, 'CD'),
    (100, 'C'), (90, 'XC'), (50, 'L'), (40, 'XL'),
    (10, 'X'), (9, 'IX'), (5, 'V'), (4, 'IV'), (1, 'I'),
  ];

  static String _toRoman(int n) {
    final buf = StringBuffer();
    for (final (val, sym) in _romans) {
      while (n >= val) {
        buf.write(sym);
        n -= val;
      }
    }
    return buf.toString();
  }
}

class AppController extends ChangeNotifier {
  final AppStorage storage;

  UserProfile? _profile;
  Map<String, VocabProgress> _progress = {};
  List<String> _learningDatesIso = [];
  List<CustomVocab> _customVocabs = [];
  List<UserFolder> _folders = [];

  bool _loading = false;
  bool get loading => _loading;

  UserProfile? get profile => _profile;
  Map<String, VocabProgress> get progress => _progress;
  List<String> get learningDatesIso => _learningDatesIso;

  String? get username => _profile?.username;
  List<CustomVocab> get customVocabs => _customVocabs;
  List<UserFolder> get folders => _folders;

  AppController({required this.storage});

  Future<void> loadForUser(String username) async {
    _loading = true;
    notifyListeners();

    await storage.ensureUserExists(username);
    _profile = await storage.getUser(username);
    _progress = await storage.getProgress(username);
    _learningDatesIso = await storage.getLearningDatesIso(username);
    _customVocabs = await storage.getCustomVocabs(username);
    _folders = await storage.getFolders(username);

    // Ensure every seed vocab has a progress record.
    for (final seed in kVocabSeeds) {
      _progress.putIfAbsent(seed.id, () => VocabProgress.initial());
    }
    // Same for custom vocabs.
    for (final cv in _customVocabs) {
      _progress.putIfAbsent(cv.id, () => VocabProgress.initial());
    }

    _loading = false;
    notifyListeners();
  }

  List<String> get selectedTopicIds => _profile?.selectedTopicIds ?? const [];

  List<TopicDef> get topics => [
        ...storage.topics,
        const TopicDef(
          id: CustomVocab.kCustomTopicId,
          label: 'Eigene Vokabeln',
          icon: Icons.edit_outlined,
        ),
      ];

  List<TopicDef> get selectedTopics {
    final selected = selectedTopicIds.toSet();
    final result = topics.where((t) => selected.contains(t.id)).toList();
    // Append virtual "Eigene Vokabeln" topic if selected and non-empty.
    if (selected.contains(CustomVocab.kCustomTopicId) &&
        _customVocabs.isNotEmpty) {
      result.add(const TopicDef(
        id: CustomVocab.kCustomTopicId,
        label: 'Eigene Vokabeln',
        icon: Icons.edit_outlined,
      ));
    }
    return result;
  }

  List<VocabSeed> _filteredSeeds({String? topicId}) {
    final profile = _profile;
    if (profile == null) return const [];

    final selected = profile.selectedTopicIds.toSet();
    final hasCustomSelected = selected.contains(CustomVocab.kCustomTopicId);

    final result = <VocabSeed>[];

    // Built-in seeds
    if (topicId == null || topicId != CustomVocab.kCustomTopicId) {
      result.addAll(kVocabSeeds.where((v) {
        if (!selected.contains(v.topicId)) return false;
        if (topicId != null && v.topicId != topicId) return false;
        return true;
      }));
    }

    // Custom seeds
    if (topicId == null && hasCustomSelected ||
        topicId == CustomVocab.kCustomTopicId) {
      result.addAll(_customVocabs.map((c) => c.toSeed()));
    }

    return result;
  }

  List<VocabSeed> getKnownVocabs() {
    return kVocabSeeds.where((v) {
      final p = _progress[v.id];
      return p != null && p.known && !p.removed;
    }).toList()
      ..sort((a, b) {
        final topicCompare = a.topicId.compareTo(b.topicId);
        if (topicCompare != 0) return topicCompare;
        return a.wordEn.compareTo(b.wordEn);
      });
  }

  String topicLabel(String topicId) {
    if (topicId == CustomVocab.kCustomTopicId) return 'Eigene Vokabeln';
    for (final t in topics) {
      if (t.id == topicId) return t.label;
    }
    return topicId;
  }

  List<VocabSeed> getNormalModeSeeds({String? topicId}) {
    final seeds = _filteredSeeds(topicId: topicId);
    final list = seeds.where((v) {
      final p = _progress[v.id]!;
      return !p.removed && !p.known;
    }).toList();
    list.sort((a, b) {
      final ap = _progress[a.id]!;
      final bp = _progress[b.id]!;
      if (ap.prioritized != bp.prioritized) {
        return ap.prioritized ? -1 : 1;
      }
      return bp.seenCount.compareTo(ap.seenCount);
    });
    return list;
  }

  List<VocabSeed> getPrioritiesModeSeeds({String? topicId}) {
    final seeds = _filteredSeeds(topicId: topicId);
    return seeds
        .where((v) {
          final p = _progress[v.id]!;
          return !p.removed && !p.known && p.prioritized;
        })
        .toList()
      ..sort((a, b) {
        final ap = _progress[a.id]!;
        final bp = _progress[b.id]!;
        return bp.seenCount.compareTo(ap.seenCount);
      });
  }

  List<VocabSeed> getReviewUnknownModeSeeds({String? topicId}) {
    final profile = _profile;
    if (profile == null) return const [];

    final seeds = _filteredSeeds(topicId: topicId);
    final threshold = profile.reviewSeenThreshold;

    final list = seeds.where((v) {
      final p = _progress[v.id]!;
      return !p.removed && !p.known && p.seenCount >= threshold;
    }).toList();

    list.sort((a, b) {
      final ap = _progress[a.id]!;
      final bp = _progress[b.id]!;
      return bp.seenCount.compareTo(ap.seenCount);
    });
    return list;
  }

  /// All seeds for a given topic (regardless of progress state).
  List<VocabSeed> allSeedsForTopic(String topicId) {
    if (topicId == CustomVocab.kCustomTopicId) {
      return _customVocabs.map((c) => c.toSeed()).toList();
    }
    return kVocabSeeds.where((v) => v.topicId == topicId).toList();
  }

  /// All vocab seeds including user-created ones.
  List<VocabSeed> get allSeeds =>
      [...kVocabSeeds, ..._customVocabs.map((c) => c.toSeed())];

  /// Search built-in seeds by Spanish word (exact or prefix, case-insensitive).
  /// Returns the matching seeds and which topic they belong to.
  List<({VocabSeed seed, String topicLabel})> searchBySpanish(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.trim().toLowerCase();
    final results = <({VocabSeed seed, String topicLabel})>[];
    for (final seed in kVocabSeeds) {
      if (seed.wordEs.toLowerCase().contains(q)) {
        results.add((seed: seed, topicLabel: topicLabel(seed.topicId)));
      }
    }
    // Also search existing custom vocabs.
    for (final cv in _customVocabs) {
      if (cv.wordEs.toLowerCase().contains(q)) {
        results.add((
          seed: cv.toSeed(),
          topicLabel: _customCollectionLabel(cv.collectionId),
        ));
      }
    }
    return results;
  }

  String _customCollectionLabel(String collectionId) {
    if (collectionId == CustomVocab.kNoCollectionId) {
      return 'Keiner Sammlung zugeordnet';
    }
    return topicLabel(collectionId);
  }

  /// Add a custom vocab. Returns false if the id already exists.
  Future<void> addCustomVocab(CustomVocab vocab) async {
    if (_profile == null) return;
    _customVocabs = [..._customVocabs, vocab];
    _progress[vocab.id] = VocabProgress.initial();
    await storage.saveCustomVocabs(_profile!.username, _customVocabs);
    await storage.saveProgress(_profile!.username, _progress);
    notifyListeners();
  }

  Future<void> createFolder(String name) async {
    if (_profile == null) return;
    final folder = UserFolder(
      id: 'folder_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      topicIds: const [],
    );
    _folders = [..._folders, folder];
    await storage.saveFolders(_profile!.username, _folders);
    notifyListeners();
  }

  Future<void> deleteFolder(String folderId) async {
    if (_profile == null) return;
    _folders = _folders.where((f) => f.id != folderId).toList();
    await storage.saveFolders(_profile!.username, _folders);
    notifyListeners();
  }

  Future<void> renameFolger(String folderId, String newName) async {
    if (_profile == null) return;
    _folders = _folders.map((f) {
      if (f.id != folderId) return f;
      return f.copyWith(name: newName);
    }).toList();
    await storage.saveFolders(_profile!.username, _folders);
    notifyListeners();
  }

  Future<void> addTopicToFolder(String folderId, String topicId) async {
    if (_profile == null) return;
    _folders = _folders.map((f) {
      if (f.id != folderId) return f;
      if (f.topicIds.contains(topicId)) return f;
      return f.copyWith(topicIds: [...f.topicIds, topicId]);
    }).toList();
    await storage.saveFolders(_profile!.username, _folders);
    notifyListeners();
  }

  Future<void> removeTopicFromFolder(String folderId, String topicId) async {
    if (_profile == null) return;
    _folders = _folders.map((f) {
      if (f.id != folderId) return f;
      return f.copyWith(
          topicIds: f.topicIds.where((id) => id != topicId).toList());
    }).toList();
    await storage.saveFolders(_profile!.username, _folders);
    notifyListeners();
  }

  /// All collections available for assigning a custom vocab.
  /// Includes built-in selected topics + the "no collection" option.
  List<({String id, String label})> get availableCollections {
    final cols = <({String id, String label})>[
      (id: CustomVocab.kNoCollectionId, label: 'Keiner Sammlung zugeordnet'),
    ];
    for (final t in topics) {
      cols.add((id: t.id, label: t.label));
    }
    return cols;
  }

  static const _chapterSize = 30;

  /// Splits a topic's seeds into deterministic chapters of [_chapterSize].
  /// Seeds are sorted by id (stable), then chunked.
  List<VocabChapter> chaptersForTopic(String topicId) {
    final label = topicLabel(topicId);
    final seeds = List<VocabSeed>.from(allSeedsForTopic(topicId))
      ..sort((a, b) => a.id.compareTo(b.id));

    final chapters = <VocabChapter>[];
    for (var i = 0; i < seeds.length; i += _chapterSize) {
      chapters.add(VocabChapter(
        topicId: topicId,
        topicLabel: label,
        index: i ~/ _chapterSize,
        seeds: seeds.sublist(i, (i + _chapterSize).clamp(0, seeds.length)),
      ));
    }
    return chapters;
  }

  /// True when every seed in the chapter is marked as known.
  bool isChapterComplete(VocabChapter chapter) {
    return chapter.seeds.every((s) => _progress[s.id]?.known == true);
  }

  /// Active (not known) seeds within a chapter for a given mode.
  List<VocabSeed> chapterActiveSeeds(VocabChapter chapter) {
    return chapter.seeds
        .where((s) {
          final p = _progress[s.id];
          return p != null && !p.known;
        })
        .toList();
  }

  int countTopicSeeds(String topicId) {
    return _filteredSeeds(topicId: topicId)
        .where((v) {
          final p = _progress[v.id]!;
          return !p.removed && !p.known;
        })
        .length;
  }

  int countPrioritizedSelected() {
    final seeds = _filteredSeeds();
    return seeds.where((v) => _progress[v.id]!.prioritized && !_progress[v.id]!.removed).length;
  }

  int countRemovedSelected() {
    final seeds = _filteredSeeds();
    return seeds.where((v) => _progress[v.id]!.removed).length;
  }

  int countKnownSelected() {
    final seeds = _filteredSeeds();
    return seeds.where((v) => _progress[v.id]!.known && !_progress[v.id]!.removed).length;
  }

  int countSelectedSeeds() {
    return _filteredSeeds().where((v) {
      final p = _progress[v.id]!;
      return !p.removed && !p.known;
    }).length;
  }

  Future<void> setSelectedTopics(List<String> topicIds) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(selectedTopicIds: topicIds);
    await storage.saveUser(_profile!);
    notifyListeners();
  }

  Future<void> setSpeedMs(int speedMs) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(speedMs: speedMs);
    await storage.saveUser(_profile!);
    notifyListeners();
  }

  Future<void> togglePriority(String vocabId, bool value) async {
    final p = _progress[vocabId];
    if (p == null) return;
    _progress[vocabId] = p.copyWith(prioritized: value);
    await storage.saveProgress(_profile!.username, _progress);
    notifyListeners();
  }

  Future<void> setRemoved(String vocabId, bool value) async {
    final p = _progress[vocabId];
    if (p == null) return;
    _progress[vocabId] = p.copyWith(removed: value, prioritized: value ? false : p.prioritized);
    await storage.saveProgress(_profile!.username, _progress);
    notifyListeners();
  }

  Future<void> setKnown(String vocabId, bool value) async {
    final p = _progress[vocabId];
    if (p == null) return;
    _progress[vocabId] = p.copyWith(known: value);
    await storage.saveProgress(_profile!.username, _progress);
    notifyListeners();
  }

  Future<void> incrementSeen(String vocabId) async {
    final p = _progress[vocabId];
    if (p == null) return;
    _progress[vocabId] = p.copyWith(seenCount: p.seenCount + 1);
    await storage.saveProgress(_profile!.username, _progress);
  }

  Future<void> recordLearningDay(DateTime date) async {
    if (_profile == null) return;
    final iso = _toIsoDate(date);
    if (_learningDatesIso.contains(iso)) return;
    _learningDatesIso = [..._learningDatesIso, iso].toList()..sort();
    await storage.saveLearningDatesIso(_profile!.username, _learningDatesIso);
    notifyListeners();
  }

  String _toIsoDate(DateTime dt) {
    final d = DateTime(dt.year, dt.month, dt.day);
    return d.toIso8601String().split('T').first;
  }

  Future<void> logout() async {
    await storage.setCurrentUser(null);
    _profile = null;
    _progress = {};
    _learningDatesIso = [];
    notifyListeners();
  }

  Future<void> resetProgress() async {
    if (_profile == null) return;

    final username = _profile!.username;
    final newProgress = <String, VocabProgress>{};
    for (final seed in kVocabSeeds) {
      newProgress[seed.id] = VocabProgress.initial();
    }
    for (final cv in _customVocabs) {
      newProgress[cv.id] = VocabProgress.initial();
    }
    _progress = newProgress;
    _learningDatesIso = [];
    await storage.saveProgress(username, _progress);
    await storage.saveLearningDatesIso(username, _learningDatesIso);
    notifyListeners();
  }
}

