import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/challenge_model.dart';
import '../models/user_progress_model.dart';
import '../services/firestore_service.dart';

class DailyChallengesScreen extends StatefulWidget {
  const DailyChallengesScreen({super.key});

  @override
  State<DailyChallengesScreen> createState() => _DailyChallengesScreenState();
}

class _DailyChallengesScreenState extends State<DailyChallengesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Coding', 'Drawing', 'Mindfulness', 'Fitness'];

  // Helper to check if two dates are the same day
  bool _isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
  
  // ... (existing _isYesterday and _markAsDone methods remain the same, omitting for brevity in replacement if not touched, but I need to replace the build method primarily)
  // Actually, I must include the context for the replacement to work, or replace the whole class/build method.
  // Since I need to insert state variables and change the build method entirely, I will target the State class content.
  
  // To be safe and precise with 'replace', I will replace the class body parts.
  // However, replacing the whole file is safer to ensure structure is correct with imports.
  // Let's rewrite the file content since I'm changing the state and the build tree significantly.
  
  // Helper to check if date1 is yesterday relative to date2
  bool _isYesterday(DateTime date1, DateTime date2) {
    final yesterday = date2.subtract(const Duration(days: 1));
    return _isSameDay(date1, yesterday);
  }

  Future<void> _markAsDone(Challenge challenge, UserProgress? currentProgress) async {
    if (_userId.isEmpty) return;

    final now = DateTime.now();
    int newStreak = 1;
    String docId = currentProgress?.id ?? '';

    // Calculate Streak
    if (currentProgress != null && currentProgress.lastCompletedDate != null) {
      if (_isSameDay(currentProgress.lastCompletedDate, now)) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Challenge already completed today!')),
        );
        return; 
      } else if (_isYesterday(currentProgress.lastCompletedDate!, now)) {
        newStreak = currentProgress.streakCount + 1;
      } else {
        newStreak = 1;
      }
    }

    final newProgress = UserProgress(
      id: docId,
      userId: _userId,
      challengeId: challenge.id,
      completionStatus: true,
      streakCount: newStreak,
      lastCompletedDate: now,
    );

    try {
      await _firestoreService.updateUserProgress(newProgress);
      await _firestoreService.updateGlobalStats(_userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marked as done! Streak: $newStreak')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view challenges.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Challenges'),
      ),
      body: Column(
        children: [
          // Category Filter
          SizedBox(
            height: 60,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    }
                  },
                );
              },
            ),
          ),
          
          // Challenges List
          Expanded(
            child: StreamBuilder<List<Challenge>>(
              stream: _firestoreService.getChallenges(category: _selectedCategory),
              builder: (context, challengeSnapshot) {
                if (challengeSnapshot.hasError) {
                  return Center(child: Text('Error: ${challengeSnapshot.error}'));
                }
                if (challengeSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final challenges = challengeSnapshot.data ?? [];

                if (challenges.isEmpty) {
                  return Center(child: Text('No $_selectedCategory challenges found.'));
                }

                return StreamBuilder<List<UserProgress>>(
                  stream: _firestoreService.getUserAllProgress(_userId),
                  builder: (context, progressSnapshot) {
                    final userProgressList = progressSnapshot.data ?? [];
                    final progressMap = {
                      for (var p in userProgressList) p.challengeId: p
                    };

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                           return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.5,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: challenges.length,
                            itemBuilder: (context, index) {
                              return _buildChallengeCard(challenges[index], progressMap[challenges[index].id]);
                            },
                          );
                        } else {
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: challenges.length,
                            itemBuilder: (context, index) {
                              return _buildChallengeCard(challenges[index], progressMap[challenges[index].id]);
                            },
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(Challenge challenge, UserProgress? progress) {
    final bool isCompletedToday = progress != null && 
        progress.lastCompletedDate != null && 
        _isSameDay(progress.lastCompletedDate, DateTime.now());
    
    final int currentStreak = progress?.streakCount ?? 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    challenge.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    challenge.difficultyLevel, 
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: _getDifficultyColor(challenge.difficultyLevel),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              challenge.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${challenge.durationMinutes} min', style: const TextStyle(color: Colors.grey)),
                const SizedBox(width: 16),
                if (currentStreak > 0) ...[
                   const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                   const SizedBox(width: 4),
                   Text('$currentStreak streak', style: const TextStyle(color: Colors.orange)),
                ]
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isCompletedToday ? null : () => _markAsDone(challenge, progress),
                icon: Icon(isCompletedToday ? Icons.check_circle : Icons.radio_button_unchecked),
                label: Text(isCompletedToday ? 'Completed' : 'Mark as Done'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompletedToday ? Colors.green : Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.green.withOpacity(0.7),
                  disabledForegroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String level) {
    switch (level.toLowerCase()) {
      case 'easy': return Colors.green;
      case 'medium': return Colors.orange;
      case 'hard': return Colors.red;
      default: return Colors.blue;
    }
  }
}
