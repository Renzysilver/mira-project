class MemoryModel {
  final String id;
  final String fact;
  final String category;
  final DateTime createdAt;

  const MemoryModel({required this.id, required this.fact, required this.category, required this.createdAt});
  Map<String, dynamic> toJson() => {'id': id, 'fact': fact, 'category': category, 'createdAt': createdAt.toIso8601String()};
  factory MemoryModel.fromJson(Map<String, dynamic> json) => MemoryModel(id: json['id'], fact: json['fact'], category: json['category'], createdAt: DateTime.parse(json['createdAt']));
}
