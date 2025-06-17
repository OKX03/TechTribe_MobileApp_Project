import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../app.dart';
import '../../services/memory_service.dart';
import 'memory_details_page.dart';

class MemoriesTab extends StatefulWidget {
  const MemoriesTab({super.key});

  @override
  State<MemoriesTab> createState() => _MemoriesTabState();
}

class _MemoriesTabState extends State<MemoriesTab> {
  String _searchQuery = '';
  String _filterOption = 'Unlocked Date';
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (newDate != null) {
      setState(() {
        if (isStart) {
          _startDate = newDate;
        } else {
          _endDate = newDate;
        }
      });
    }
  }

  void _clearDates() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
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

  

  final memoryService = MemoryService();

  void _confirmDelete(BuildContext context, MemoryService service, String memoryId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this memory?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              try {
                await memoryService.deleteMemory(memoryId);
                if (!context.mounted) return;
                Navigator.pop(dialogContext);
                showSuccessMessage("Memory deleted successfully!");
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(dialogContext);
                showErrorMessage("Failed to delete memory.");
              }
            },
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text('You must be logged in to view memories.'));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search memories by title...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                const Text("Sort by: "),
                DropdownButton<String>(
                  value: _filterOption,
                  items: const [
                    DropdownMenuItem(value: 'Unlocked Date', child: Text('Unlocked Date')),
                    DropdownMenuItem(value: 'Created Date', child: Text('Created Date')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _filterOption = value);
                  },
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _clearDates,
                  icon: const Icon(Icons.clear),
                  label: const Text("Clear Dates"),
                )
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _startDate == null
                          ? "Start Date"
                          : DateFormat('dd/MM/yyyy').format(_startDate!),
                    ),
                    onPressed: () => _pickDate(context, true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _endDate == null
                          ? "End Date"
                          : DateFormat('dd/MM/yyyy').format(_endDate!),
                    ),
                    onPressed: () => _pickDate(context, false),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // 🔄 Memory List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: memoryService.getMyMemories(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var memories = snapshot.data!.docs;
               
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text("No memories yet.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // 🔍 Filter by title
                memories = memories.where((doc) {
                  final title = (doc['title'] ?? '').toString().toLowerCase();
                  return title.contains(_searchQuery);
                }).toList();

                // 📅 Date range filter
                memories = memories.where((doc) {
                  final DateTime date = (doc[_filterOption == 'Unlocked Date' ? 'unlockedAt' : 'createdAt'] as Timestamp).toDate();
                  if (_startDate != null && date.isBefore(_startDate!)) return false;
                  if (_endDate != null && date.isAfter(_endDate!)) return false;
                  return true;
                }).toList();

                // 🔽 Sort
                memories.sort((a, b) {
                  final aTime = (a[_filterOption == 'Unlocked Date' ? 'unlockedAt' : 'createdAt'] as Timestamp).toDate();
                  final bTime = (b[_filterOption == 'Unlocked Date' ? 'unlockedAt' : 'createdAt'] as Timestamp).toDate();
                  return bTime.compareTo(aTime); // newest first
                });

                if (memories.isEmpty) {
                  return const Center(child: Text('No memories match the filters.'));
                }

                return ListView.builder(
                  itemCount: memories.length,
                  itemBuilder: (context, index) {
                    final memory = memories[index].data() as Map<String, dynamic>;
                    final docId = memories[index].id;

                    final title = memory['title'] ?? 'Untitled';
                    final description = memory['description'] ?? '';
                    final unlockedAt = (memory['unlockedAt'] as Timestamp).toDate();
                    final createdAt = (memory['createdAt'] as Timestamp).toDate();
                    final headerImage = (memory['photoUrls'] as List).isNotEmpty
                        ? memory['photoUrls'][0]
                        : null;

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MemoryDetailPage(
                            memoryId: docId,
                            memoryData: memory,
                          ),
                        ),
                      ),
                      onLongPress: () {
                        _confirmDelete(context, memoryService, docId);
                      },
                      child: Card(
                        color: Colors.white,
                        margin: const EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          if (headerImage != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Image.network(
                                headerImage,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Image.asset(
                                "assets/images/default_image.png",
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0))),
                                  const SizedBox(height: 6),
                                  Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Created: ${DateFormat('dd/MM/yyyy').format(createdAt)}",
                                        style: TextStyle(fontSize: 12, color: Colors.blue.shade300),
                                      ),
                                      Text(
                                        "Unlocked: ${DateFormat('dd/MM/yyyy').format(unlockedAt)}",
                                        style: TextStyle(fontSize: 12, color: Colors.blue.shade300),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
      ),
    );
  }
}
