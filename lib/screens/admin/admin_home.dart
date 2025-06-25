// filepath: c:\FlutterDev\Memorime\TechTribe_MobileApp_Project\lib\admin_home.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../memory/memory_details_page.dart';
import 'reportedMemories.dart';
import '../../models/report.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;
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

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReports() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('reports')
              .orderBy('timestamp', descending: true)
              .limit(5)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data!.docs;

        if (reports.isEmpty) {
          return const Center(child: Text('No recent reports'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index].data() as Map<String, dynamic>;
            final status = report['status'] ?? 'pending';
            final reason = report['reason'] ?? '';
            final timestamp = (report['timestamp'] as Timestamp).toDate();

            return ListTile(
              leading: _getStatusIcon(status),
              title: Text(reason),
              subtitle: Text(
                DateFormat('MMM d, y HH:mm').format(timestamp),
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: _getStatusBadge(status),
            );
          },
        );
      },
    );
  }

  Widget _getStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'inReview':
        color = Colors.blue;
        break;
      case 'resolved':
        color = Colors.green;
        break;
      case 'dismissed':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 12)),
    );
  }

  Widget _getStatusIcon(String status) {
    IconData icon;
    Color color;

    switch (status) {
      case 'pending':
        icon = Icons.pending;
        color = Colors.orange;
        break;
      case 'inReview':
        icon = Icons.search;
        color = Colors.blue;
        break;
      case 'resolved':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'dismissed':
        icon = Icons.cancel;
        color = Colors.grey;
        break;
      default:
        icon = Icons.error;
        color = Colors.grey;
    }

    return Icon(icon, color: color);
  }

  Widget _buildDashboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reports').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data!.docs;
        int totalReports = reports.length;
        int pendingReports =
            reports
                .where(
                  (doc) =>
                      (doc.data() as Map<String, dynamic>)['status'] ==
                      'pending',
                )
                .length;
        int resolvedReports =
            reports
                .where(
                  (doc) =>
                      (doc.data() as Map<String, dynamic>)['status'] ==
                      'resolved',
                )
                .length;
        int inReviewReports =
            reports
                .where(
                  (doc) =>
                      (doc.data() as Map<String, dynamic>)['status'] ==
                      'inReview',
                )
                .length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome, Admin!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatCard(
                    'Total Reports',
                    totalReports.toString(),
                    Colors.purple,
                    Icons.report,
                  ),
                  _buildStatCard(
                    'Pending',
                    pendingReports.toString(),
                    Colors.orange,
                    Icons.pending,
                  ),
                  _buildStatCard(
                    'In Review',
                    inReviewReports.toString(),
                    Colors.blue,
                    Icons.search,
                  ),
                  _buildStatCard(
                    'Resolved',
                    resolvedReports.toString(),
                    Colors.green,
                    Icons.check_circle,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Recent Reports',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildRecentReports(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? 'Admin Dashboard' : 'Reported Memories',
        ),
        backgroundColor: Colors.blue,
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
