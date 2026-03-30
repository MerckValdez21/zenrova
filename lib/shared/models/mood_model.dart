enum MoodType {
  happy,
  sad,
  anxious,
  calm,
  excited,
  angry,
  neutral,
}

class MoodModel {
  final String id;
  final String userId;
  final MoodType moodType;
  final int intensity; // 1-10 scale
  final String? note;
  final List<String> tags;
  final DateTime createdAt;

  const MoodModel({
    required this.id,
    required this.userId,
    required this.moodType,
    required this.intensity,
    this.note,
    required this.tags,
    required this.createdAt,
  });

  factory MoodModel.fromJson(Map<String, dynamic> json) {
    return MoodModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      moodType: MoodType.values.firstWhere(
        (e) => e.toString() == 'MoodType.${json['moodType']}',
        orElse: () => MoodType.neutral,
      ),
      intensity: json['intensity'] ?? 5,
      note: json['note'],
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'moodType': moodType.toString().split('.').last,
      'intensity': intensity,
      'note': note,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  MoodModel copyWith({
    String? id,
    String? userId,
    MoodType? moodType,
    int? intensity,
    String? note,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return MoodModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      moodType: moodType ?? this.moodType,
      intensity: intensity ?? this.intensity,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
