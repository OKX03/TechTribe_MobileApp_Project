import 'package:flutter/material.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample achievements data - in a real app, this would come from a backend
    final achievements = [
      {
        'title': 'Early Bird',
        'description': 'Joined TechTribe in its early days',
        'icon': Icons.star,
        'color': const Color(0xFFFFD700),
        'earned': true,
        'progress': 1.0,
      },
      {
        'title': 'Memory Keeper',
        'description': 'Created 10 time capsules',
        'icon': Icons.lock_clock,
        'color': const Color(0xFF7BC6A4),
        'earned': false,
        'progress': 0.6,
      },
      {
        'title': 'Social Butterfly',
        'description': 'Connected with 20 friends',
        'icon': Icons.people,
        'color': const Color(0xFF3B5BFE),
        'earned': false,
        'progress': 0.3,
      },
      {
        'title': 'Time Traveler',
        'description': 'Opened 5 time capsules',
        'icon': Icons.access_time,
        'color': const Color(0xFFF45B3B),
        'earned': true,
        'progress': 1.0,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 22,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Achievements',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(width: 48), // for symmetry
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Stats summary
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD86B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat('2', 'Earned'),
                          _buildDivider(),
                          _buildStat('4', 'Total'),
                          _buildDivider(),
                          _buildStat('50%', 'Progress'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Achievements list
                    ...achievements.map(
                      (achievement) =>
                          _buildAchievementCard(context, achievement),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFD86B),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 40, width: 1, color: Colors.grey[300]);
  }

  Widget _buildAchievementCard(
    BuildContext context,
    Map<String, dynamic> achievement,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              achievement['earned'] ? achievement['color'] : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: achievement['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  achievement['icon'],
                  color: achievement['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement['description'],
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (achievement['earned'])
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF7BC6A4),
                  size: 24,
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: achievement['progress'],
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(achievement['color']),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
