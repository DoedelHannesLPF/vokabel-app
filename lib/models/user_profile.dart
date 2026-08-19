class UserProfile {
  final String username;
  final String passwordHash; // simple hash stored locally
  final List<String> selectedTopicIds;
  final int speedMs; // delay per phase in a card (word -> translation)
  final int reviewSeenThreshold; // seenCount >= threshold AND !known
  final List<String> learningDatesIso; // ISO-8601 dates when the user learned

  const UserProfile({
    required this.username,
    required this.passwordHash,
    required this.selectedTopicIds,
    required this.speedMs,
    required this.reviewSeenThreshold,
    required this.learningDatesIso,
  });

  factory UserProfile.initial(String username, {String passwordHash = ''}) =>
      UserProfile(
        username: username,
        passwordHash: passwordHash,
        selectedTopicIds: const [],
        speedMs: 900,
        reviewSeenThreshold: 4,
        learningDatesIso: const [],
      );

  UserProfile copyWith({
    String? passwordHash,
    List<String>? selectedTopicIds,
    int? speedMs,
    int? reviewSeenThreshold,
    List<String>? learningDatesIso,
  }) {
    return UserProfile(
      username: username,
      passwordHash: passwordHash ?? this.passwordHash,
      selectedTopicIds: selectedTopicIds ?? this.selectedTopicIds,
      speedMs: speedMs ?? this.speedMs,
      reviewSeenThreshold: reviewSeenThreshold ?? this.reviewSeenThreshold,
      learningDatesIso: learningDatesIso ?? this.learningDatesIso,
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'passwordHash': passwordHash,
        'selectedTopicIds': selectedTopicIds,
        'speedMs': speedMs,
        'reviewSeenThreshold': reviewSeenThreshold,
        'learningDatesIso': learningDatesIso,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        username: (json['username'] as String?) ?? '',
        passwordHash: (json['passwordHash'] as String?) ?? '',
        selectedTopicIds:
            (json['selectedTopicIds'] as List?)?.whereType<String>().toList() ??
                const [],
        speedMs: (json['speedMs'] as num?)?.toInt() ?? 900,
        reviewSeenThreshold:
            (json['reviewSeenThreshold'] as num?)?.toInt() ?? 4,
        learningDatesIso:
            (json['learningDatesIso'] as List?)?.whereType<String>().toList() ??
                const [],
      );
}

