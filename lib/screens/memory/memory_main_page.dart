import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:memorime_v1/screens/memory/shared_memory.dart';
import 'package:memorime_v1/screens/memory/memories_tab.dart';
import 'package:memorime_v1/screens/memory/time_capsule_tab.dart';
import '../user/profile.dart';


class MemoryMainPage extends StatefulWidget {
  const MemoryMainPage({super.key});

  @override
  State<MemoryMainPage> createState() => _MemoryMainPageState();
}

class _MemoryMainPageState extends State<MemoryMainPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      
      // Replacing AppBar with TabBar
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 8),
            color: Colors.white,
            child: TabBar(
              //isScrollable: true,
              controller: _tabController,
              indicatorColor: Colors.blue,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Memories'),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Shared with you'),
                  ),
                ),
                Tab(text: 'Time Capsule'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                MemoriesTab(),
                SharedWithYouTab(),
                TimeCapsuleTab(),
              ],
            ),
          ),
        ],
      ),
      
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
                      Icon(Icons.home, color: Colors.blueGrey),
                      Text(
                        'Home',
                        style: TextStyle(color: Colors.blueGrey, fontSize: 14),
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
                  onTap: (){
                    Navigator.pushNamed(context, '/memory');
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.photo_album, color: Colors.blue),
                      Text(
                        'Memory',
                        style: TextStyle(color: Colors.blue, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: (){
                    Navigator.pushReplacementNamed(context, '/timeline');
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
