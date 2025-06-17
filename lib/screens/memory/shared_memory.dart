import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../services/memory_service.dart';
import 'shared_memory_details_page.dart';

// class SharedWithYouTab extends StatefulWidget {
//   const SharedWithYouTab({super.key});

//   @override
//   State<SharedWithYouTab> createState() => _SharedWithYouTabState();
// }

// class _SharedWithYouTabState extends State<SharedWithYouTab> {
//   final memoryService = MemoryService();

//   @override
//   Widget build(BuildContext context) {
//     final currentUserId = FirebaseAuth.instance.currentUser?.uid;

//     return Scaffold(
//       body: StreamBuilder<QuerySnapshot>(
//         stream: memoryService.getSharedMemories(currentUserId), // ✅ fixed userId ref
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

//           final docs = snapshot.data!.docs;

//           if (docs.isEmpty) {
//             return const Center(child: Text("No shared memories yet."));
//           }

//           return Padding(
//             padding: const EdgeInsets.all(8),
//             child: GridView.builder(
//               itemCount: docs.length,
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 crossAxisSpacing: 12,
//                 mainAxisSpacing: 12,
//                 childAspectRatio: 0.70,
//               ),
//               itemBuilder: (context, index) {
//                 final doc = docs[index];
//                 final memory = doc.data() as Map<String, dynamic>;
//                 final docId = doc.id;

//                 final title = memory['title'] ?? 'Untitled';
//                 final description = memory['description'] ?? '';
//                 final unlockedAt = (memory['unlockedAt'] as Timestamp).toDate();
//                 final createdAt = (memory['createdAt'] as Timestamp).toDate();
//                 final headerImage = (memory['photoUrls'] as List).isNotEmpty
//                     ? memory['photoUrls'][0]
//                     : null;

//                 final ownerId = memory['ownerId'];
//                 print("Owner ID: $ownerId");
//                 return FutureBuilder<DocumentSnapshot>(
//                   future: memoryService.getUserProfile(ownerId),
//                   builder: (context, userSnapshot) {
//                     if (!userSnapshot.hasData) {
//                       return const Center(child: CircularProgressIndicator());
//                     }

//                     final userData = userSnapshot.data!.data() as Map<String, dynamic>?;

//                     final profilePic = userData?['profile_picture'] ??
//                         'https://www.gravatar.com/avatar/placeholder?d=mp';
//                     final username = userData?['username'] ?? 'Unknown';

//                     return GestureDetector(
//                       onTap: () => Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => SharedMemoryDetailPage(
//                             memoryId: docId,
//                             memoryData: memory,
//                           ),
//                         ),
//                       ),
//                       child: LayoutBuilder(
//                         builder: (context, constraints) {
//                           return Card(
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                             elevation: 4,
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 // 👤 User Info Bar
//                                 Padding(
//                                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                                   child: Row(
//                                     children: [
//                                       CircleAvatar(
//                                         radius: 16,
//                                         backgroundImage: NetworkImage(profilePic),
//                                       ),
//                                       const SizedBox(width: 8),
//                                       Expanded(
//                                         child: Text(
//                                           username,
//                                           style: const TextStyle(fontWeight: FontWeight.bold),
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),

//                                 // 📸 Header Image
//                                 ClipRRect(
//                                   // borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//                                   child: headerImage != null
//                                       ? Image.network(
//                                           headerImage,
//                                           height: 150,
//                                           width: double.infinity,
//                                           fit: BoxFit.cover,
//                                         )
//                                       : Image.asset(
//                                           "assets/images/default_image.png",
//                                           height: 150,
//                                           width: double.infinity,
//                                           fit: BoxFit.cover,
//                                           alignment: Alignment.center,
//                                         ),
//                                 ),

//                                 // 📝 Flexible text container
//                                 Flexible(
//                                   child: Padding(
//                                     padding: const EdgeInsets.all(10),
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           title,
//                                           style: const TextStyle(
//                                             fontSize: 14,
//                                             fontWeight: FontWeight.bold,
//                                             color: Color.fromARGB(255, 0, 0, 0),
//                                           ),
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                         const SizedBox(height: 4),
//                                         // Text(
//                                         //   description,
//                                         //   maxLines: 2,
//                                         //   overflow: TextOverflow.ellipsis,
//                                         //   style: const TextStyle(fontSize: 12),
//                                         // ),
//                                         const Spacer(),
//                                         Text(
//                                           "Unlocked: ${DateFormat('dd/MM/yyyy').format(unlockedAt)}",
//                                           style: TextStyle(fontSize: 10, color: Colors.blue.shade300),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           );
//                         },
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
class SharedWithYouTab extends StatefulWidget {
  const SharedWithYouTab({super.key});

