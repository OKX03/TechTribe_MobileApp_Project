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

  Future<void> _showBranchCreationDialog(
    BuildContext context,
    Map<String, dynamic> parentMemory,
  ) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String privacy = 'Private';

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create Branch Memory'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter branch memory title',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter branch memory description',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: privacy,
                    decoration: const InputDecoration(labelText: 'Privacy'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Private',
                        child: Text('Private'),
                      ),
                      DropdownMenuItem(
                        value: 'Friends',
                        child: Text('Friends'),
                      ),
                      DropdownMenuItem(value: 'Public', child: Text('Public')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        privacy = value;
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a title')),
                    );
                    return;
                  }

                  try {
                    final userId = FirebaseAuth.instance.currentUser?.uid;
                    if (userId == null) return;

                    await _memoryService.createBranch(
                      parentMemoryId: parentMemory['id'],
                      title: titleController.text,
                      description: descriptionController.text,
                      ownerId: userId,
                      photoUrls: List<String>.from(
                        parentMemory['photoUrls'] ?? [],
                      ),
                      videoUrls: List<String>.from(
                        parentMemory['videoUrls'] ?? [],
                      ),
                      audioUrls: List<String>.from(
                        parentMemory['audioUrls'] ?? [],
                      ),
                      fileUrls: List<String>.from(
                        parentMemory['fileUrls'] ?? [],
                      ),
                      privacy: privacy,
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Branch memory created successfully!'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error creating branch: $e')),
                      );
                    }
                  }
                },
                child: const Text('Create Branch'),
              ),
            ],
          ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    String memoryId,
    bool isBranch,
  ) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isBranch ? 'Delete Branch?' : 'Delete Memory?'),
            content: Text(
              isBranch
                  ? 'This will delete this branch and all its sub-branches. This action cannot be undone.'
                  : 'Are you sure you want to delete this memory? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () async {
                  try {
                    if (isBranch) {
                      await _memoryService.deleteBranch(memoryId);
                    } else {
                      await _memoryService.deleteMemory(memoryId);
                    }
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isBranch
                                ? 'Branch deleted successfully'
                                : 'Memory deleted successfully',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting: $e')),
                      );
                    }
                  }
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    Map<String, dynamic> memory,
    String memoryId,
  ) async {
    final titleController = TextEditingController(text: memory['title']);
    final descriptionController = TextEditingController(
      text: memory['description'],
    );
    String privacy = memory['privacy'] ?? 'Private';

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Memory'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter memory title',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter memory description',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: privacy,
                    decoration: const InputDecoration(labelText: 'Privacy'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Private',
                        child: Text('Private'),
                      ),
                      DropdownMenuItem(
                        value: 'Friends',
                        child: Text('Friends'),
                      ),
                      DropdownMenuItem(value: 'Public', child: Text('Public')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        privacy = value;
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a title')),
                    );
                    return;
                  }

                  try {
                    await FirebaseFirestore.instance
                        .collection('memories')
                        .doc(memoryId)
                        .update({
                          'title': titleController.text,
                          'description': descriptionController.text,
                          'privacy': privacy,
                        });

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Memory updated successfully!'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating memory: $e')),
                      );
                    }
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          ),
    );
  }

  void _showMemoryOptions(
    BuildContext context,
    Map<String, dynamic> memory,
    String memoryId,
  ) {
    final isBranch = memory['isBranch'] ?? false;

    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(context, memory, memoryId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmationDialog(context, memoryId, isBranch);
                  },
                ),
              ],
            ),
          ),
    );
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
              child: const Center(child: CircularProgressIndicator()),
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
    return Container();
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
              const Text(
                'Timeline',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.sort),
                itemBuilder:
                    (context) => [
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

              // Build a map of parentId -> List of branches
              final Map<String, List<QueryDocumentSnapshot>> branchMap = {};
              final List<QueryDocumentSnapshot> mainMemories = [];
              for (var doc in memories) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['isBranch'] == true &&
                    data['parentMemoryId'] != null) {
                  branchMap
                      .putIfAbsent(data['parentMemoryId'], () => [])
                      .add(doc);
                } else {
                  mainMemories.add(doc);
                }
              }

              // Helper to recursively build widgets for a memory and its branches
              List<Widget> buildMemoryWithBranches(
                QueryDocumentSnapshot doc,
                int branchLevel,
              ) {
                final memory = doc.data() as Map<String, dynamic>;
                final memoryId = doc.id;
                final date =
                    _sortByUnlockDate
                        ? (memory['unlockedAt'] as Timestamp).toDate()
                        : (memory['createdAt'] as Timestamp).toDate();
                final isBranch = memory['isBranch'] ?? false;
                final branches = branchMap[memoryId] ?? [];

                List<Widget> widgets = [
                  GestureDetector(
                    onLongPress:
                        () => _showMemoryOptions(context, memory, memoryId),
                    child: TimelineTile(
                      alignment: TimelineAlign.manual,
                      lineXY: 0.2 + (branchLevel * 0.1),
                      isFirst:
                          false, // We'll handle first/last visually by spacing
                      isLast: false,
                      indicatorStyle: IndicatorStyle(
                        width: 20,
                        color: isBranch ? Colors.green : Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        iconStyle: IconStyle(
                          color: Colors.white,
                          iconData: isBranch ? Icons.call_split : Icons.circle,
                        ),
                      ),
                      startChild: Container(
                        padding: EdgeInsets.only(
                          left: 16.0 + branchLevel * 24,
                          right: 8,
                        ),
                        child: Text(
                          DateFormat('MMM dd').format(date),
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
                            Row(
                              children: [
                                if (isBranch)
                                  const Icon(
                                    Icons.call_split,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    memory['title'] ?? 'Untitled',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (memory['photoUrls'] != null &&
                                (memory['photoUrls'] as List).isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  memory['photoUrls'][0],
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('MMM dd, yyyy').format(date),
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                Wrap(
                                  spacing: 4,
                                  children: [
                                    if (!isBranch)
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          minimumSize: Size(0, 32),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 0,
                                          ),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed:
                                            () => _showBranchCreationDialog(
                                              context,
                                              {...memory, 'id': memoryId},
                                            ),
                                        icon: const Icon(
                                          Icons.call_split,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Branch',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        minimumSize: Size(0, 32),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 0,
                                        ),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => MemoryDetailPage(
                                                  memoryId: memoryId,
                                                  memoryData: memory,
                                                ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'View Details',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
                // Recursively add branches below
                for (var branch in branches) {
                  widgets.addAll(
                    buildMemoryWithBranches(branch, branchLevel + 1),
                  );
                }
                return widgets;
              }

              // Sort main memories by date
              mainMemories.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aDate =
                    _sortByUnlockDate
                        ? (aData['unlockedAt'] as Timestamp).toDate()
                        : (aData['createdAt'] as Timestamp).toDate();
                final bDate =
                    _sortByUnlockDate
                        ? (bData['unlockedAt'] as Timestamp).toDate()
                        : (bData['createdAt'] as Timestamp).toDate();
                return bDate.compareTo(aDate);
              });

              // Build the timeline list
              List<Widget> timelineList = [];
              for (var doc in mainMemories) {
                timelineList.addAll(buildMemoryWithBranches(doc, 0));
              }

              return ListView(children: timelineList);
            },
          ),
        ),
      ],
    );
  }
}
