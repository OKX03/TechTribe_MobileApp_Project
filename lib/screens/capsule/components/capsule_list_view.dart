import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/time_capsule.dart';
import '../../../repository/capsule_repository.dart';
import '../../../services/capsule_service.dart';
import '../capsule_detailsPage.dart.dart';
import '../../../app.dart';
import '../select_friend.dart';
import '../animationUnlock.dart';
import '../../memory/memory_details_page.dart';

class CapsuleListView extends StatefulWidget {
  final CapsuleService capsuleService;

  const CapsuleListView({super.key, required this.capsuleService});

  @override
  State<CapsuleListView> createState() => _CapsuleListViewState();
}

class _CapsuleListViewState extends State<CapsuleListView> {

  @override
  void initState() {
    super.initState();
    // final userId = FirebaseAuth.instance.currentUser!.uid;
    // widget.capsuleService.fetchAllCapsules().then((capsules) {
    //   widget.capsuleService.migrateUnlockedCapsules(capsules);
    // });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TimeCapsule>>(
       stream: widget.capsuleService.streamLockedCapsules(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No capsules found."));
        }

        final capsules = snapshot.data!;

        return ListView.builder(
          itemCount: capsules.length,
          itemBuilder: (context, index) {
            final capsule = capsules[index];
            final now = DateTime.now();
            final daysLeft = capsule.unlockDate.difference(DateTime(now.year, now.month, now.day)).inDays;

            // Check if unlock date is today
            final isToday = capsule.unlockDate.year == now.year &&
                capsule.unlockDate.month == now.month &&
                capsule.unlockDate.day == now.day;

            final isUnlocked = daysLeft < 0;

            return GestureDetector(
              onTap: () {
                _onUnlockCapsule(context, capsule);
              },
              child: CapsuleCard(
                title: capsule.title,
                unlockDate: _formatDate(capsule.unlockDate),
                daysLeft: daysLeft.toString(),
                createdDate: _formatDate(capsule.createdAt),
                isUnlocked: isUnlocked,
                isToday: isToday,
                onEdit: () => _showEditDialog(context, widget.capsuleService, capsule),
                onDelete: () => _confirmDelete(context, widget.capsuleService, capsule.id),
                onUnlock: isToday && !isUnlocked
                    ? () => _onUnlockCapsule(context, capsule)
                    : null,
              ),
            );
          },
      );
    },
  );
}

  void showSuccessMessage(String message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  void showErrorMessage(String message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }


  void _confirmDelete(BuildContext context, CapsuleService service, String capsuleId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this capsule?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
             try {
              await service.deleteCapsule(capsuleId);
              if (!mounted) return;
              // Navigator.pop(dialogContext);
              showSuccessMessage( "Capsule deleted successfully!");
            } catch (e) {
              if (!mounted) return;
              Navigator.pop(dialogContext);
              showErrorMessage("Failed to delete capsule.");
            }


            },
          ),
        ],
      ),
    );
  }

  Future<List<String>> computeVisibleToUids(String privacy, List<String> selectedFriendIds) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    if (privacy == 'private') return [];

    if (privacy == 'public') {
      final firestore = FirebaseFirestore.instance;

      final asOwner = await firestore
          .collection('friendList')
          .where('ownerId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();

      final asFriend = await firestore
          .collection('friendList')
          .where('friendId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();

      final friendUids = <String>{};
      for (var doc in asOwner.docs) {
        friendUids.add(doc['friendId']);
      }
      for (var doc in asFriend.docs) {
        friendUids.add(doc['ownerId']);
      }

      return friendUids.toList();
    }

    if (privacy == 'specific') return selectedFriendIds;

    return [userId];
  }

  void _showEditDialog(BuildContext context,  CapsuleService service, TimeCapsule capsule) {
    final privacyOptions = ["private", "public", "specific"];
    String selectedPrivacy = capsule.privacy.toLowerCase();
    DateTime selectedDate = capsule.unlockDate;
    List<String> selectedVisibleTo = List.from(capsule.visibleTo);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Edit Capsule"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: selectedPrivacy,
                items: privacyOptions.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(p[0].toUpperCase() + p.substring(1)),
                  );
                }).toList(),
                onChanged: (val) async {
                  if (val == null) return;

                  final visibleTo = await computeVisibleToUids(val, selectedVisibleTo);

                  setState(() {
                    selectedPrivacy = val;
                    selectedVisibleTo = visibleTo;
                  });
                },
                decoration: const InputDecoration(labelText: "Privacy"),
              ),
              const SizedBox(height: 8),

              // Show friend selector info + edit button
              if (selectedPrivacy == 'specific')
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Shared with ${selectedVisibleTo.length} friend(s)',
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      tooltip: "Edit selected friends/groups",
                      onPressed: () async {
                        final result = await Navigator.push<List<String>>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SelectFriendsPage(initiallySelected: selectedVisibleTo),
                          ),
                        );

                        if (result != null) {
                          setState(() {
                            selectedVisibleTo = result;
                          });
                        }
                      },
                    )
                  ],
                ),

              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("Unlock Date: "),
                  TextButton(
                    child: Text(
                      "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                      style: const TextStyle(color: Colors.blue),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            ElevatedButton(
              child: const Text("Save"),
              onPressed: () async {
                try {
                  print('Updating capsule: ${capsule.id}');
                  await service.updateCapsule(
                    capsule.id,
                    privacy: selectedPrivacy,
                    unlockDate: selectedDate,
                    visibleTo: selectedVisibleTo,
                  );

                  if (!mounted) return;
                   Navigator.of(dialogContext).pop();
                  showSuccessMessage("Capsule updated successfully!");
                } catch (e) {
                  if (!mounted) return;
                  Navigator.of(dialogContext).pop();
                  showErrorMessage("Failed to update capsule.");
                }
              },
            ),
          ],
        ),
      ),
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

  void _showUnlockDialog(BuildContext context, TimeCapsule capsule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Unlock Capsule"),
        content: const Text("Do you want to unlock this capsule now?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: const Text("Unlock"),
            onPressed: () {
              Navigator.pop(ctx); // Close the prompt
              _showUnlockAnimation(context, capsule); // Show animation next
            },
          ),
        ],
      ),
    );
  }

  void _onUnlockCapsule(BuildContext context, TimeCapsule capsule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Unlock Capsule"),
        content: const Text("Do you want to unlock this capsule now?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: const Text("Unlock"),
            onPressed: () {
              Navigator.pop(ctx); // Close the prompt
              _showUnlockAnimation(context, capsule); // Show animation next
            },
          ),
        ],
      ),
    );
  }

  void _showUnlockAnimation(BuildContext context, TimeCapsule capsule) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CapsuleUnlockAnimation(
        onCompleted: () async {
          Navigator.of(context).pop();

          // Use the root navigator context for navigation
          final rootContext = navigatorKey.currentContext;
          if (rootContext == null) return;

          // Migrate capsule to memory
          final userId = FirebaseAuth.instance.currentUser!.uid;
          final capsuleService = CapsuleService(userId);
          await capsuleService.migrateToMemory(capsule);

          // Fetch the memory document after unlocking
          final memoryDoc = await FirebaseFirestore.instance
              .collection('memories')
              .doc(capsule.id)
              .get();

          if (memoryDoc.exists) {
            Navigator.of(rootContext).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    MemoryDetailPage(
                      memoryId: capsule.id,
                      memoryData: memoryDoc.data()!,
                    ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0); // Start from bottom
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.ease));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
                transitionDuration: const Duration(milliseconds: 600),
              ),
            );
          } else {
            ScaffoldMessenger.of(rootContext).showSnackBar(
              const SnackBar(content: Text('Memory not found!')),
            );
          }
        },
      ),
    );
  }
}


class CapsuleCard extends StatelessWidget {
  final String title;
  final String unlockDate;
  final String daysLeft;
  final String createdDate;
  final bool isUnlocked;
  final bool isToday;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onUnlock;

  const CapsuleCard({
    super.key,
    required this.title,
    required this.unlockDate,
    required this.daysLeft,
    required this.createdDate,
    required this.isUnlocked,
    required this.isToday,
    this.onEdit,
    this.onDelete,
    this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: Stack(
        children: [
          // Card content
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24.0), // Space for icon row
                Row(
                  children: [
                    Icon(
                      isUnlocked ? Icons.lock_open : Icons.lock,
                      color: isUnlocked ? Colors.green : Colors.blueAccent,
                      size: 24.0,
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    const Icon(Icons.lock_open, color: Colors.blueAccent, size: 12.0),
                    const SizedBox(width: 4.0),
                    Text(
                      'Unlock Date: $unlockDate',
                      style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Unlocks in $daysLeft days',
                      style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Created on: $createdDate',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.blue[300],
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Unlock button if today and not unlocked
                if (isToday && !isUnlocked && onUnlock != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.lock_open),
                      label: const Text("Unlock Now"),
                      onPressed: onUnlock,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Top-right buttons
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
