import 'package:flutter/material.dart';
import 'edit_profile.dart';
import 'achievements_page.dart';
import 'notification_settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _currentStatus = 'Available';
  bool _isLoading = false;
  Map<String, bool> _notificationSettings = {
    'newMessages': true,
    'friendRequests': true,
    'achievementUnlocked': true,
    'capsuleUnlocked': true,
    'appUpdates': false,
  };
  bool _isLoadingNotifications = false;

  final List<Map<String, dynamic>> _statusList = [
    {
      'id': 'available',
      'label': 'Available',
      'emoji': '🟢',
      'color': Colors.green,
    },
    {'id': 'busy', 'label': 'Busy', 'emoji': '🔴', 'color': Colors.red},
    {'id': 'away', 'label': 'Away', 'emoji': '😴', 'color': Colors.orange},
    {
      'id': 'meeting',
      'label': 'In a Meeting',
      'emoji': '💼',
      'color': Colors.blue,
    },
    {
      'id': 'focus',
      'label': 'Focus Mode',
      'emoji': '🎯',
      'color': Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _loadNotificationSettings();
  }

  Future<void> _loadStatus() async {
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

        if (mounted && doc.exists && doc.data()!.containsKey('status')) {
          setState(() {
            _currentStatus = doc.data()!['status'];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load status: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (!mounted) return;

    setState(() {
      _currentStatus = newStatus;
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'status': newStatus,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadNotificationSettings() async {
    if (!mounted) return;

    setState(() => _isLoadingNotifications = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (mounted && doc.exists && doc.data()!.containsKey('notifications')) {
          final notifications =
              doc.data()!['notifications'] as Map<String, dynamic>;
          setState(() {
            _notificationSettings = Map<String, bool>.from(notifications);
          });
        } else {
          // If no settings exist, save the defaults
          await _saveNotificationSettings();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notification settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingNotifications = false);
      }
    }
  }

  Future<void> _saveNotificationSettings() async {
    if (!mounted) return;

    setState(() => _isLoadingNotifications = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'notifications': _notificationSettings,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save notification settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingNotifications = false);
      }
    }
  }

  Future<void> _updateNotificationSetting(String key, bool value) async {
    setState(() {
      _notificationSettings[key] = value;
    });
    await _saveNotificationSettings();
  }

  // Logout function to sign out and navigate to login screen
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to login page and remove all previous routes
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: ${e.toString()}')),
        );
      }
    }
  }

  // Function to show delete account confirmation dialog
  Future<bool?> _showDeleteAccountDialog(BuildContext context) async {
    final TextEditingController confirmController = TextEditingController();
    final confirmationText = "delete my account";
    bool isConfirmationValid = false;

    // Update the UI when the text changes
    void validateConfirmation() {
      if (confirmController.text.trim().toLowerCase() == confirmationText) {
        isConfirmationValid = true;
      } else {
        isConfirmationValid = false;
      }
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            confirmController.addListener(() {
              setState(() {
                validateConfirmation();
              });
            });

            return AlertDialog(
              title: const Text(
                'Delete Account',
                style: TextStyle(
                  color: Color(0xFFF45B3B),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This action cannot be undone. All your data will be permanently deleted.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please type "delete my account" to confirm:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: confirmationText,
                      hintStyle: TextStyle(color: Colors.grey[400]),
                    ),
                    autofocus: true,
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed:
                      isConfirmationValid
                          ? () {
                            Navigator.of(dialogContext).pop(true);
                          }
                          : null,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor:
                        isConfirmationValid
                            ? const Color(0xFFF45B3B)
                            : Colors.grey[400],
                  ),
                  child: const Text('Delete Account'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Function to handle account deletion
  Future<void> _deleteAccount(BuildContext context) async {
    // Show confirmation dialog
    final bool? shouldDelete = await _showDeleteAccountDialog(context);

    // If not confirmed, do nothing
    if (shouldDelete != true) return;

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Delete user account
        await user.delete();

        // Navigate to login page
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your account has been deleted')),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'requires-recent-login') {
        errorMessage =
            'Please log out and log back in before deleting your account.';
      } else {
        errorMessage = 'Error deleting account: ${e.message}';
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Move status options to a separate method for better organization
  Map<String, dynamic> get currentStatus {
    return _statusList.firstWhere(
      (status) => status['id'] == _currentStatus,
      orElse: () => _statusList[0],
    );
  }

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Set your status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._statusList.map(
                        (status) => ListTile(
                          onTap: () {
                            _updateStatus(status['id']);
                            Navigator.pop(context);
                          },
                          leading: Text(
                            status['emoji'],
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            status['label'],
                            style: TextStyle(
                              color:
                                  _currentStatus == status['id']
                                      ? status['color']
                                      : Colors.black87,
                              fontWeight:
                                  _currentStatus == status['id']
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                          trailing:
                              _currentStatus == status['id']
                                  ? Icon(
                                    Icons.check_circle,
                                    color: status['color'],
                                  )
                                  : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notification Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoadingNotifications)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else ...[
                        _buildNotificationTile(
                          'New Messages',
                          'Get notified when you receive new messages',
                          'newMessages',
                          Icons.message,
                          Colors.blue,
                        ),
                        _buildNotificationTile(
                          'Friend Requests',
                          'Get notified about new friend requests',
                          'friendRequests',
                          Icons.person_add,
                          Colors.green,
                        ),
                        _buildNotificationTile(
                          'Achievements',
                          'Get notified when you unlock new achievements',
                          'achievementUnlocked',
                          Icons.emoji_events,
                          Colors.amber,
                        ),
                        _buildNotificationTile(
                          'Time Capsules',
                          'Get notified when your time capsules are unlocked',
                          'capsuleUnlocked',
                          Icons.lock_clock,
                          Colors.purple,
                        ),
                        _buildNotificationTile(
                          'App Updates',
                          'Get notified about new features and updates',
                          'appUpdates',
                          Icons.system_update,
                          Colors.grey,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildNotificationTile(
    String title,
    String subtitle,
    String settingKey,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
      ),
      trailing: Switch(
        value: _notificationSettings[settingKey] ?? false,
        onChanged: (value) => _updateNotificationSetting(settingKey, value),
        activeColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get current Firebase user
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'My Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 48), // for symmetry
                  ],
                ),
                const SizedBox(height: 24),

                // Profile Info
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[100],
                        backgroundImage: AssetImage(
                          'assets/images/default_profile_picture.jpg',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user?.displayName ?? 'User',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF3B5BFE),
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfilePage(),
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.edit,
                              color: Colors.grey,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Status Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Current Status',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666),
                      ),
                    ),
                    if (!_isLoading)
                      TextButton(
                        onPressed: _showStatusPicker,
                        child: const Text(
                          'Change',
                          style: TextStyle(
                            color: Color(0xFF3B5BFE),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  InkWell(
                    onTap: _showStatusPicker,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _statusList.firstWhere(
                              (s) => s['id'] == _currentStatus,
                              orElse: () => _statusList[0],
                            )['emoji'],
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _statusList.firstWhere(
                              (s) => s['id'] == _currentStatus,
                              orElse: () => _statusList[0],
                            )['label'],
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 32),

                // Dashboard Section
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 16),

                // Achievements
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AchievementsPage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD86B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              color: Color(0xFFFFD86B),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Achievements',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Notifications
                StreamBuilder<DocumentSnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .snapshots(),
                  builder: (context, snapshot) {
                    int enabledCount = 0;
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final notifications =
                          snapshot.data!.get('notifications')
                              as Map<String, dynamic>?;
                      if (notifications != null) {
                        enabledCount =
                            notifications.values.where((v) => v == true).length;
                      }
                    }

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const NotificationSettingsPage(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF3B5BFE,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.notifications_rounded,
                                  color: Color(0xFF3B5BFE),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Notifications',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 17,
                                      ),
                                    ),
                                    Text(
                                      '$enabledCount notifications enabled',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // My Account Section
                const Text(
                  'My Account',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 16),

                // Account Actions
                TextButton(
                  onPressed: () => _logout(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Color(0xFFF45B3B),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _deleteAccount(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  child: const Text(
                    'Delete Account',
                    style: TextStyle(
                      color: Color(0xFFF45B3B),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
