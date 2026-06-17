import 'persona_model.dart';
import 'relationship_model.dart';

/// A companion instance — one AI girlfriend with her own persona, stats,
/// and chat history.
///
/// Architecture note: this model exists so we can support MULTIPLE
/// companions per user (the user mentioned adding more girlfriends
/// later). The current code only ever creates/uses one companion per
/// user, stored at `users/{uid}/persona/current`. When we're ready to
/// go multi-companion:
///
///   1. Move the persona doc from `persona/current` to
///      `companions/{companionId}`.
///   2. Add a `companions` collection listing per user.
///   3. Add a `currentCompanionIdProvider` that scopes Firestore reads.
///   4. Update ChatProvider / CallProvider / MemoryProvider to take a
///      companionId parameter.
///
/// For now this class is a thin wrapper — providers continue to use
/// PersonaModel directly, but new code should prefer CompanionModel
/// so the migration is mechanical when the time comes.
class CompanionModel {
  final String id;
  final PersonaModel persona;
  final RelationshipModel relationship;
  final String? avatarAssetPath;
  final DateTime createdAt;
  final bool isFavorite;

  const CompanionModel({
    required this.id,
    required this.persona,
    this.relationship = const RelationshipModel(),
    this.avatarAssetPath,
    required this.createdAt,
    this.isFavorite = false,
  });

  /// Default companion — used as a placeholder when none is loaded yet.
  /// Mirrors the old single-companion behaviour.
  factory CompanionModel.defaultCompanion() => CompanionModel(
        id: 'default',
        persona: const PersonaModel(),
        createdAt: DateTime.now(),
      );

  CompanionModel copyWith({
    String? id,
    PersonaModel? persona,
    RelationshipModel? relationship,
    String? avatarAssetPath,
    DateTime? createdAt,
    bool? isFavorite,
  }) =>
      CompanionModel(
        id: id ?? this.id,
        persona: persona ?? this.persona,
        relationship: relationship ?? this.relationship,
        avatarAssetPath: avatarAssetPath ?? this.avatarAssetPath,
        createdAt: createdAt ?? this.createdAt,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'persona': persona.toJson(),
        'relationship': relationship.toJson(),
        'avatarAssetPath': avatarAssetPath,
        'createdAt': createdAt.toIso8601String(),
        'isFavorite': isFavorite,
      };

  factory CompanionModel.fromJson(Map<String, dynamic> json) => CompanionModel(
        id: json['id'] ?? 'default',
        persona: PersonaModel.fromJson(
            json['persona'] as Map<String, dynamic>? ?? {}),
        relationship: RelationshipModel.fromJson(
            json['relationship'] as Map<String, dynamic>? ?? {}),
        avatarAssetPath: json['avatarAssetPath'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        isFavorite: json['isFavorite'] as bool? ?? false,
      );
}
