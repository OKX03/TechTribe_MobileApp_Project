import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memorime_v1/models/time_capsule.dart';

import 'components/capsule_list_view.dart';
import 'components/capsule_grid_view.dart';

import '../../services/capsule_service.dart';

class TimeCapsuleTab extends StatefulWidget {
  const TimeCapsuleTab({super.key});

  @override
  State<TimeCapsuleTab> createState() => _TimeCapsuleTabState();
}

class _TimeCapsuleTabState extends State<TimeCapsuleTab> {
  bool isListView = true;
  late String userId;
  late CapsuleService capsuleService;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      userId = currentUser.uid;
      capsuleService = CapsuleService(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const Center(child: Text('User not logged in'));
    }

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Share Icon Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Your Capsules",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  color: Colors.blueAccent,
                  onPressed: () {},
                  icon: const Icon(Icons.screen_share_outlined),
                ),
              ],
            ),
          ),

          // Toggle View Icon Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                _buildToggleIcon(
                  icon: Icons.list_rounded,
                  isActive: isListView,
                  onTap: () {
                    setState(() {
                      isListView = true;
                    });
                  },
                ),
                _buildToggleIcon(
                  icon: Icons.grid_view_rounded,
                  isActive: !isListView,
                  onTap: () {
                    setState(() {
                      isListView = false;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 6.0),

          // Capsule List/Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('capsules')
                  .where('ownerId', isEqualTo: userId)
                  .orderBy('unlockDate')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final now = DateTime.now();
                final List<TimeCapsule> lockedCapsules = [];

                for (final doc in docs) {
                  final capsule = TimeCapsule.fromJson(doc.data() as Map<String, dynamic>, doc.id);

                  // If unlocked, migrate it
                  if (capsule.unlockDate.isBefore(now) || capsule.unlockDate.isAtSameMomentAs(now)) {
                    capsuleService.migrateToMemory(capsule);
                  } else {
                    // Still locked
                    lockedCapsules.add(capsule);
                  }
                }

                if (lockedCapsules.isEmpty) {
                  return const Center(child: Text('No locked capsules available.'));
                }

                return isListView
                    ? CapsuleListView(capsuleService: capsuleService)
                    : CapsuleGridView(capsules: lockedCapsules, month: DateTime.now());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleIcon({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 30,
        color: isActive ? Colors.blue : Colors.grey,
      ),
    );
  }
}
