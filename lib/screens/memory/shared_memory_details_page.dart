import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'video_player.dart';
import 'audio_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SharedMemoryDetailPage extends StatefulWidget {
  final String memoryId;
  final Map<String, dynamic> memoryData;

  const SharedMemoryDetailPage({
    super.key,
    required this.memoryId,
    required this.memoryData,
  });

  @override
  State<SharedMemoryDetailPage> createState() => _SharedMemoryDetailPageState();
}

class _SharedMemoryDetailPageState extends State<SharedMemoryDetailPage> {
  bool isLiked = false;
  List<String> likedBy = [];
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    likedBy = List<String>.from(widget.memoryData['likedBy'] ?? []);
    isLiked = likedBy.contains(FirebaseAuth.instance.currentUser!.uid);
  }

  // Future<void> _toggleLike() async {
  //   final userId = FirebaseAuth.instance.currentUser!.uid;
  //   final docRef = FirebaseFirestore.instance.collection('memories').doc(widget.memoryId);

  //   setState(() {
  //     isLiked = !isLiked;
  //     isLiked ? likedBy.add(userId) : likedBy.remove(userId);
  //   });

  //   await docRef.update({'likedBy': likedBy});
  // }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser!;
    final commentRef = FirebaseFirestore.instance
        .collection('memories')
        .doc(widget.memoryId)
        .collection('comments')
        .doc();

    await commentRef.set({
      'text': text,
      'userId': user.uid,
      'createdAt': Timestamp.now(),
    });

    _commentController.clear();
  }

  Future<void> _reportMemory() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('reports').add({
      'memoryId': widget.memoryId,
      'reportedBy': userId,
      'timestamp': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Memory reported.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final title = widget.memoryData['title'] ?? 'Untitled';
    final description = widget.memoryData['description'] ?? '';
    final createdAt = (widget.memoryData['createdAt'] as Timestamp).toDate();
    final unlockedAt = (widget.memoryData['unlockedAt'] as Timestamp).toDate();
    final photos = List<String>.from(widget.memoryData['photoUrls'] ?? []);
    final videos = List<String>.from(widget.memoryData['videoUrls'] ?? []);
    final audioUrls = List<String>.from(widget.memoryData['audioUrls'] ?? []);
    final fileUrls = List<String>.from(widget.memoryData['fileUrls'] ?? []);
    final likedBy = List<String>.from(widget.memoryData['likedBy'] ?? []);
    
    // final isLiked = likedBy.contains(userId);

    // Future<void> _toggleLike() async {
    //   final docRef = FirebaseFirestore.instance.collection('memories').doc(widget.memoryId);
    //   if (isLiked) {
    //     await docRef.update({
    //       'likedBy': FieldValue.arrayRemove([userId])
    //     });
    //   } else {
    //     await docRef.update({
    //       'likedBy': FieldValue.arrayUnion([userId])
    //     });
    //   }
    // }

    final galleryItems = [
      ...photos.map((url) => {'type': 'image', 'url': url}),
      ...videos.map((url) => {'type': 'video', 'url': url}),
    ];

    // return Scaffold(
    //   appBar: AppBar(
    //     title: Text(title, style: const TextStyle(color: Colors.white)),
    //     flexibleSpace: Container(
    //       decoration: const BoxDecoration(
    //         gradient: LinearGradient(
    //           colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
    //           begin: Alignment.topLeft,
    //           end: Alignment.bottomRight,
    //         ),
    //       ),
    //     ),
    //     backgroundColor: Colors.transparent,
    //     elevation: 0,
    //     iconTheme: const IconThemeData(color: Colors.white),
    //   ),
    //   body: SingleChildScrollView(
    //     padding: const EdgeInsets.all(12),
    //     child: Card(
    //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    //       elevation: 3,
    //       margin: const EdgeInsets.only(bottom: 20),
    //       child: Padding(
    //         padding: const EdgeInsets.all(16),
    //         child: Column(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             FutureBuilder<DocumentSnapshot>(
    //               future: FirebaseFirestore.instance
    //                   .collection('users')
    //                   .doc(widget.memoryData['sourceOwnerId'] ?? widget.memoryData['ownerId'])
    //                   .get(),
    //               builder: (context, snapshot) {
    //                 if (!snapshot.hasData) {
    //                   return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
    //                 }

    //                 final data = snapshot.data!.data() as Map<String, dynamic>?;
    //                 final profilePic = data?['profileImage'] ??
    //                     'https://www.gravatar.com/avatar/placeholder?d=mp';
    //                 final displayName = data?['displayName'] ?? 'Unknown';

    //                 return Row(
    //                   children: [
    //                     CircleAvatar(backgroundImage: NetworkImage(profilePic), radius: 20),
    //                     const SizedBox(width: 10),
    //                     Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
    //                   ],
    //                 );
    //               },
    //             ),

    //             const SizedBox(height: 16),
    //             // 🖼️ GALLERY
    //             if (galleryItems.isNotEmpty)
    //               Padding(
    //                 padding: const EdgeInsets.only(bottom: 16),
    //                 child: SizedBox(
    //                   height: 300,
    //                   width: double.infinity,
    //                   child: PageView.builder(
    //                     itemCount: galleryItems.length,
    //                     itemBuilder: (_, i) {
    //                       final item = galleryItems[i];
    //                       return Padding(
    //                         padding: const EdgeInsets.only(right: 8),
    //                         child: item['type'] == 'image'
    //                             ? ClipRRect(
    //                                 borderRadius: BorderRadius.circular(10),
    //                                 child: Image.network(
    //                                   item['url'] as String,
    //                                   fit: BoxFit.cover,
    //                                   width: double.infinity,
    //                                 ),
    //                               )
    //                             : MyVideoPlayer(videoUrl: item['url'] as String),
    //                       );
    //                     },
    //                   ),
    //                 ),
    //               ),

    //             const SizedBox(height: 10),

    //             // 🎧 AUDIO
    //             if (audioUrls.isNotEmpty)
    //               Column(
    //                 crossAxisAlignment: CrossAxisAlignment.start,
    //                 children: [
    //                   ...audioUrls.map((url) => AudioPlayerWidget(audioUrl: url)).toList(),
    //                 ],
    //               ),

    //             // 📁 FILES
    //             if (fileUrls.isNotEmpty)
    //               Column(
    //                 crossAxisAlignment: CrossAxisAlignment.start,
    //                 children: [
    //                   const SizedBox(height: 20),
    //                   const Text("Files", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    //                   const SizedBox(height: 8),
    //                   ...fileUrls.map((url) => Card(
    //                         margin: const EdgeInsets.symmetric(vertical: 6),
    //                         child: ListTile(
    //                           leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
    //                           title: Text(url.split('/').last, overflow: TextOverflow.ellipsis),
    //                           trailing: const Icon(Icons.download),
    //                           onTap: () async {
    //                             final uri = Uri.parse(url);
    //                             if (await canLaunchUrl(uri)) {
    //                               await launchUrl(uri, mode: LaunchMode.externalApplication);
    //                             }
    //                           },
    //                         ),
    //                       )),
    //                 ],
    //               ),

    //             const SizedBox(height: 16),

    //             // 📝 DESCRIPTION
    //             Text(description, style: const TextStyle(fontSize: 16)),

    //             const SizedBox(height: 16),

    //             // 📆 FOOTER: Created and Unlocked Date
    //             Row(
    //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //               children: [
    //                 Text(
    //                   "Created: ${DateFormat('dd/MM/yyyy').format(createdAt)}",
    //                   style: TextStyle(fontSize: 12, color: Colors.blue.shade300),
    //                 ),
    //                 Text(
    //                   "Unlocked: ${DateFormat('dd/MM/yyyy').format(unlockedAt)}",
    //                   style: TextStyle(fontSize: 12, color: Colors.blue.shade300),
    //                 ),
    //               ],
    //             ),
    //              Row(
    //               children: [
    //                 IconButton(
    //                   icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.red),
    //                   onPressed: _toggleLike,
    //                 ),
    //                 Text('${likedBy.length} likes'),
    //                 const Spacer(),
    //                 IconButton(
    //                   icon: const Icon(Icons.report),
    //                   tooltip: "Report memory",
    //                   onPressed: _reportMemory,
    //                 ),
    //               ],
    //             ),

    //             const Divider(height: 30),

    //             const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold)),
    //             const SizedBox(height: 10),

    //             StreamBuilder<QuerySnapshot>(
    //               stream: FirebaseFirestore.instance
    //                   .collection('memories')
    //                   .doc(widget.memoryId)
    //                   .collection('comments')
    //                   .orderBy('createdAt', descending: true)
    //                   .snapshots(),
    //               builder: (context, commentSnapshot) {
    //                 if (!commentSnapshot.hasData) return const CircularProgressIndicator();

    //                 final comments = commentSnapshot.data!.docs;

    //                 return Column(
    //                   children: comments.map((doc) {
    //                     final data = doc.data()! as Map<String, dynamic>;
    //                     final commentText = data['text'];
    //                     final createdAt = (data['createdAt'] as Timestamp).toDate();
    //                     return ListTile(
    //                       title: Text(commentText),
    //                       subtitle: Text(DateFormat('dd/MM/yyyy hh:mm a').format(createdAt)),
    //                     );
    //                   }).toList(),
    //                 );
    //               },
    //             ),

    //             const SizedBox(height: 10),
    //             TextField(
    //               controller: _commentController,
    //               decoration: InputDecoration(
    //                 hintText: "Write a comment...",
    //                 suffixIcon: IconButton(
    //                   icon: const Icon(Icons.send),
    //                   onPressed: _submitComment,
    //                 ),
    //               ),
    //             ),
    //           ],
    //         ),
    //       ),
    //     ),
    //   ),
    // );
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
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.memoryData['ownerId'])
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final userData = snapshot.data!.data() as Map<String, dynamic>;
                        final profilePic = userData['profile_picture'] ?? 'https://www.gravatar.com/avatar/placeholder?d=mp';
                        final username = userData['username'] ?? 'Unknown';
                        return Row(
                          children: [
                            CircleAvatar(backgroundImage: NetworkImage(profilePic), radius: 20),
                            const SizedBox(width: 10),
                            Text(username, style: const TextStyle(fontWeight: FontWeight.bold))
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 5),
                    if (galleryItems.isNotEmpty)
                      SizedBox(
                        height: 300,
                        child: PageView.builder(
                          itemCount: galleryItems.length,
                          itemBuilder: (_, i) {
                            final item = galleryItems[i];
                            return Padding(
                              padding: const EdgeInsets.only(right: 0),
                              child: item['type'] == 'image'
                                  ? ClipRRect(
                                      // borderRadius: BorderRadius.circular(10),
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
                    if (audioUrls.isNotEmpty)
                      ...audioUrls.map((url) => AudioPlayerWidget(audioUrl: url)).toList(),
                    if (fileUrls.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          const Text("Files", style: TextStyle(fontWeight: FontWeight.bold)),
                          ...fileUrls.map((url) => ListTile(
                                leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
                                title: Text(url.split('/').last, overflow: TextOverflow.ellipsis),
                                trailing: const Icon(Icons.download),
                                onTap: () async {
                                  final uri = Uri.parse(url);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                              ))
                        ],
                      ),
                    const SizedBox(height: 10),
                    Text(description, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),

                    //Created and Unlocked Date
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

            // Buttons
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('memories')
                  .doc(widget.memoryId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final likedBy = List<String>.from(data['likedBy'] ?? []);
                final isLiked = likedBy.contains(userId);

                return Row(
                  children: [
                    IconButton(
                      icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                          color: Colors.red),
                      onPressed: () async {
                        final ref = FirebaseFirestore.instance
                            .collection('memories')
                            .doc(widget.memoryId);
                        if (isLiked) {
                          await ref.update({
                            'likedBy': FieldValue.arrayRemove([userId])
                          });
                        } else {
                          await ref.update({
                            'likedBy': FieldValue.arrayUnion([userId])
                          });
                        }
                      },
                    ),
                    Text('${likedBy.length} likes'),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.report, color: Colors.red),
                      onPressed: _reportMemory,
                    )
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
                    .doc(widget.memoryId)
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

            const SizedBox(height: 10),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: "Write a comment...",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _submitComment,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}