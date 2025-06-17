// filepath: c:\FlutterDev\Memorime\TechTribe_MobileApp_Project\lib\admin_home.dart
import 'package:flutter/material.dart';
import 'timelineView.dart';



class TimelineMainPage extends StatelessWidget {
  const TimelineMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,  // Add this line to remove back arrow
        title: Text('Timeline',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),),
        backgroundColor: Colors.blue,

      ),
      body: const TimelineView(),
      
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
                  onTap: (){
                    
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.timeline, color: Colors.blue),
                      Text(
                        'Timeline',
                        style: TextStyle(color: Colors.blue, fontSize: 14),
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