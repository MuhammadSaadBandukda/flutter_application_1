import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/challenge_model.dart';
import '../models/user_progress_model.dart';
import '../models/user_profile_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Users & Profile ---

  // Create or Update User (Modified to merge profile data)
  Future<void> saveUser(String userId, String email) async {
    // Check if user exists to avoid overwriting stats on login
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) {
      await _db.collection('users').doc(userId).set({
        'email': email,
        'current_streak': 0,
        'total_completions': 0,
        'badges': [],
        'last_active_date': null,
      });
    }
  }

  // Get User Profile
  Stream<UserProfile> getUserProfile(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      return UserProfile.fromFirestore(doc);
    });
  }

  // Update Global Stats (Called when a challenge is completed)
  Future<void> updateGlobalStats(String userId) async {
    final docRef = _db.collection('users').doc(userId);
    
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final lastActiveTimestamp = data['last_active_date'] as Timestamp?;
      final currentStreak = data['current_streak'] as int? ?? 0;
      final totalCompletions = data['total_completions'] as int? ?? 0;
      List<String> badges = List<String>.from(data['badges'] ?? []);

      final now = DateTime.now();
      final lastActiveDate = lastActiveTimestamp?.toDate();
      
      int newStreak = currentStreak;

      // Logic to update streak
      if (lastActiveDate == null) {
        newStreak = 1;
      } else {
        final yesterday = DateTime(now.year, now.month, now.day - 1);
        final lastActiveDay = DateTime(lastActiveDate.year, lastActiveDate.month, lastActiveDate.day);
        final today = DateTime(now.year, now.month, now.day);

        if (lastActiveDay.isAtSameMomentAs(yesterday)) {
          newStreak++;
        } else if (lastActiveDay.isBefore(yesterday)) {
          newStreak = 1;
        } else if (lastActiveDay.isAtSameMomentAs(today)) {
          // Already active today, streak doesn't change
        }
      }

      // Check for Badges
      if (newStreak >= 3 && !badges.contains('streak_3')) badges.add('streak_3');
      if (newStreak >= 7 && !badges.contains('streak_7')) badges.add('streak_7');
      if (newStreak >= 30 && !badges.contains('streak_30')) badges.add('streak_30');

      // Update Transaction
      transaction.update(docRef, {
        'current_streak': newStreak,
        'total_completions': totalCompletions + 1,
        'last_active_date': FieldValue.serverTimestamp(),
        'badges': badges,
      });
    });
  }

  // --- Challenges Collection ---


  // Add Challenge
  Future<void> addChallenge(Challenge challenge) async {
    await _db.collection('challenges').add(challenge.toMap());
  }

  // Get Challenges (with optional category filter)
  Stream<List<Challenge>> getChallenges({String? category}) {
    Query query = _db.collection('challenges');
    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Challenge.fromFirestore(doc)).toList();
    });
  }

  // Get Single Challenge
  Future<Challenge> getChallenge(String id) async {
    var doc = await _db.collection('challenges').doc(id).get();
    if (doc.exists) {
      return Challenge.fromFirestore(doc);
    } else {
      throw Exception("Challenge not found");
    }
  }

  // Update Challenge
  Future<void> updateChallenge(Challenge challenge) async {
    await _db.collection('challenges').doc(challenge.id).update(challenge.toMap());
  }

  // Delete Challenge
  Future<void> deleteChallenge(String id) async {
    await _db.collection('challenges').doc(id).delete();
  }

  // --- User Progress Collection ---

  // Initialize or Update Progress
  Future<void> updateUserProgress(UserProgress progress) async {
    // We can use a composite ID or let Firestore generate one.
    // If we want to easily find progress for a specific user and challenge, 
    // it's often good to query. 
    // If the ID in the model is empty, we add, otherwise we update.
    
    if (progress.id.isEmpty) {
       await _db.collection('user_progress').add(progress.toMap());
    } else {
       await _db.collection('user_progress').doc(progress.id).update(progress.toMap());
    }
  }

  // Get Progress for a specific User and Challenge
  Future<UserProgress?> getUserProgress(String userId, String challengeId) async {
    var query = await _db
        .collection('user_progress')
        .where('user_id', isEqualTo: userId)
        .where('challenge_id', isEqualTo: challengeId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return UserProgress.fromFirestore(query.docs.first);
    }
    return null;
  }
  
  // Get all progress for a user
  Stream<List<UserProgress>> getUserAllProgress(String userId) {
    return _db
        .collection('user_progress')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserProgress.fromFirestore(doc)).toList();
    });
  }
}
