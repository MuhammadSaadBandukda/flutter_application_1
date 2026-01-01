import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final int currentStreak;
  final int totalCompletions;
  final List<String> badges;
  final DateTime? lastActiveDate;

  UserProfile({
    required this.uid,
    required this.email,
    this.currentStreak = 0,
    this.totalCompletions = 0,
    this.badges = const [],
    this.lastActiveDate,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      currentStreak: data['current_streak'] ?? 0,
      totalCompletions: data['total_completions'] ?? 0,
      badges: List<String>.from(data['badges'] ?? []),
      lastActiveDate: data['last_active_date'] != null
          ? (data['last_active_date'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'current_streak': currentStreak,
      'total_completions': totalCompletions,
      'badges': badges,
      'last_active_date': lastActiveDate != null
          ? Timestamp.fromDate(lastActiveDate!)
          : null,
    };
  }
}
