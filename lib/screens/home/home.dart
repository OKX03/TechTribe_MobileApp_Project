import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../user/profile.dart';
import '../notification/notification_page.dart';
import '../memory/shared_memory_details_page.dart';
import '../../services/memory_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _buildSharedMemories(MemoryService memoryService, String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: memoryService.getSharedMemories(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

       if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch, // To make image full width
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.asset(
                    'assets/images/home_image.png',
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      Text(
                        'No shared memories yet!',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Welcome to Memorime! Seal your memories in capsules and unlock them with your friends.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
        final memories = snapshot.data!.docs
            .map((doc) => MapEntry(doc.id, doc.data() as Map<String, dynamic>))
            .where((entry) {
              final unlockedAt = (entry.value['unlockedAt'] as Timestamp?)?.toDate();
              return unlockedAt != null && unlockedAt.isBefore(DateTime.now());
            })
            .toList()
          ..sort((a, b) {
            final aDate = (a.value['unlockedAt'] as Timestamp).toDate();
            final bDate = (b.value['unlockedAt'] as Timestamp).toDate();
            return aDate.compareTo(bDate);
          });

        final top3 = memories.take(3).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: top3.length,
          itemBuilder: (context, index) {
            final docId = top3[index].key;
            final memory = top3[index].value;
            final ownerId = memory['ownerId']; 
            final title = memory['title'] ?? 'Untitled';
            final description = memory['description'] ?? '';
            final unlockedAt = (memory['unlockedAt'] as Timestamp).toDate();
            final createdAt = (memory['createdAt'] as Timestamp).toDate();
            final headerImage = (memory['photoUrls'] as List?)?.isNotEmpty == true
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
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              CircleAvatar(radius: 16, backgroundImage: profilePic.toString().startsWith('http')
                              ? NetworkImage(profilePic)
                              : AssetImage('assets/images/default_profile_picture.jpg') as ImageProvider,),
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
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: headerImage != null
                              ? Image.network(headerImage, height: 180, width: double.infinity, fit: BoxFit.cover)
                              : Image.asset('assets/images/default_image.png', height: 180, width: double.infinity, fit: BoxFit.cover),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Created: ${DateFormat('dd/MM/yyyy').format(createdAt)}",
                                      style: TextStyle(fontSize: 12, color: Colors.blue.shade300)),
                                  Text("Unlocks: ${DateFormat('dd/MM/yyyy').format(unlockedAt)}",
                                      style: TextStyle(fontSize: 12, color: Colors.blue.shade300)),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final memoryService = MemoryService();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        automaticallyImplyLeading: false,  // Add this line to remove back arrow
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Memorime',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage:
                    user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                child:
                    user?.photoURL == null
                        ? const Icon(Icons.person, color: Colors.blue)
                        : null,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage()));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          // Header Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1465101046530-73398c7f28ca',
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Whenever I think of the past,\nit brings back so many memories',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '- Steve Wright',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'MEMORIES SHARED WITH YOU',
              style: TextStyle(
                color: Color(0xFF90A4AE),
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.1,
              ),
            ),
          ),

          if (user != null) _buildSharedMemories(memoryService, user.uid),

          const SizedBox(height: 80), // For spacing at bottom
        ],
      ),

      // THESE GO OUTSIDE THE ListView
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
              notchMargin: 8.0,
              child: SizedBox(
                height: 64,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/home');
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.home, color: Colors.blue),
                            Text(
                              'Home',
                              style: TextStyle(color: Colors.blue, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/friends');
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.people, color: Colors.blueGrey),
                            Text(
                              'Friends',
                              style: TextStyle(color: Colors.blueGrey, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 56), // Space for FAB
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/memory');
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.photo_album, color: Colors.blueGrey),
                            Text(
                              'Memory',
                              style: TextStyle(color: Colors.blueGrey, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/timeline');
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.timeline, color: Colors.blueGrey),
                            Text(
                              'Timeline',
                              style: TextStyle(color: Colors.blueGrey, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/create_capsule');
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, size: 36, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
