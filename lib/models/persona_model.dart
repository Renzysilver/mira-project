enum PersonalityType { sweet, tsundere, intellectual }
enum AvatarMood { happy, shy, excited, sad, thinking, sleepy, neutral, flirty }

class PersonaModel {
  final String name;
  final PersonalityType personalityType;
  final AvatarMood currentMood;
  final double temperature;
  final bool flirtEnabled;
  final bool friendshipMode;
  final String? customAvatar;
  /// Per-companion personality traits (from the companion creator).
  /// e.g. ['Adventurous', 'Confident', 'Playful']
  /// If empty, falls back to generic tags based on [personalityType].
  final List<String> personalityTraits;

  const PersonaModel({
    this.name = 'Mira',
    this.personalityType = PersonalityType.sweet,
    this.currentMood = AvatarMood.happy,
    this.temperature = 0.8,
    this.flirtEnabled = false,
    this.friendshipMode = false,
    this.customAvatar,
    this.personalityTraits = const [],
  });

  PersonaModel copyWith({
    String? name,
    PersonalityType? personalityType,
    AvatarMood? currentMood,
    double? temperature,
    bool? flirtEnabled,
    bool? friendshipMode,
    String? customAvatar,
    List<String>? personalityTraits,
  }) {
    return PersonaModel(
      name: name ?? this.name,
      personalityType: personalityType ?? this.personalityType,
      currentMood: currentMood ?? this.currentMood,
      temperature: temperature ?? this.temperature,
      flirtEnabled: flirtEnabled ?? this.flirtEnabled,
      friendshipMode: friendshipMode ?? this.friendshipMode,
      customAvatar: customAvatar ?? this.customAvatar,
      personalityTraits: personalityTraits ?? this.personalityTraits,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'personalityType': personalityType.name,
    'currentMood': currentMood.name,
    'temperature': temperature,
    'flirtEnabled': flirtEnabled,
    'friendshipMode': friendshipMode,
    'customAvatar': customAvatar,
    'personalityTraits': personalityTraits,
  };

  factory PersonaModel.fromJson(Map<String, dynamic> json) => PersonaModel(
    name: json['name'] ?? 'Mira',
    personalityType: PersonalityType.values.firstWhere(
        (e) => e.name == json['personalityType'],
        orElse: () => PersonalityType.sweet),
    currentMood: AvatarMood.values.firstWhere(
        (e) => e.name == json['currentMood'],
        orElse: () => AvatarMood.happy),
    temperature: (json['temperature'] as num?)?.toDouble() ?? 0.8,
    flirtEnabled: json['flirtEnabled'] ?? false,
    friendshipMode: json['friendshipMode'] ?? false,
    customAvatar: json['customAvatar'],
    personalityTraits: (json['personalityTraits'] as List<dynamic>? ??
        json['personality_traits'] as List<dynamic>? ?? const [])
        .map((e) => e as String)
        .toList(),
  );

  Map<String, dynamic> toApiFormat() => {
    'name': name,
    'personalityType': personalityType.name,
    'mood': currentMood.name,
    'temperature': temperature,
    'flirtEnabled': flirtEnabled,
    'friendshipMode': friendshipMode,
  };

  /// Human-readable personality name.
  String get personalityDisplayName =>
      name.isEmpty ? 'Mira' : '${name[0].toUpperCase()}${name.substring(1)}';
}
