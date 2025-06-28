import 'package:flutter/material.dart';

class CustomTabBar extends StatelessWidget {
  final TabController controller;

  const CustomTabBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: TabBar(
        controller: controller,
        tabs: const [
          Tab(text: 'Memories'),
          Tab(text: 'Shared with you'),
          Tab(text: 'Time Capsule'),
        ],
        indicatorColor: Colors.blue,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
      ),
    );
  }
}