  @override
  State<SharedWithYouTab> createState() => _SharedWithYouTabState();
}

class _SharedWithYouTabState extends State<SharedWithYouTab> {
  final memoryService = MemoryService();
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
        if (isStart) _startDate = newDate;
        else _endDate = newDate;
      });
    }
  }

  void _clearDates() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    if (currentUserId == null) {
      return const Center(child: Text("You must be logged in."));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          //Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by title or username...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),

          //  Sort+ Clear Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
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

          /// Date Range
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

          const SizedBox(height: 8),

          /// Memory Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: memoryService.getSharedMemories(currentUserId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text("No shared memories yet.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  );
                }


                return FutureBuilder<List<QueryDocumentSnapshot>>(
                  future: _filterMemories(docs),
                  builder: (context, filteredSnapshot) {
                    if (!filteredSnapshot.hasData) return const CircularProgressIndicator();
                    final filteredDocs = filteredSnapshot.data!;
                    if (filteredDocs.isEmpty) {
                      return const Center(child: Text("No matching shared memories."));
                    }

                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: GridView.builder(
                        itemCount: filteredDocs.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.70,
                        ),
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final memory = doc.data() as Map<String, dynamic>;
                          final docId = doc.id;
                          final ownerId = memory['ownerId'];
                          final title = memory['title'] ?? '';
                          final unlockedAt = (memory['unlockedAt'] as Timestamp).toDate();
                          final headerImage = (memory['photoUrls'] as List).isNotEmpty
                              ? memory['photoUrls'][0]
                              : null;

                          return FutureBuilder<DocumentSnapshot>(
                            future: memoryService.getUserProfile(ownerId),
                            builder: (context, userSnapshot) {
                              if (!userSnapshot.hasData) return const SizedBox();
                              final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                              final username = userData?['username'] ?? 'Unknown';
                              final profilePic = userData?['profile_picture'] ??
                                  'https://www.gravatar.com/avatar/placeholder?d=mp';

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SharedMemoryDetailPage(
                                        memoryId: docId,
                                        memoryData: memory,
                                      ),
                                    ),
                                  );
                                },
                                child: Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      /// User Info
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        child: Row(
                                          children: [
                                            CircleAvatar(radius: 16, backgroundImage: NetworkImage(profilePic)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                username,
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      /// Image
                                      ClipRRect(
                                        child: headerImage != null
                                            ? Image.network(
                                                headerImage,
                                                height: 150,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.asset(
                                                "assets/images/default_image.png",
                                                height: 150,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                      /// Title & Date
                                      Flexible(
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold, fontSize: 14),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const Spacer(),
                                              Text(
                                                "Unlocked: ${DateFormat('dd/MM/yyyy').format(unlockedAt)}",
                                                style: TextStyle(fontSize: 10, color: Colors.blue.shade300),
                                              ),
                                            ],
                                          ),
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

  /// 🔍 Filter logic
  Future<List<QueryDocumentSnapshot>> _filterMemories(List<QueryDocumentSnapshot> docs) async {
    final List<QueryDocumentSnapshot> result = [];

    for (final doc in docs) {
      final memory = doc.data() as Map<String, dynamic>;
      final title = (memory['title'] ?? '').toString().toLowerCase();
      final unlockedAt = (memory['unlockedAt'] as Timestamp).toDate();
      final createdAt = (memory['createdAt'] as Timestamp).toDate();
      final ownerId = memory['ownerId'];

      // Get username
      final userSnap = await memoryService.getUserProfile(ownerId);
      final username = (userSnap.data() as Map<String, dynamic>?)?['username']?.toLowerCase() ?? '';

      // Search match
      final matchesSearch = _searchQuery.isEmpty ||
          title.contains(_searchQuery) ||
          username.contains(_searchQuery);

      // Date filter
      final targetDate = _filterOption == 'Unlocked Date' ? unlockedAt : createdAt;
      final matchesStart = _startDate == null || !targetDate.isBefore(_startDate!);
      final matchesEnd = _endDate == null || !targetDate.isAfter(_endDate!);

      if (matchesSearch && matchesStart && matchesEnd) {
        result.add(doc);
      }
    }

    return result;
  }
}
