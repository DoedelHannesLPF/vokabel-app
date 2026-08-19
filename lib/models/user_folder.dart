class UserFolder {
  final String id;
  final String name;
  final List<String> topicIds; // topic ids assigned to this folder

  const UserFolder({
    required this.id,
    required this.name,
    required this.topicIds,
  });

  UserFolder copyWith({String? name, List<String>? topicIds}) => UserFolder(
        id: id,
        name: name ?? this.name,
        topicIds: topicIds ?? this.topicIds,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'topicIds': topicIds,
      };

  factory UserFolder.fromJson(Map<String, dynamic> json) => UserFolder(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        topicIds: (json['topicIds'] as List?)
                ?.whereType<String>()
                .toList() ??
            const [],
      );
}
