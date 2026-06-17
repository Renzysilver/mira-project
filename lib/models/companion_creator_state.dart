import 'persona_model.dart';

/// Draft state for the companion creator wizard.
///
/// Each step of the wizard writes into this model. On the final step,
/// [toCompanionJson] converts it to the Map that gets written to the
/// companions table (Firestore now, Supabase later).
class CompanionCreatorState {
  // Identity
  final String name;
  final String ageRange;
  final String backgroundStory;

  // Appearance
  final String hairStyle;
  final String hairColor;
  final String eyeColor;
  final String faceStyle;
  final String clothing;
  final List<String> accessories;

  // Voice
  final String voiceProvider; // 'groq' | 'elevenlabs' | 'cartesia' | 'azure'
  final String voiceId;       // provider-specific
  final String accent;
  final String tone;
  final String energyLevel;
  final String speakingSpeed;
  final String speechPattern;

  // Personality
  final PersonalityType personalityType;
  final List<String> traits; // ['caring','playful','romantic',...]

  // Interests
  final List<String> interests; // ['gaming','anime','music',...]

  const CompanionCreatorState({
    this.name = '',
    this.ageRange = 'young-adult',
    this.backgroundStory = '',
    this.hairStyle = 'long',
    this.hairColor = 'black',
    this.eyeColor = 'blue',
    this.faceStyle = 'soft',
    this.clothing = 'casual',
    this.accessories = const [],
    this.voiceProvider = 'groq',
    this.voiceId = 'hannah',
    this.accent = 'neutral',
    this.tone = 'soft',
    this.energyLevel = 'medium',
    this.speakingSpeed = 'normal',
    this.speechPattern = 'casual',
    this.personalityType = PersonalityType.sweet,
    this.traits = const [],
    this.interests = const [],
  });

  CompanionCreatorState copyWith({
    String? name,
    String? ageRange,
    String? backgroundStory,
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
    String? speechPattern,
    PersonalityType? personalityType,
    List<String>? traits,
    List<String>? interests,
  }) =>
      CompanionCreatorState(
        name: name ?? this.name,
        ageRange: ageRange ?? this.ageRange,
        backgroundStory: backgroundStory ?? this.backgroundStory,
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
        speechPattern: speechPattern ?? this.speechPattern,
        personalityType: personalityType ?? this.personalityType,
        traits: traits ?? this.traits,
        interests: interests ?? this.interests,
      );

  /// Convert to the JSON shape stored in the companions table.
  ///
  /// All future schema fields are populated; the existing Firebase
  /// Firestore document just ignores the extra keys (it's schemaless).
  Map<String, dynamic> toCompanionJson() => {
        'name': name.isEmpty ? 'Mira' : name,
        'personalityType': personalityType.name,
        'currentMood': 'happy',
        'temperature': 0.8,
        'flirtEnabled': false,
        'friendshipMode': false,
        'customAvatar': null,
        'avatarAssetPath': null,
        // Future companion-creator fields
        'backgroundStory': backgroundStory,
        'hairStyle': hairStyle,
        'hairColor': hairColor,
        'eyeColor': eyeColor,
        'faceStyle': faceStyle,
        'clothing': clothing,
        'accessories': accessories,
        'voiceProvider': voiceProvider,
        'voiceId': voiceId,
        'accent': accent,
        'tone': tone,
        'energyLevel': energyLevel,
        'speakingSpeed': speakingSpeed,
        'speechPattern': speechPattern,
        'interests': interests,
        'traits': traits,
        'isFavorite': false,
        'isActive': false,
        'createdAt': DateTime.now().toIso8601String(),
      };

  /// List of all 5 wizard steps.
  static const int stepCount = 5;
  static const List<String> stepTitles = [
    'Identity',
    'Appearance',
    'Voice',
    'Personality',
    'Interests',
  ];
  static const List<String> stepSubtitles = [
    'Who is she?',
    'How does she look?',
    'How does she sound?',
    'What is she like?',
    'What does she love?',
  ];
}

// ── Static option lists (drive the picker UIs) ──────────────────────────

class CompanionCreatorOptions {
  CompanionCreatorOptions._();

