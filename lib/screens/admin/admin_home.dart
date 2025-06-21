// filepath: c:\FlutterDev\Memorime\TechTribe_MobileApp_Project\lib\admin_home.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../memory/memory_details_page.dart';
import 'reportedMemories.dart'; // Add this import

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

  Widget _buildDashboard() {
    return const Center(
      child: Text(
        'Welcome, Admin!',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Admin Dashboard' : 'Reported Memories'),
        backgroundColor: Colors.blue,
      ),
      body: _selectedIndex == 0
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