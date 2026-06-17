import '../../models/persona_model.dart';

/// All selectable options for the companion creator.
///
/// Centralised here so the UI and the provider agree on the option lists,
/// and so it's easy to add more options later (e.g. new hair styles or
/// voice providers).
class CompanionCreatorOptions {
  // ── Age range ──────────────────────────────────────────────────────
  static const ageRanges = [
    '18-22', '23-27', '28-35', '36+', 'Ageless',
  ];

  // ── Personality traits (multi-select) ──────────────────────────────
  static const personalityTraits = [
    'Caring', 'Playful', 'Romantic', 'Intellectual',
    'Funny', 'Protective', 'Energetic', 'Shy',
    'Confident', 'Teasing', 'Supportive',
  ];

  // ── Hair style ─────────────────────────────────────────────────────
  static const hairStyles = [
    'Long', 'Short', 'Ponytail', 'Twin tails',
    'Bob', 'Curly', 'Wavy', 'Straight',
  ];

  // ── Hair color ─────────────────────────────────────────────────────
  static const hairColors = [
    'Black', 'Brown', 'Blonde', 'Red',
    'Pink', 'Blue', 'Purple', 'White', 'Silver',
  ];

  // ── Eye color ──────────────────────────────────────────────────────
  static const eyeColors = [
    'Blue', 'Green', 'Brown', 'Hazel',
    'Gray', 'Amber', 'Violet', 'Pink',
  ];

  // ── Face style ─────────────────────────────────────────────────────
  static const faceStyles = [
    'Round', 'Oval', 'Heart', 'Square',
    'Cute', 'Elegant',
  ];

  // ── Clothing ───────────────────────────────────────────────────────
  static const clothingStyles = [
    'Casual', 'Formal', 'School uniform', 'Traditional',
    'Modern', 'Fantasy', 'Gothic',
  ];

  // ── Accessories (multi-select) ─────────────────────────────────────
  static const accessories = [
    'Glasses', 'Hair ribbon', 'Earrings', 'Necklace',
    'Headphones', 'None',
  ];

  // ── Accents ────────────────────────────────────────────────────────
  static const accents = [
    'Neutral International', 'American', 'British', 'Australian',
    'Nigerian', 'South African', 'Indian',
    'Japanese-accented', 'Korean-accented', 'Latina-accented',
  ];

  // ── Voice tones ────────────────────────────────────────────────────
  static const voiceTones = [
    'Soft', 'Elegant', 'Playful', 'Mature',
    'Energetic', 'Romantic', 'Confident', 'Shy',
  ];

  // ── Energy levels ──────────────────────────────────────────────────
  static const energyLevels = ['Low', 'Medium', 'High'];

  // ── Speaking speeds ────────────────────────────────────────────────
  static const speakingSpeeds = ['Slow', 'Normal', 'Fast'];

  // ── Interests (multi-select) ───────────────────────────────────────
  static const interests = [
    'Gaming', 'Anime', 'Music', 'Technology', 'Books',
    'Fitness', 'Education', 'Art', 'Cooking', 'Travel',
    'Photography', 'Writing', 'Sports', 'Dance',
  ];
}

/// Form state for the companion creator wizard.
class CompanionCreatorState {
  final int currentStep;
  final String name;
  final String ageRange;
  final String backgroundStory;

  final PersonalityType personalityType;
  final List<String> personalityTraits;

  final String hairStyle;
  final String hairColor;
  final String eyeColor;
  final String faceStyle;
  final String clothing;
  final List<String> accessories;

  final String voiceProvider;
  final String voiceId;
  final String accent;
  final String tone;
  final String energyLevel;
  final String speakingSpeed;

  final List<String> interests;

  final bool isSaving;
  final String? error;

  const CompanionCreatorState({
    this.currentStep = 0,
    this.name = '',
    this.ageRange = '18-22',
    this.backgroundStory = '',
    this.personalityType = PersonalityType.sweet,
    this.personalityTraits = const ['Caring'],
    this.hairStyle = 'Long',
    this.hairColor = 'Pink',
    this.eyeColor = 'Blue',
    this.faceStyle = 'Cute',
    this.clothing = 'Casual',
    this.accessories = const [],
    this.voiceProvider = 'groq',
    this.voiceId = 'hannah',
    this.accent = 'Neutral International',
    this.tone = 'Soft',
    this.energyLevel = 'Medium',
    this.speakingSpeed = 'Normal',
    this.interests = const ['Anime'],
    this.isSaving = false,
    this.error,
  });

  static const int totalSteps = 6; // identity, personality, appearance,
                                    // voice, interests, review

  CompanionCreatorState copyWith({
    int? currentStep,
    String? name,
    String? ageRange,
    String? backgroundStory,
    PersonalityType? personalityType,
    List<String>? personalityTraits,
    String? hairStyle,
    String? hairColor,
    String? eyeColor,
    String? faceStyle,
    String? clothing,
    List<String>? accessories,
    String? voiceProvider,
    String? voiceId,
    String? accent,
    String? tone,
    String? energyLevel,
    String? speakingSpeed,
    List<String>? interests,
    bool? isSaving,
    String? error,
  }) {
    return CompanionCreatorState(
      currentStep: currentStep ?? this.currentStep,
      name: name ?? this.name,
      ageRange: ageRange ?? this.ageRange,
      backgroundStory: backgroundStory ?? this.backgroundStory,
      personalityType: personalityType ?? this.personalityType,
      personalityTraits: personalityTraits ?? this.personalityTraits,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      eyeColor: eyeColor ?? this.eyeColor,
      faceStyle: faceStyle ?? this.faceStyle,
      clothing: clothing ?? this.clothing,
      accessories: accessories ?? this.accessories,
      voiceProvider: voiceProvider ?? this.voiceProvider,
      voiceId: voiceId ?? this.voiceId,
      accent: accent ?? this.accent,
      tone: tone ?? this.tone,
      energyLevel: energyLevel ?? this.energyLevel,
      speakingSpeed: speakingSpeed ?? this.speakingSpeed,
      interests: interests ?? this.interests,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }

  /// Serialise to a Firestore-ready map. Includes everything the schema
  /// in supabase/schema.sql expects.
  Map<String, dynamic> toFirestore() => {
        'name': name.isEmpty ? 'Mira' : name,
        'age_range': ageRange,
        'background_story': backgroundStory,
        'personality_type': personalityType.name,
        'personality_traits': personalityTraits,
        'hair_style': hairStyle,
        'hair_color': hairColor,
        'eye_color': eyeColor,
        'face_style': faceStyle,
        'clothing': clothing,
        'accessories': accessories,
        'voice_provider': voiceProvider,
        'voice_id': voiceId,
        'accent': accent,
        'tone': tone,
        'energy_level': energyLevel,
        'speaking_speed': speakingSpeed,
        'interests': interests,
        'current_mood': 'happy',
        'temperature': 0.8,
        'flirt_enabled': false,
        'friendship_mode': false,
        'is_active': true,
        'is_favorite': false,
      };
}
