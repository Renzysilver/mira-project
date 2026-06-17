import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String role;
  final String content;
  final DateTime timestamp;
  final bool isStreaming;

  MessageModel({required this.id, required this.role, required this.content, required this.timestamp, this.isStreaming = false});

  MessageModel copyWith({String? id, String? role, String? content, DateTime? timestamp, bool? isStreaming}) {
    return MessageModel(id: id ?? this.id, role: role ?? this.role, content: content ?? this.content, timestamp: timestamp ?? this.timestamp, isStreaming: isStreaming ?? this.isStreaming);
  }

  Map<String, dynamic> toJson() => {'id': id, 'role': role, 'content': content, 'timestamp': timestamp.toIso8601String(), 'isStreaming': isStreaming};

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    id: json['id'],
    role: json['role'],
    content: json['content'],
    timestamp: json['timestamp'] is Timestamp
        ? (json['timestamp'] as Timestamp).toDate()
        : DateTime.parse(json['timestamp'] as String),
    isStreaming: json['isStreaming'] ?? false,
  );

  Map<String, String> toApiFormat() => {'role': role, 'content': content};
}