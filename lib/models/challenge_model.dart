import 'package:cloud_firestore/cloud_firestore.dart';

class Challenge {
  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final String category;
  final String difficultyLevel;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.category,
    required this.difficultyLevel,
  });

  factory Challenge.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Challenge(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      durationMinutes: data['duration_minutes'] ?? 0,
      category: data['category'] ?? '',
      difficultyLevel: data['difficulty_level'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'duration_minutes': durationMinutes,
      'category': category,
      'difficulty_level': difficultyLevel,
    };
  }
}
