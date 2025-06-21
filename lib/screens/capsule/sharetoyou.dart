import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/time_capsule.dart';

class SharedToYouTab extends StatefulWidget {
  const SharedToYouTab({super.key});

  @override
  State<SharedToYouTab> createState() => _SharedToYouTabState();
}

class _SharedToYouTabState extends State<SharedToYouTab> {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    print('Current userId: $userId');
    if (userId == null) {
      return const Center(child: Text('User not logged in'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('capsules')
                .where('visibleTo', arrayContains: userId)
                .orderBy('unlockDate')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              final now = DateTime.now();
              final List<TimeCapsule> sharedCapsules = [];

              for (final doc in docs) {
                final capsule = TimeCapsule.fromJson(doc.data() as Map<String, dynamic>, doc.id);

                final unlockDate = capsule.unlockDate;
                final isToday = unlockDate.year == now.year &&
                    unlockDate.month == now.month &&
                    unlockDate.day == now.day;

                if ((unlockDate.isAfter(now) || isToday) && capsule.status == 'locked') {
                  sharedCapsules.add(capsule);
                }
              }

              if (sharedCapsules.isEmpty) {
                return const Center(child: Text('No capsules shared with you.'));
              }

              return ListView.builder(
                itemCount: sharedCapsules.length,
                itemBuilder: (context, index) {
                  final capsule = sharedCapsules[index];
                  final daysLeft = capsule.unlockDate.difference(DateTime(now.year, now.month, now.day)).inDays;
                  final isToday = capsule.unlockDate.year == now.year &&
                      capsule.unlockDate.month == now.month &&
                      capsule.unlockDate.day == now.day;
                  final isUnlocked = daysLeft < 0;

                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: Icon(
                        isUnlocked ? Icons.lock_open : Icons.lock,
                        color: isUnlocked ? Colors.green : Colors.blueAccent,
                      ),
                      title: Text(capsule.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Unlock Date: ${_formatDate(capsule.unlockDate)}'),
                          Text('Unlocks in $daysLeft days'),
                          Text('Created on: ${_formatDate(capsule.createdAt)}'),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day} ${_monthName(date.month)} ${date.year}";
  }

  String _monthName(int month) {
    const months = [
      '', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return months[month];
  }
}