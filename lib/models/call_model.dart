import 'package:cloud_firestore/cloud_firestore.dart';

// ── Enums ──────────────────────────────────────────────────────────────────
enum CallStatus { ringing, connected, ended }
enum CallPhase  { dialing, listening, thinking, speaking }

// ── Live call state (used by CallScreen via callProvider) ──────────────────
class CallState {
  final String id;
  final CallStatus status;
  final CallPhase phase;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final bool isMuted;
  final bool isSpeakerOn;
  final String lastUserSpeech;
  final String lastAiSpeech;

  const CallState({
    required this.id,
    required this.status,
    required this.phase,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds = 0,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.lastUserSpeech = '',
    this.lastAiSpeech = '',
  });

  CallState copyWith({
    String? id,
    CallStatus? status,
    CallPhase? phase,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
    bool? isMuted,
    bool? isSpeakerOn,
    String? lastUserSpeech,
    String? lastAiSpeech,
  }) =>
      CallState(
        id: id ?? this.id,
        status: status ?? this.status,
        phase: phase ?? this.phase,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        isMuted: isMuted ?? this.isMuted,
        isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
        lastUserSpeech: lastUserSpeech ?? this.lastUserSpeech,
        lastAiSpeech: lastAiSpeech ?? this.lastAiSpeech,
      );

  String get formattedDuration {
    final mins = durationSeconds ~/ 60;
    final secs = durationSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}

// ── Firestore DTO (used by callHistoryProvider for call history reads) ──────
class CallModel {
  final String id;
  final String personaName;
  final int duration;
  final DateTime endedAt;
  final String? summary;

  const CallModel({
    required this.id,
    required this.personaName,
    required this.duration,
    required this.endedAt,
    this.summary,
  });

  factory CallModel.fromMap(Map<String, dynamic> data) {
    return CallModel(
      id: data['id'] ?? '',
      personaName: data['personaName'] ?? 'Unknown',
      duration: data['duration'] ?? 0,
      endedAt: (data['endedAt'] as Timestamp).toDate(),
      summary: data['summary'],
    );
  }

  String get formattedDuration {
    final mins = duration ~/ 60;
    final secs = duration % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}