  static const Map<String, String> ageRanges = {
    'teen': 'Teen (16-19)',
    'young-adult': 'Young Adult (20-26)',
    'adult': 'Adult (27-35)',
    'mature': 'Mature (36+)',
  };

  static const Map<String, String> hairStyles = {
    'long': 'Long',
    'short': 'Short',
    'medium': 'Medium',
    'twin-tails': 'Twin Tails',
    'ponytail': 'Ponytail',
    'bob': 'Bob',
    'curly': 'Curly',
    'wavy': 'Wavy',
  };

  static const Map<String, String> hairColors = {
    'black': 'Black',
    'brown': 'Brown',
    'blonde': 'Blonde',
    'white': 'White',
    'silver': 'Silver',
    'pink': 'Pink',
    'blue': 'Blue',
    'red': 'Red',
  };

  static const Map<String, String> eyeColors = {
    'blue': 'Blue',
    'green': 'Green',
    'brown': 'Brown',
    'hazel': 'Hazel',
    'violet': 'Violet',
    'amber': 'Amber',
    'red': 'Red',
    'grey': 'Grey',
  };

  static const Map<String, String> faceStyles = {
    'soft': 'Soft',
    'sharp': 'Sharp',
    'round': 'Round',
    'angular': 'Angular',
    'cute': 'Cute',
    'elegant': 'Elegant',
  };

  static const Map<String, String> clothingStyles = {
    'casual': 'Casual',
    'elegant': 'Elegant',
    'school': 'School Uniform',
    'traditional': 'Traditional',
    'gothic': 'Gothic',
    'sporty': 'Sporty',
    'formal': 'Formal',
  };

  static const List<String> accessoriesList = [
    'Glasses',
    'Hair Ribbon',
    'Cat Ears',
    'Headphones',
    'Choker',
    'Flower Crown',
    'Tiara',
    'Scarf',
  ];

  static const Map<String, String> accents = {
    'neutral': 'Neutral International',
    'american': 'American',
    'british': 'British',
    'australian': 'Australian',
    'nigerian': 'Nigerian',
    'south-african': 'South African',
    'indian': 'Indian',
    'japanese': 'Japanese (English)',
    'korean': 'Korean (English)',
    'latina': 'Latina (English)',
  };

  static const Map<String, String> tones = {
    'soft': 'Soft',
    'elegant': 'Elegant',
    'playful': 'Playful',
    'mature': 'Mature',
    'energetic': 'Energetic',
    'romantic': 'Romantic',
    'confident': 'Confident',
    'shy': 'Shy',
  };

  static const Map<String, String> energyLevels = {
    'low': 'Low / Calm',
    'medium': 'Medium',
    'high': 'High',
  };

  static const Map<String, String> speakingSpeeds = {
    'slow': 'Slow',
    'normal': 'Normal',
    'fast': 'Fast',
  };

  static const Map<String, String> speechPatterns = {
    'formal': 'Formal',
    'casual': 'Casual',
    'friendly': 'Friendly',
    'teasing': 'Teasing',
    'intellectual': 'Intellectual',
    'emotional': 'Emotional',
  };

  /// Personality traits (multi-select). Drives the trait picker chips.
  static const Map<String, String> traits = {
    'caring': 'Caring',
    'playful': 'Playful',
    'romantic': 'Romantic',
    'intellectual': 'Intellectual',
    'funny': 'Funny',
    'protective': 'Protective',
    'energetic': 'Energetic',
    'shy': 'Shy',
    'confident': 'Confident',
    'teasing': 'Teasing',
    'supportive': 'Supportive',
    'mysterious': 'Mysterious',
  };

  /// Interests (multi-select). Drives the interest picker chips.
  static const Map<String, String> interests = {
    'gaming': 'Gaming',
    'anime': 'Anime',
    'music': 'Music',
    'technology': 'Technology',
    'books': 'Books',
    'fitness': 'Fitness',
    'education': 'Education',
    'art': 'Art',
    'cooking': 'Cooking',
    'travel': 'Travel',
    'photography': 'Photography',
    'nature': 'Nature',
    'astronomy': 'Astronomy',
    'fashion': 'Fashion',
    'cinema': 'Cinema',
  };
}
