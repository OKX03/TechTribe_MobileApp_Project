import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../group/group_page.dart';
import '../../services/friend_service.dart';

class FriendsMainPage extends StatefulWidget {
  const FriendsMainPage({super.key});

  @override
  State<FriendsMainPage> createState() => _FriendsMainPageState();
}

class _FriendsMainPageState extends State<FriendsMainPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = "";
  late TabController _tabController;
  final _friendService = FriendService();

  User? get _me => _friendService.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ─── Fetch pending requests (where friendId == me) ───────────────
  Future<List<Map<String, String>>> fetchFriendRequests() async {
    return _friendService.fetchFriendRequests();
  }

  // ─── Fetch accepted friends (where ownerId == me) ────────────────
  Future<List<Map<String, dynamic>>> fetchFriendList() async {
    return _friendService.fetchFriendList();
  }

  // ─── Fetch "recommended" (everyone except me & anyone I've already touched) ───
  Future<List<Map<String, dynamic>>> fetchRecommendedFriends() async {
    return _friendService.fetchRecommendedFriends();
  }

  // ─── US014-01: Send Friend Request ────────────────────────────────
  Future<void> sendFriendRequest(String toUserId) async {
    await _friendService.sendFriendRequest(toUserId);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend request sent!')));
    }
  }

  // ─── US014-04: Accept Friend Request ──────────────────────────────
  Future<void> acceptFriendRequest(String fromUid) async {
    await _friendService.acceptFriendRequest(fromUid);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend request accepted!')));
    }
  }

  // ─── US014-04B: Reject Friend Request ─────────────────────────────
  Future<void> rejectFriendRequest(String fromUid) async {
    await _friendService.rejectFriendRequest(fromUid);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend request rejected.')));
      setState(() {});
    }
  }

  // ─── US014-03: Delete Friend (Unfriend) ───────────────────────────
  Future<void> deleteFriend(String friendUid) async {
    await _friendService.deleteFriend(friendUid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend removed successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {}, // Already on Friends page
              child: const Text(
                'Friends',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('|', style: TextStyle(fontSize: 20, color: Colors.grey)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const GroupMainPage()),
                );
              },
              child: const Text(
                'Groups',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              showSearch(
                context: context,
                delegate: FriendSearchDelegate(
                  firestore: FirebaseFirestore.instance,
                  currentUser: _me,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 16,
              ),
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'My Friends'),
                Tab(text: 'Received'),
                Tab(text: 'Sent'),
              ],
            ),
          ),

          // Friend Count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchFriendList(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.length ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'You have $count friends',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsListView(),
                _buildReceivedRequestsView(),
                _buildSentRequestsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsListView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchFriendList(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final friends = snapshot.data ?? [];

        if (friends.isEmpty) {
          return _buildEmptyState(
            "You haven't added any friends yet",
            Icons.people,
          );
        }

        final filteredFriends =
            friends
                .where(
                  (f) => f['username']!.toLowerCase().contains(_searchQuery),
                )
                .toList();

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            // Recommendations Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'People You May Know',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          // Refresh recommendations
                          setState(() {});
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Refresh'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchRecommendedFriends(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final recommendations = snapshot.data ?? [];
                      if (recommendations.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No recommendations available',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        );
                      }

                      return SizedBox(
                        height: 72,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: recommendations.length,
                          itemBuilder: (context, index) {
                            final recommendation = recommendations[index];
                            return Container(
                              width: 280,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 12),
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundImage: NetworkImage(
                                      recommendation['profile_picture']!,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          recommendation['username']!,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        recommendation['mutualFriends'] > 0
                                            ? Text(
                                              '${recommendation['mutualFriends']} mutual friends',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            )
                                            : Text(
                                              'Joined: ' +
                                                  (recommendation['createdAt']
                                                          is Timestamp
                                                      ? DateFormat.yMMMd().format(
                                                        (recommendation['createdAt']
                                                                as Timestamp)
                                                            .toDate(),
                                                      )
                                                      : 'Unknown'),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed:
                                        recommendation['isPending']
                                            ? null
                                            : () => sendFriendRequest(
                                              recommendation['uid']!,
                                            ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 0,
                                      ),
                                      minimumSize: const Size(0, 36),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Text(
                                      recommendation['isPending']
                                          ? 'Sent'
                                          : 'Add Friend',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Friends List Section
            const Text(
              'Your Friends',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ...filteredFriends
                .map((friend) => _buildFriendListTile(friend))
                .toList(),
          ],
        );
      },
    );
  }

  Widget _buildReceivedRequestsView() {
    return FutureBuilder<List<Map<String, String>>>(
      future: fetchFriendRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return _buildEmptyState(
            'No new friend requests',
            Icons.person_add_disabled,
          );
        }

        final filtered =
            requests
                .where(
                  (r) => r['username']!.toLowerCase().contains(_searchQuery),
                )
                .toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final request = filtered[index];
            return _buildRequestTile(
              request,
              onAccept: () => acceptFriendRequest(request['uid']!),
              onReject: () => rejectFriendRequest(request['uid']!),
            );
          },
        );
      },
    );
  }

  Widget _buildSentRequestsView() {
    final me = _me;
    if (me == null) {
      return const Center(child: Text('Not logged in'));
    }
    // 1. Get my friends
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchFriendList(),
      builder: (context, friendSnap) {
        final myFriends = friendSnap.data ?? [];
        final myFriendIds = myFriends.map((f) => f['uid'] as String).toSet();

        // 2. Get my pending sent requests
        return FutureBuilder<QuerySnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection('friendList')
                  .where('ownerId', isEqualTo: me.uid)
                  .where('status', isEqualTo: 'pending')
                  .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final requests = snapshot.data?.docs ?? [];
            // 3. Filter out requests where friendId is already a friend
            final filteredRequests =
                requests
                    .where(
                      (d) => !myFriendIds.contains(d['friendId'] as String),
                    )
                    .toList();
            if (filteredRequests.isEmpty) {
              return _buildEmptyState('No sent friend requests', Icons.outbox);
            }
            final friendIds =
                filteredRequests.map((d) => d['friendId'] as String).toList();
            return FutureBuilder<QuerySnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .where(FieldPath.documentId, whereIn: friendIds)
                      .get(),
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = userSnap.data?.docs ?? [];
                if (users.isEmpty) {
                  return _buildEmptyState(
                    'No sent friend requests',
                    Icons.outbox,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final data = users[index].data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(
                            data['profile_picture'] as String? ??
                                'https://via.placeholder.com/150',
                          ),
                        ),
                        title: Text(
                          data['username'] as String? ?? 'No Name',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        trailing: OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.hourglass_empty),
                          label: const Text('Pending'),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFriendListTile(Map<String, dynamic> friend) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage(friend['profile_picture']!),
        ),
        title: Text(
          friend['username']!,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          friend['since'] != null
              ? 'Added since ${DateFormat.yMMMd().add_jm().format(friend['since']!.toDate())}'
              : 'since unknown',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.black54),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('View Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'message',
                  child: Row(
                    children: [
                      Icon(Icons.message_outlined, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('Send Message'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('Block'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'unfriend',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Unfriend',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ],
                  ),
                ),
              ],
          onSelected: (value) {
            switch (value) {
              case 'unfriend':
                deleteFriend(friend['uid']!);
                break;
              // Implement other actions
            }
          },
        ),
      ),
    );
  }

  Widget _buildRequestTile(
    Map<String, String> request, {
    required VoidCallback onAccept,
    required VoidCallback onReject,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Profile picture
            CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(request['profile_picture']!),
            ),
            const SizedBox(width: 12),
            // Name, subtitle, and timestamp
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          request['username']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      // Timestamp (replace with your actual time logic)
                      Text(
                        '5 min ago',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Wants to be your Friend',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Accept button (filled)
                      ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          side: const BorderSide(color: Colors.black26),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Accept'),
                      ),
                      const SizedBox(width: 8),
                      // Decline button (outlined)
                      OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Colors.black26),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Decline'),
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
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class FriendSearchDelegate extends SearchDelegate {
  final FirebaseFirestore firestore;
  final User? currentUser;

  late final Future<Set<String>> _myFriendIdsFuture;
  late final Future<Set<String>> _myPendingRequestsFuture;

  FriendSearchDelegate({required this.firestore, required this.currentUser}) {
    _myFriendIdsFuture = _loadMyFriendIds();
    _myPendingRequestsFuture = _loadMyPendingRequests();
  }

  Future<Set<String>> _loadMyFriendIds() async {
    if (currentUser == null) return {};

    final uid = currentUser!.uid;
    // get accepted where I'm owner
    final snap1 =
        await firestore
            .collection('friendList')
            .where('ownerId', isEqualTo: uid)
            .where('status', isEqualTo: 'accepted')
            .get();
    // and where I'm friend
    final snap2 =
        await firestore
            .collection('friendList')
            .where('friendId', isEqualTo: uid)
            .where('status', isEqualTo: 'accepted')
            .get();

    final ids = <String>{};
    for (var d in snap1.docs) ids.add(d['friendId'] as String);
    for (var d in snap2.docs) ids.add(d['ownerId'] as String);
    return ids;
  }

  Future<Set<String>> _loadMyPendingRequests() async {
    if (currentUser == null) return {};
    final snap =
        await firestore
            .collection('friendList')
            .where('ownerId', isEqualTo: currentUser!.uid)
            .where('status', isEqualTo: 'pending')
            .get();
    return snap.docs.map((d) => d['friendId'] as String).toSet();
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context).copyWith(
    appBarTheme: AppBarTheme(backgroundColor: Colors.grey[50], elevation: 0),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: Colors.grey[400]),
      border: InputBorder.none,
    ),
  );

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Start typing to search users...',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<Set<String>>(
      future: _myFriendIdsFuture,
      builder: (ctx, snapIds) {
        final myFriends = snapIds.data ?? {};
        return FutureBuilder<Set<String>>(
          future: _myPendingRequestsFuture,
          builder: (ctx, snapPending) {
            final myPending = snapPending.data ?? {};
            return FutureBuilder<QuerySnapshot>(
              future: firestore.collection('users').limit(200).get(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs =
                    snap.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final username =
                          (data['username'] as String?)?.toLowerCase() ?? '';
                      return username.contains(query.toLowerCase());
                    }).toList();
                if (docs.isEmpty) {
                  return Center(child: Text('No users found'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data()! as Map<String, dynamic>;
                    final userId = docs[i].id;
                    if (userId == currentUser?.uid)
                      return const SizedBox.shrink();

                    final isFriend = myFriends.contains(userId);
                    final isPending = myPending.contains(userId);

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(
                            data['profile_picture'] as String? ??
                                'https://via.placeholder.com/150',
                          ),
                        ),
                        title: Text(
                          data['username'] as String? ?? 'No Name',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        trailing:
                            isFriend
                                ? ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.message),
                                  label: const Text('Message'),
                                )
                                : isPending
                                ? OutlinedButton.icon(
                                  onPressed: null,
                                  icon: const Icon(Icons.hourglass_empty),
                                  label: const Text('Pending'),
                                )
                                : ElevatedButton.icon(
                                  onPressed: () {
                                    firestore
                                        .collection('friendList')
                                        .add({
                                          'ownerId': currentUser!.uid,
                                          'friendId': userId,
                                          'status': 'pending',
                                          'since': FieldValue.serverTimestamp(),
                                        })
                                        .then(
                                          (_) => ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Friend request sent!',
                                              ),
                                            ),
                                          ),
                                        );
                                  },
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Add Friend'),
                                ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
