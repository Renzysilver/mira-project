class RelationshipModel {
  final int daysTogether;
  final int messagesSent;
  final int callsMade;
  final int affectionLevel;
  final int streakDays;
  final String lastCheckIn;
  final String startDate;

  const RelationshipModel({this.daysTogether = 0, this.messagesSent = 0, this.callsMade = 0, this.affectionLevel = 30, this.streakDays = 0, this.lastCheckIn = '', this.startDate = ''});

  RelationshipModel copyWith({int? daysTogether, int? messagesSent, int? callsMade, int? affectionLevel, int? streakDays, String? lastCheckIn, String? startDate}) {
    return RelationshipModel(daysTogether: daysTogether ?? this.daysTogether, messagesSent: messagesSent ?? this.messagesSent, callsMade: callsMade ?? this.callsMade, affectionLevel: affectionLevel ?? this.affectionLevel, streakDays: streakDays ?? this.streakDays, lastCheckIn: lastCheckIn ?? this.lastCheckIn, startDate: startDate ?? this.startDate);
  }

  String get affectionLabel {
    if (affectionLevel < 20) return 'Acquaintance';
    if (affectionLevel < 40) return 'Friend';
    if (affectionLevel < 60) return 'Close Friend';
    if (affectionLevel < 80) return 'Best Friend';
    return 'Soulmate';
  }

  Map<String, dynamic> toJson() => {'daysTogether': daysTogether, 'messagesSent': messagesSent, 'callsMade': callsMade, 'affectionLevel': affectionLevel, 'streakDays': streakDays, 'lastCheckIn': lastCheckIn, 'startDate': startDate};
  factory RelationshipModel.fromJson(Map<String, dynamic> json) => RelationshipModel(daysTogether: json['daysTogether'] ?? 0, messagesSent: json['messagesSent'] ?? 0, callsMade: json['callsMade'] ?? 0, affectionLevel: json['affectionLevel'] ?? 30, streakDays: json['streakDays'] ?? 0, lastCheckIn: json['lastCheckIn'] ?? '', startDate: json['startDate'] ?? '');
}
