import 'dart:convert';

import '../models/custom_vocab.dart';
import '../models/user_folder.dart';
import '../models/user_profile.dart';
import '../models/vocab.dart';
import 'seed_vocab.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Simple deterministic hash — good enough for local offline storage.
String _hashPassword(String password) {
  var h = 5381;
  for (final c in password.codeUnits) {
    h = ((h << 5) + h + c) & 0xFFFFFFFF;
  }
  return h.toRadixString(16);
}

class AppStorage {
  final SharedPreferences prefs;

  AppStorage(this.prefs);

  static const _kCurrentUserKey = 'vokabel_currentUser';
  static const _kUsersKey = 'vokabel_users';
  static const _kProgressPrefix = 'vokabel_progress_';
  static const _kHistoryPrefix = 'vokabel_history_';
  static const _kCustomVocabPrefix = 'vokabel_custom_';
  static const _kFoldersPrefix = 'vokabel_folders_';

  static Future<AppStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppStorage(prefs);
  }

  String? get currentUser => prefs.getString(_kCurrentUserKey);

  Future<void> setCurrentUser(String? username) async {
    if (username == null) {
      await prefs.remove(_kCurrentUserKey);
      return;
    }
    await prefs.setString(_kCurrentUserKey, username);
  }

  // Stores a map `username -> profileJson`.
  Map<String, dynamic> _readUsersMap() {
    final raw = prefs.getString(_kUsersKey);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _writeUsersMap(Map<String, dynamic> map) async {
    await prefs.setString(_kUsersKey, jsonEncode(map));
  }

  /// Returns true if the username is already taken.
  bool userExists(String username) => _readUsersMap().containsKey(username);

  /// Creates a new account. Returns false if username is already taken.
  Future<bool> register(String username, String password) async {
    final usersMap = _readUsersMap();
    if (usersMap.containsKey(username)) return false;

    final profile = UserProfile.initial(
      username,
      passwordHash: _hashPassword(password),
    );
    usersMap[username] = profile.toJson();
    await _writeUsersMap(usersMap);
    return true;
  }

  /// Returns true if credentials are correct.
  bool checkPassword(String username, String password) {
    final usersMap = _readUsersMap();
    final json = usersMap[username];
    if (json == null) return false;
    final stored = (json as Map<String, dynamic>)['passwordHash'] as String? ?? '';
    return stored == _hashPassword(password);
  }

  Future<void> ensureUserExists(String username) async {
    final usersMap = _readUsersMap();
    if (usersMap.containsKey(username)) return;

    final profile = UserProfile.initial(username);
    usersMap[username] = profile.toJson();

    await _writeUsersMap(usersMap);
    await prefs.remove('vokabel_progress_$username');
    await prefs.remove('vokabel_history_$username');
  }

  Future<UserProfile?> getUser(String username) async {
    final usersMap = _readUsersMap();
    final json = usersMap[username];
    if (json == null) return null;
    return UserProfile.fromJson(json as Map<String, dynamic>);
  }

  Future<void> saveUser(UserProfile profile) async {
    final usersMap = _readUsersMap();
    usersMap[profile.username] = profile.toJson();
    await _writeUsersMap(usersMap);
  }

  Future<Map<String, VocabProgress>> getProgress(String username) async {
    final key = '$_kProgressPrefix$username';
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return <String, VocabProgress>{};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final Map<String, VocabProgress> result = {};
    decoded.forEach((vocabId, value) {
      result[vocabId] = VocabProgress.fromJson(value as Map<String, dynamic>);
    });
    return result;
  }

  Future<void> saveProgress(
    String username,
    Map<String, VocabProgress> progress,
  ) async {
    final key = '$_kProgressPrefix$username';
    final map = progress.map((id, p) => MapEntry(id, p.toJson()));
    await prefs.setString(key, jsonEncode(map));
  }

  Future<List<String>> getLearningDatesIso(String username) async {
    final key = '$_kHistoryPrefix$username';
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List;
    return decoded.whereType<String>().toList();
  }

  Future<void> saveLearningDatesIso(String username, List<String> datesIso) async {
    final key = '$_kHistoryPrefix$username';
    await prefs.setString(key, jsonEncode(datesIso));
  }

  Future<List<CustomVocab>> getCustomVocabs(String username) async {
    final key = '$_kCustomVocabPrefix$username';
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .whereType<Map<String, dynamic>>()
        .map(CustomVocab.fromJson)
        .toList();
  }

  Future<void> saveCustomVocabs(
      String username, List<CustomVocab> vocabs) async {
    final key = '$_kCustomVocabPrefix$username';
    await prefs.setString(
        key, jsonEncode(vocabs.map((v) => v.toJson()).toList()));
  }

  Future<List<UserFolder>> getFolders(String username) async {
    final key = '$_kFoldersPrefix$username';
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.whereType<Map<String, dynamic>>().map(UserFolder.fromJson).toList();
  }

  Future<void> saveFolders(String username, List<UserFolder> folders) async {
    final key = '$_kFoldersPrefix$username';
    await prefs.setString(key, jsonEncode(folders.map((f) => f.toJson()).toList()));
  }

  // Helper for UI: returns the full seed topic list.
  List<TopicDef> get topics => kTopics;
}

