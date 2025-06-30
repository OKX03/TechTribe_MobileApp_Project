import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _isLoading = false;
  Map<String, bool> _settings = {};

  final List<Map<String, dynamic>> _notificationTypes = [
    {
      'category': 'Social',
      'items': [
        {
          'key': 'newMessages',
          'title': 'Messages',
          'subtitle': 'When you receive new messages',
          'icon': Icons.message_rounded,
          'color': Colors.blue,
        },
        {
          'key': 'friendRequests',
          'title': 'Friend Requests',
          'subtitle': 'When someone sends you a friend request',
          'icon': Icons.person_add_rounded,
          'color': Colors.green,
        },
        {
          'key': 'mentions',
          'title': 'Mentions',
          'subtitle': 'When someone mentions you',
          'icon': Icons.alternate_email_rounded,
          'color': Colors.orange,
        },
      ],
    },
    {
      'category': 'Content',
      'items': [
        {
          'key': 'capsuleUnlocked',
          'title': 'Time Capsules',
          'subtitle': 'When your time capsules are ready to open',
          'icon': Icons.lock_clock,
          'color': Colors.purple,
        },
        {
          'key': 'memories',
          'title': 'Memories',
          'subtitle': 'Daily memories from the past',
          'icon': Icons.photo_album_rounded,
          'color': Colors.pink,
        },
        {
          'key': 'achievementUnlocked',
          'title': 'Achievements',
          'subtitle': 'When you earn new achievements',
          'icon': Icons.emoji_events_rounded,
          'color': Colors.amber,
        },
      ],
    },
    {
      'category': 'System',
      'items': [
        {
          'key': 'appUpdates',
          'title': 'App Updates',
          'subtitle': 'New features and improvements',
          'icon': Icons.system_update_rounded,
          'color': Colors.indigo,
        },
        {
          'key': 'security',
          'title': 'Security Alerts',
          'subtitle': 'Important security notifications',
          'icon': Icons.security_rounded,
          'color': Colors.red,
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (mounted && doc.exists && doc.data()!.containsKey('notifications')) {
          setState(() {
            _settings = Map<String, bool>.from(
              doc.data()!['notifications'] as Map<String, dynamic>,
            );
          });
        } else {
          // Initialize default settings
          _settings = {
            'newMessages': true,
            'friendRequests': true,
            'mentions': true,
            'capsuleUnlocked': true,
            'memories': true,
            'achievementUnlocked': true,
            'appUpdates': false,
            'security': true,
          };
          await _saveSettings();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'notifications': _settings,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleSetting(String key) async {
    setState(() {
      _settings[key] = !(_settings[key] ?? false);
    });
    await _saveSettings();
  }

  Future<void> _toggleCategory(String category, bool value) async {
    final categoryItems =
        _notificationTypes.firstWhere(
              (type) => type['category'] == category,
            )['items']
            as List;

    setState(() {
      for (final item in categoryItems) {
        _settings[item['key']] = value;
      }
    });
    await _saveSettings();
  }

  bool _isCategoryEnabled(String category) {
    final categoryItems =
        _notificationTypes.firstWhere(
              (type) => type['category'] == category,
            )['items']
            as List;
    return categoryItems.every((item) => _settings[item['key']] ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ..._notificationTypes.map((type) => _buildCategory(type)),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildCategory(Map<String, dynamic> category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category['category'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _isCategoryEnabled(category['category']),
                  onChanged:
                      (value) => _toggleCategory(category['category'], value),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...category['items'].map<Widget>(
            (item) => _buildNotificationTile(item),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: item['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item['icon'], color: item['color']),
        ),
        title: Text(
          item['title'],
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          item['subtitle'],
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: Switch(
          value: _settings[item['key']] ?? false,
          onChanged: (value) => _toggleSetting(item['key']),
          activeColor: item['color'],
        ),
      ),
    );
  }
}
