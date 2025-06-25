import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'reportedMemories.dart';


class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;
  int selectedOption = 0; // 0 = User List, 1 = Memory List
  DateTimeRange? _filterRange;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onFilterChanged(DateTimeRange? range) {
    setState(() {
      _filterRange = range;
    });
  }

  Widget _buildStatCard(String title, String count, IconData icon) {
    return Container(
      height: 120,
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Colors.purple),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildToggleButton() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleSegment("User List", 0),
            _buildToggleSegment("Memory List", 1),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSegment(String label, int index) {
    final isSelected = selectedOption == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedOption = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildUserTable() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('memories').get(),
      builder: (context, memorySnapshot) {
        if (!memorySnapshot.hasData) return const CircularProgressIndicator();
        final memories = memorySnapshot.data!.docs;

        // Count capsules per user
        Map<String, int> capsuleCounts = {};
        for (var memory in memories) {
          final ownerId = memory['ownerId'];
          capsuleCounts[ownerId] = (capsuleCounts[ownerId] ?? 0) + 1;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            final users = snapshot.data!.docs;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Register Date')),
                  DataColumn(label: Text('Created Capsules')),
                ],
                rows:
                    users.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final userId = doc.id;
                      final createdAt =
                          data['created_at'] != null
                              ? DateFormat('yyyy-MM-dd').format(
                                (data['created_at'] as Timestamp).toDate(),
                              )
                              : 'N/A';
                      final capsuleCount = capsuleCounts[userId] ?? 0;

                      return DataRow(
                        cells: [
                          DataCell(Text(data['username'] ?? 'N/A')),
                          DataCell(Text(data['email'] ?? 'N/A')),
                          DataCell(Text(createdAt)),
                          DataCell(Text(capsuleCount.toString())),
                        ],
                      );
                    }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMemoryTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('memories').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final memories = snapshot.data!.docs;

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('users').get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return const CircularProgressIndicator();
            final users = {
              for (var doc in userSnapshot.data!.docs)
                doc.id: doc.data() as Map<String, dynamic>,
            };

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Title')),
                  DataColumn(label: Text('Owner')),
                  DataColumn(label: Text('Created At')),
                  DataColumn(label: Text('Unlock Date')),
                  DataColumn(label: Text('Status')),
                ],
                rows:
                    memories.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final ownerName =
                          users[data['ownerId']]?['username'] ?? 'Unknown';

                      return DataRow(
                        cells: [
                          DataCell(Text(data['title'] ?? 'N/A')),
                          DataCell(Text(ownerName)),
                          DataCell(
                            Text(
                              data['createdAt'] != null
                                  ? DateFormat('yyyy-MM-dd').format(
                                    (data['createdAt'] as Timestamp).toDate(),
                                  )
                                  : 'N/A',
                            ),
                          ),
                          DataCell(
                            Text(
                              data['unlockDate'] != null
                                  ? DateFormat('yyyy-MM-dd').format(
                                    (data['unlockDate'] as Timestamp).toDate(),
                                  )
                                  : 'N/A',
                            ),
                          ),
                          DataCell(Text(data['status'] ?? 'N/A')),
                        ],
                      );
                    }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOptionContent() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
        child: Column(
          children: [
            selectedOption == 0 ? _buildUserTable() : _buildMemoryTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, usersSnapshot) {
        return StreamBuilder(
          stream:
              FirebaseFirestore.instance.collection('capsules').snapshots(),
          builder: (context, lockedSnapshot) {
            return StreamBuilder(
              stream:
                  FirebaseFirestore.instance.collection('memories').snapshots(),
              builder: (context, memoriesSnapshot) {
                return StreamBuilder(
                  stream:
                      FirebaseFirestore.instance
                          .collection('reports')
                          .snapshots(),
                  builder: (context, reportsSnapshot) {
                    if (!usersSnapshot.hasData ||
                        !lockedSnapshot.hasData ||
                        !memoriesSnapshot.hasData ||
                        !reportsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final totalUsers = usersSnapshot.data!.docs.length;
                    final lockedCapsules = lockedSnapshot.data!.docs.length;
                    final unlockedCapsules = memoriesSnapshot.data!.docs.length;
                    final totalReports = reportsSnapshot.data!.docs.length;

                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard(
                                'Users',
                                totalUsers.toString(),
                                Icons.people,
                              ),
                              _buildStatCard(
                                'Capsules',
                                lockedCapsules.toString(),
                                Icons.lock,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard(
                                'Memories',
                                unlockedCapsules.toString(),
                                Icons.lock_open,
                              ),
                              _buildStatCard(
                                'Reports',
                                totalReports.toString(),
                                Icons.report,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildToggleButton(),
                          const SizedBox(height: 12),
                          _buildOptionContent(),
                        ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFC17ACE), Color(0xFFDD98E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: Text(
              _selectedIndex == 0 ? 'Admin Dashboard' : 'Reported Memories',
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body:
          _selectedIndex == 0
              ? _buildDashboard()
              : ReportedMemoriesTab(
                filterRange: _filterRange,
                onFilterChanged: _onFilterChanged,
              ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Reported Memories',
          ),
        ],
      ),
    );
  }
} 