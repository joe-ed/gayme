
import 'package:flutter/material.dart';

class AchievementScreen extends StatelessWidget {
  const AchievementScreen({super.key});

  static const Color backgroundColor = Color(0xFF101014);
  static const Color neonPink = Color(0xFFFF00E6);
  static const Color neonYellow = Color(0xFFFFF500);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonBlue = Color(0xFF00E5FF);

  final List<Map<String, dynamic>> achievements = const [
    {
      'title': 'First Steps',
      'description': 'Play your first game.',
      'icon': Icons.play_arrow_rounded,
      'progress': 1.0,
      'completed': true,
      'color': neonGreen,
    },
    {
      'title': 'Getting Started',
      'description': 'Play 5 games.',
      'icon': Icons.sports_esports_rounded,
      'progress': 0.6,
      'completed': false,
      'color': neonPink,
    },
    {
      'title': 'High Scorer',
      'description': 'Reach a score of 1,000.',
      'icon': Icons.emoji_events_rounded,
      'progress': 0.35,
      'completed': false,
      'color': neonYellow,
    },
    {
      'title': 'Dedicated Player',
      'description': 'Play 10 games.',
      'icon': Icons.local_fire_department_rounded,
      'progress': 0.2,
      'completed': false,
      'color': neonBlue,
    },
    {
      'title': 'Perfect Run',
      'description': 'Complete a game without mistakes.',
      'icon': Icons.stars_rounded,
      'progress': 0.0,
      'completed': false,
      'color': neonPink,
    },
    {
      'title': 'Champion',
      'description': 'Unlock all achievements.',
      'icon': Icons.military_tech_rounded,
      'progress': 0.0,
      'completed': false,
      'color': neonYellow,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final completedCount =
        achievements.where((achievement) => achievement['completed'] as bool).length;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'ACHIEVEMENTS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: neonYellow,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1B23),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: neonPink, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: neonPink.withOpacity(0.2),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: neonYellow,
                    size: 48,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR PROGRESS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$completedCount / ${achievements.length} UNLOCKED',
                          style: const TextStyle(
                            color: neonGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: completedCount / achievements.length,
                            minHeight: 8,
                            backgroundColor: Colors.white12,
                            valueColor:
                            const AlwaysStoppedAnimation<Color>(neonGreen),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ALL ACHIEVEMENTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  final bool completed = achievement['completed'];
                  final Color color = achievement['color'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1B23),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: completed ? color : Colors.white12,
                        width: completed ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: completed ? color : Colors.white24,
                            ),
                          ),
                          child: Icon(
                            completed
                                ? achievement['icon']
                                : Icons.lock_rounded,
                            color: completed ? color : Colors.white38,
                            size: 29,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                achievement['title'],
                                style: TextStyle(
                                  color: completed ? color : Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                achievement['description'],
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: achievement['progress'],
                                  minHeight: 5,
                                  backgroundColor: Colors.white12,
                                  valueColor:
                                  AlwaysStoppedAnimation<Color>(color),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          completed
                              ? Icons.check_circle_rounded
                              : Icons.lock_outline_rounded,
                          color: completed ? neonGreen : Colors.white30,
                          size: 22,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
