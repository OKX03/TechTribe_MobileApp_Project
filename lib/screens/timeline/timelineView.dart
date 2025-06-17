import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:intl/intl.dart';
import '../../services/memory_service.dart';
import '../memory/memory_details_page.dart';

class TimelineView extends StatefulWidget {
  const TimelineView({Key? key}) : super(key: key);

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  final MemoryService _memoryService = MemoryService();
  bool _sortByUnlockDate = true;

  String _formatDate(DateTime date) {
    return DateFormat('yyyy').format(date);
  }

  Widget _buildMemoryContent(Map<String, dynamic> memory) {
    if (memory['type'] == 'image' && memory['mediaUrl'] != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          memory['mediaUrl'],
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Icon(Icons.error),
            );
          },
        ),
      );
    }
    return Container(); // Return empty container for non-image memories
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const Center(child: Text('Please login'));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Timeline', 
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
              PopupMenuButton(
                icon: const Icon(Icons.sort),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Sort by Created'),
                    onTap: () => setState(() => _sortByUnlockDate = false),
                  ),
                  PopupMenuItem(
                    child: const Text('Sort by Unlocked'),
                    onTap: () => setState(() => _sortByUnlockDate = true),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _memoryService.getMyMemories(userId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final memories = snapshot.data?.docs ?? [];
              if (memories.isEmpty) {
                return const Center(child: Text('No memories yet!'));
              }

              return ListView.builder(
                itemCount: memories.length,
                itemBuilder: (context, index) {
                  final memory = memories[index].data() as Map<String, dynamic>;
                  final date = _sortByUnlockDate 
                      ? (memory['unlockedAt'] as Timestamp).toDate()
                      : (memory['createdAt'] as Timestamp).toDate();
                  final isFirst = index == 0;
                  final isLast = index == memories.length - 1;

                  return TimelineTile(
                    alignment: TimelineAlign.manual,
                    lineXY: 0.2,
                    isFirst: isFirst,
                    isLast: isLast,
                    indicatorStyle: IndicatorStyle(
                      width: 20,
                      color: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                    ),
                    startChild: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _formatDate(date),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    endChild: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            memory['title'] ?? 'Untitled',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (memory['type'] == 'image')
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                memory['content'],
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: 8),
                          //_buildMemoryContent(memory),
                          //const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMM dd, yyyy').format(date),
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MemoryDetailPage(
                                        memoryId: memories[index].id,
                                        memoryData: memory,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('View Details'),
                              ),
                            ],
                          ),
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
}