import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile_model.dart';
import '../models/user_progress_model.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final FirestoreService firestoreService = FirestoreService();

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please log in")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    child: Icon(Icons.person, size: 40),
                  ),
                  const SizedBox(height: 8),
                  Text(user.email ?? 'User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats Stream
            StreamBuilder<UserProfile>(
              stream: firestoreService.getUserProfile(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final profile = snapshot.data!;

                return Column(
                  children: [
                    // Streak Card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem("Current Streak", "${profile.currentStreak} Days", Icons.local_fire_department, Colors.orange),
                            _buildStatItem("Total Done", "${profile.totalCompletions}", Icons.check_circle, Colors.green),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Badges Section
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Badges Earned", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    profile.badges.isEmpty
                        ? const Text("No badges yet. Keep learning!", style: TextStyle(color: Colors.grey))
                        : Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: profile.badges.map((badgeId) => _buildBadge(badgeId)).toList(),
                          ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Progress Chart Section
            const Text("Activity (Last 7 Days)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: StreamBuilder<List<UserProgress>>(
                stream: firestoreService.getUserAllProgress(user.uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  return _buildChart(snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildBadge(String badgeId) {
    String label = "";
    Color color = Colors.grey;
    IconData icon = Icons.star;

    switch (badgeId) {
      case 'streak_3':
        label = "3 Day Streak";
        color = Colors.blue;
        break;
      case 'streak_7':
        label = "7 Day Streak";
        color = Colors.purple;
        break;
      case 'streak_30':
        label = "30 Day Streak";
        color = Colors.amber;
        icon = Icons.emoji_events;
        break;
      default:
        label = badgeId;
    }

    return Chip(
      avatar: CircleAvatar(backgroundColor: Colors.white, child: Icon(icon, size: 16, color: color)),
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color),
    );
  }

  Widget _buildChart(List<UserProgress> allProgress) {
    // Process data for last 7 days
    final now = DateTime.now();
    final Map<int, int> counts = {};

    for (int i = 0; i < 7; i++) {
      counts[i] = 0; // Initialize 0-6
    }

    for (var p in allProgress) {
      if (p.completionStatus && p.lastCompletedDate != null) {
        final diff = now.difference(p.lastCompletedDate!).inDays;
        if (diff >= 0 && diff < 7) {
          // 0 is today, 6 is 6 days ago. 
          // We want to reverse for chart: Left (6 days ago) -> Right (Today)
          // Chart Index 0 = 6 days ago.
          // Chart Index 6 = Today.
          // So, chartIndex = 6 - diff.
          int chartIndex = 6 - diff;
          counts[chartIndex] = (counts[chartIndex] ?? 0) + 1;
        }
      }
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (counts.values.fold(0, (p, c) => p > c ? p : c) + 2).toDouble(),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final date = now.subtract(Duration(days: 6 - value.toInt()));
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "${date.day}/${date.month}",
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: counts[index]?.toDouble() ?? 0,
                color: Colors.deepPurple,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }
}
