class PersonalSpace {
  const PersonalSpace({
    required this.id,
    required this.name,
    required this.avatarText,
    this.syncEnabled = true,
  });

  final String id;
  final String name;
  final String avatarText;
  final bool syncEnabled;

  PersonalSpace copyWith({
    String? id,
    String? name,
    String? avatarText,
    bool? syncEnabled,
  }) {
    return PersonalSpace(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarText: avatarText ?? this.avatarText,
      syncEnabled: syncEnabled ?? this.syncEnabled,
    );
  }
}
