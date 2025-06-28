import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'video_player.dart';
import 'audio_player.dart';
import 'package:url_launcher/url_launcher.dart';

class MemoryDetailPage extends StatelessWidget {
  final String memoryId;
  final Map<String, dynamic> memoryData;

  const MemoryDetailPage({
    super.key,
    required this.memoryId,
    required this.memoryData,
  });

  @override
  Widget build(BuildContext context) {
    final title = memoryData['title'] ?? 'Untitled';
    final description = memoryData['description'] ?? '';
    final createdAt = (memoryData['createdAt'] as Timestamp).toDate();
    final unlockedAt = (memoryData['unlockedAt'] as Timestamp).toDate();
    final photos = List<String>.from(memoryData['photoUrls'] ?? []);
    final videos = List<String>.from(memoryData['videoUrls'] ?? []);
    final audioUrls = List<String>.from(memoryData['audioUrls'] ?? []);
    final fileUrls = List<String>.from(memoryData['fileUrls'] ?? []);

    final galleryItems = [
      ...photos.map((url) => {'type': 'image', 'url': url}),
      ...videos.map((url) => {'type': 'video', 'url': url}),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // GALLERY
                    if (galleryItems.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SizedBox(
                          height: 300,
                          width: double.infinity,
                          child: PageView.builder(
                            itemCount: galleryItems.length,
                            itemBuilder: (_, i) {
                              final item = galleryItems[i];
                              return Padding(
                                padding: const EdgeInsets.only(right: 0),
                                child: item['type'] == 'image'
                                    ? ClipRRect(
                                        child: Image.network(
                                          item['url'] as String,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      )
                                    : MyVideoPlayer(videoUrl: item['url'] as String),
                              );
                            },
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),

                    //AUDIO
                    if (audioUrls.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...audioUrls.map((url) => AudioPlayerWidget(audioUrl: url)).toList(),
                        ],
                      ),

                    //FILES
                    if (fileUrls.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          const Text("Files", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...fileUrls.map((url) => Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
                                  title: Text(url.split('/').last, overflow: TextOverflow.ellipsis),
                                  trailing: const Icon(Icons.download),
                                  onTap: () async {
                                    final uri = Uri.parse(url);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                ),
                              )),
                        ],
                      ),

                    const SizedBox(height: 16),

                    //DESCRIPTION
                    Text(description, style: const TextStyle(fontSize: 16)),

                    const SizedBox(height: 16),

                    //FOOTER: Created and Unlocked Date
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
            ),

            /// Likes
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('memories')
                  .doc(memoryId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final likedBy = List<String>.from(data['likedBy'] ?? []);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.favorite, color: Colors.red),
                    Text('${likedBy.length} likes'),
                  ],
                );
              },
            ),

            const Divider(height: 30),
            const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 10),

            SizedBox(
              height: 250,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('memories')
                    .doc(memoryId)
                    .collection('comments')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final comments = snapshot.data!.docs;
                  return ListView(
                    children: comments.map((doc) {
                      final data = doc.data()! as Map<String, dynamic>;
                      final commentText = data['text'];
                      final createdAt = (data['createdAt'] as Timestamp).toDate();
                      final userId = data['userId'];

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          final userData = snapshot.data!.data() as Map<String, dynamic>;
                          final username = userData['username'] ?? 'Anonymous';
                          final avatar = userData['profile_picture'] ?? 'https://www.gravatar.com/avatar/placeholder?d=mp';

                          return ListTile(
                            leading: CircleAvatar(backgroundImage: NetworkImage(avatar)),
                            title: Text(username),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(commentText),
                                Text(DateFormat('dd/MM/yyyy hh:mm a').format(createdAt),
                                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          );
                        },
                      );
                    }).toList(),
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
