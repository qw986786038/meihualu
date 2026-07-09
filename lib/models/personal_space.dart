class PersonalSpace {
  const PersonalSpace({
    required this.id,
    required this.name,
    required this.avatarText,
    this.syncEnabled = true,
    this.photoNum = 0,
    this.logo,
  });

  final String id;
  final String name;
  final String avatarText;
  final bool syncEnabled;
  final int photoNum;
  final String? logo;

  PersonalSpace copyWith({
    String? id,
    String? name,
    String? avatarText,
    bool? syncEnabled,
    int? photoNum,
    String? logo,
  }) {
    return PersonalSpace(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarText: avatarText ?? this.avatarText,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      photoNum: photoNum ?? this.photoNum,
      logo: logo ?? this.logo,
    );
  }
}
