import 'package:cloud_firestore/cloud_firestore.dart';

class UserProgress {
  final String id;
  final String userId;
  final String challengeId;
  final bool completionStatus;
  final int streakCount;
  final DateTime? lastCompletedDate;

  UserProgress({
    required this.id,
    required this.userId,
    required this.challengeId,
    required this.completionStatus,
    required this.streakCount,
    this.lastCompletedDate,
  });

  factory UserProgress.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProgress(
      id: doc.id,
      userId: data['user_id'] ?? '',
      challengeId: data['challenge_id'] ?? '',
      completionStatus: data['completion_status'] ?? false,
      streakCount: data['streak_count'] ?? 0,
      lastCompletedDate: data['last_completed_date'] != null
          ? (data['last_completed_date'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'challenge_id': challengeId,
      'completion_status': completionStatus,
      'streak_count': streakCount,
      'last_completed_date': lastCompletedDate != null
          ? Timestamp.fromDate(lastCompletedDate!)
          : null,
    };
  }
}
