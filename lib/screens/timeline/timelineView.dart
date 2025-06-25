import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../services/memory_service.dart';
import '../memory/memory_details_page.dart';

class TimelineView extends StatefulWidget {
  const TimelineView({Key? key}) : super(key: key);

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  final MemoryService _memoryService = MemoryService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _sortByUnlockDate = true;
  String? _selectedBranchId;

  // Media URL lists
  final List<String> _photoUrls = [];
  final List<String> _videoUrls = [];
  final List<String> _audioUrls = [];
  final List<String> _fileUrls = [];

  @override
  void initState() {
    super.initState();
    _clearMediaUrls();
  }

  void _clearMediaUrls() {
    _photoUrls.clear();
    _videoUrls.clear();
    _audioUrls.clear();
    _fileUrls.clear();
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy').format(date);
  }

  Future<String?> _uploadFile(File file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  Future<void> _pickAndUploadImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isEmpty) return;

      List<String> urls = [];
      for (var image in images) {
        final file = File(image.path);
        final fileName =
            DateTime.now().millisecondsSinceEpoch.toString() + '_' + image.name;
        final url = await _uploadFile(file, 'branch_photos/$fileName');
        if (url != null) urls.add(url);
      }

      setState(() {
        _photoUrls.addAll(urls);
      });
    } catch (e) {
      print('Error picking images: $e');
    }
  }

  Future<void> _pickAndUploadVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );
      if (video == null) return;

      final file = File(video.path);
      final fileName =
          DateTime.now().millisecondsSinceEpoch.toString() + '_' + video.name;
      final url = await _uploadFile(file, 'branch_videos/$fileName');

      if (url != null) {
        setState(() {
          _videoUrls.add(url);
        });
      }
    } catch (e) {
      print('Error picking video: $e');
    }
  }

  Future<void> _pickAndUploadAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      final fileName =
          DateTime.now().millisecondsSinceEpoch.toString() +
          '_' +
          result.files.first.name;
      final url = await _uploadFile(file, 'branch_audio/$fileName');

      if (url != null) {
        setState(() {
          _audioUrls.add(url);
        });
      }
    } catch (e) {
      print('Error picking audio: $e');
    }
  }

  Future<void> _pickAndUploadFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result == null || result.files.isEmpty) return;

      List<String> urls = [];
      for (var file in result.files) {
        if (file.path == null) continue;
        final fileName =
            DateTime.now().millisecondsSinceEpoch.toString() + '_' + file.name;
        final url = await _uploadFile(
          File(file.path!),
          'branch_files/$fileName',
        );
        if (url != null) urls.add(url);
      }

      setState(() {
        _fileUrls.addAll(urls);
      });
    } catch (e) {
      print('Error picking files: $e');
    }
  }

  Future<void> _showBranchCreationDialog(
    BuildContext context,
    Map<String, dynamic> parentMemory,
  ) async {
    // Clear any previous media URLs
    _clearMediaUrls();

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String privacy = 'Private';
    DateTime? unlockDate = DateTime.now();

    return showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Create Branch',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2196F3),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Title Field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Text(
                                    'Title',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    ' *',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: titleController,
                                decoration: InputDecoration(
                                  hintText: 'Enter branch title',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Add Media Section
                          ExpansionTile(
                            title: const Text(
                              'Add Media',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: const Text(
                              'Make your branch more memorable with photos, videos, and files',
                              style: TextStyle(fontSize: 14),
                            ),
                            leading: const Icon(Icons.photo_library),
                            children: [
                              Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.photo_camera),
                                    title: const Text('Add Photos'),
                                    subtitle:
                                        _photoUrls.isNotEmpty
                                            ? Text(
                                              '${_photoUrls.length} photos selected',
                                            )
                                            : null,
                                    onTap: () async {
                                      await _pickAndUploadImages();
                                      setState(() {});
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.videocam),
                                    title: const Text('Add Videos'),
                                    subtitle:
                                        _videoUrls.isNotEmpty
                                            ? Text(
                                              '${_videoUrls.length} videos selected',
                                            )
                                            : null,
                                    onTap: () async {
                                      await _pickAndUploadVideo();
                                      setState(() {});
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.mic),
                                    title: const Text('Add Audio'),
                                    subtitle:
                                        _audioUrls.isNotEmpty
                                            ? Text(
                                              '${_audioUrls.length} audio files selected',
                                            )
                                            : null,
                                    onTap: () async {
                                      await _pickAndUploadAudio();
                                      setState(() {});
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.attach_file),
                                    title: const Text('Add Files'),
                                    subtitle:
                                        _fileUrls.isNotEmpty
                                            ? Text(
                                              '${_fileUrls.length} files selected',
                                            )
                                            : null,
                                    onTap: () async {
                                      await _pickAndUploadFiles();
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Description Field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Text(
                                    'Description',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    ' *',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: descriptionController,
                                maxLines: 3,
                                maxLength: 500,
                                decoration: InputDecoration(
                                  hintText: 'Enter branch description',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Unlock Date
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Unlock Date',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: unlockDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    unlockDate = picked;
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today),
                                      const SizedBox(width: 8),
                                      Text(
                                        unlockDate != null
                                            ? DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(unlockDate!)
                                            : 'Select Date',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Privacy Setting
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Privacy',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: privacy,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Private',
                                    child: Text('Private'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Friends',
                                    child: Text('Friends'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Public',
                                    child: Text('Public'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    privacy = value;
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Create Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2196F3),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                if (titleController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a title'),
                                    ),
                                  );
                                  return;
                                }

                                if (descriptionController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter a description',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  final userId =
                                      FirebaseAuth.instance.currentUser?.uid;
                                  if (userId == null) return;

                                  await _memoryService.createBranch(
                                    parentMemoryId: parentMemory['id'],
                                    title: titleController.text,
                                    description: descriptionController.text,
                                    ownerId: userId,
                                    photoUrls: _photoUrls,
                                    videoUrls: _videoUrls,
                                    audioUrls: _audioUrls,
                                    fileUrls: _fileUrls,
                                    privacy: privacy,
                                    unlockDate: unlockDate ?? DateTime.now(),
                                  );

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Branch created successfully!',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error creating branch: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text(
                                'Create Branch',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    String memoryId,
    bool isBranch,
  ) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isBranch ? 'Delete Branch?' : 'Delete Memory?'),
            content: Text(
              isBranch
                  ? 'This will delete this branch and all its sub-branches. This action cannot be undone.'
                  : 'Are you sure you want to delete this memory? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () async {
                  try {
                    if (isBranch) {
                      await _memoryService.deleteBranch(memoryId);
                    } else {
                      await _memoryService.deleteMemory(memoryId);
                    }
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isBranch
                                ? 'Branch deleted successfully'
                                : 'Memory deleted successfully',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting: $e')),
                      );
                    }
                  }
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    Map<String, dynamic> memory,
    String memoryId,
  ) async {
    final titleController = TextEditingController(text: memory['title']);
    final descriptionController = TextEditingController(
      text: memory['description'],
    );
    String privacy = memory['privacy'] ?? 'Private';
    DateTime? unlockDate = (memory['unlockDate'] as Timestamp).toDate();

    // Initialize media URLs from memory
    _photoUrls.clear();
    _videoUrls.clear();
    _audioUrls.clear();
    _fileUrls.clear();

    _photoUrls.addAll(List<String>.from(memory['photoUrls'] ?? []));
    _videoUrls.addAll(List<String>.from(memory['videoUrls'] ?? []));
    _audioUrls.addAll(List<String>.from(memory['audioUrls'] ?? []));
    _fileUrls.addAll(List<String>.from(memory['fileUrls'] ?? []));

    return showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Edit Branch',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2196F3),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Title Field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Text(
                                    'Title',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    ' *',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: titleController,
                                decoration: InputDecoration(
                                  hintText: 'Enter branch title',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Add Media Section
                          ExpansionTile(
                            title: const Text(
                              'Add Media',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: const Text(
                              'Make your branch more memorable with photos, videos, and files',
                              style: TextStyle(fontSize: 14),
                            ),
                            leading: const Icon(Icons.photo_library),
                            children: [
                              Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.photo_camera),
                                    title: const Text('Add Photos'),
                                    subtitle:
                                        _photoUrls.isNotEmpty
                                            ? Text(
                                              '${_photoUrls.length} photos selected',
                                            )
                                            : null,
                                    trailing:
                                        _photoUrls.isNotEmpty
                                            ? IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                setState(() {
                                                  _photoUrls.clear();
                                                });
                                              },
                                            )
                                            : null,
                                    onTap: () async {
                                      await _pickAndUploadImages();
                                      setState(() {});
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.videocam),
                                    title: const Text('Add Videos'),
                                    subtitle:
                                        _videoUrls.isNotEmpty
                                            ? Text(
                                              '${_videoUrls.length} videos selected',
                                            )
                                            : null,
                                    trailing:
                                        _videoUrls.isNotEmpty
                                            ? IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                setState(() {
                                                  _videoUrls.clear();
                                                });
                                              },
                                            )
                                            : null,
                                    onTap: () async {
                                      await _pickAndUploadVideo();
                                      setState(() {});
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.mic),
                                    title: const Text('Add Audio'),
                                    subtitle:
                                        _audioUrls.isNotEmpty
                                            ? Text(
                                              '${_audioUrls.length} audio files selected',
                                            )
                                            : null,
                                    trailing:
                                        _audioUrls.isNotEmpty
                                            ? IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                setState(() {
                                                  _audioUrls.clear();
                                                });
                                              },
                                            )
                                            : null,
                                    onTap: () async {
                                      await _pickAndUploadAudio();
                                      setState(() {});
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.attach_file),
                                    title: const Text('Add Files'),
                                    subtitle:
                                        _fileUrls.isNotEmpty
                                            ? Text(
                                              '${_fileUrls.length} files selected',
                                            )
                                            : null,
                                    trailing:
                                        _fileUrls.isNotEmpty
                                            ? IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                setState(() {
                                                  _fileUrls.clear();
                                                });
                                              },
                                            )
                                            : null,
                                    onTap: () async {
                                      await _pickAndUploadFiles();
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Description Field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Text(
                                    'Description',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    ' *',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: descriptionController,
                                maxLines: 3,
                                maxLength: 500,
                                decoration: InputDecoration(
                                  hintText: 'Enter branch description',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Unlock Date
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Unlock Date',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: unlockDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      unlockDate = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today),
                                      const SizedBox(width: 8),
                                      Text(
                                        unlockDate != null
                                            ? DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(unlockDate!)
                                            : 'Select Date',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Privacy Setting
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Privacy',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: privacy,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Private',
                                    child: Text('Private'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Friends',
                                    child: Text('Friends'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Public',
                                    child: Text('Public'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      privacy = value;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2196F3),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                if (titleController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a title'),
                                    ),
                                  );
                                  return;
                                }

                                if (descriptionController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter a description',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  await FirebaseFirestore.instance
                                      .collection('memories')
                                      .doc(memoryId)
                                      .update({
                                        'title': titleController.text,
                                        'description':
                                            descriptionController.text,
                                        'privacy': privacy,
                                        'unlockDate': Timestamp.fromDate(
                                          unlockDate ?? DateTime.now(),
                                        ),
                                        'photoUrls': _photoUrls,
                                        'videoUrls': _videoUrls,
                                        'audioUrls': _audioUrls,
                                        'fileUrls': _fileUrls,
                                      });

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Branch updated successfully!',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error updating branch: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  void _showMemoryOptions(
    BuildContext context,
    Map<String, dynamic> memory,
    String memoryId,
  ) {
    final isBranch = memory['isBranch'] ?? false;

    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(context, memory, memoryId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmationDialog(context, memoryId, isBranch);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildMemoryContent(Map<String, dynamic> memory) {
    if (memory['type'] == 'image' && memory['mediaUrl'] != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          memory['mediaUrl'],
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Icon(Icons.error),
            );
          },
        ),
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const Center(child: Text('Please login'));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: _memoryService.getMyMemories(userId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return Container();

                      final memories = snapshot.data?.docs ?? [];
                      final mainMemories =
                          memories.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return !(data['isBranch'] ?? false);
                          }).toList();

                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFF2196F3)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: DropdownButton<String>(
                          value: _selectedBranchId,
                          hint: const Text(
                            'All Branches',
                            style: TextStyle(
                              color: Color(0xFF2196F3),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: const TextStyle(
                            color: Color(0xFF2196F3),
                            fontWeight: FontWeight.w500,
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF2196F3),
                          ),
                          dropdownColor: Colors.white,
                          underline: Container(),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                'All Branches',
                                style: TextStyle(
                                  color: Color(0xFF2196F3),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            ...mainMemories.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(
                                  data['title'] ?? 'Untitled',
                                  style: const TextStyle(
                                    color: Color(0xFF2196F3),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedBranchId = value);
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF2196F3)),
                    ),
                    child: PopupMenuButton(
                      icon: const Icon(Icons.sort, color: Color(0xFF2196F3)),
                      position: PopupMenuPosition.under,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      itemBuilder:
                          (context) => [
                            PopupMenuItem(
                              child: const Text(
                                'Sort by Created',
                                style: TextStyle(
                                  color: Color(0xFF2196F3),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onTap:
                                  () =>
                                      setState(() => _sortByUnlockDate = false),
                            ),
                            PopupMenuItem(
                              child: const Text(
                                'Sort by Unlocked',
                                style: TextStyle(
                                  color: Color(0xFF2196F3),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onTap:
                                  () =>
                                      setState(() => _sortByUnlockDate = true),
                            ),
                          ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _memoryService.getMyMemories(userId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final memories = snapshot.data?.docs ?? [];
              if (memories.isEmpty) {
                return const Center(child: Text('No memories yet!'));
              }

              // Build a map of parentId -> List of branches
              final Map<String, List<QueryDocumentSnapshot>> branchMap = {};
              final List<QueryDocumentSnapshot> mainMemories = [];
              for (var doc in memories) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['isBranch'] == true &&
                    data['parentMemoryId'] != null) {
                  if (_selectedBranchId == null ||
                      data['parentMemoryId'] == _selectedBranchId) {
                    branchMap
                        .putIfAbsent(data['parentMemoryId'], () => [])
                        .add(doc);
                  }
                } else if (_selectedBranchId == null ||
                    doc.id == _selectedBranchId) {
                  mainMemories.add(doc);
                }
              }

              // Helper to recursively build widgets for a memory and its branches
              List<Widget> buildMemoryWithBranches(
                QueryDocumentSnapshot doc,
                int branchLevel,
              ) {
                final memory = doc.data() as Map<String, dynamic>;
                final memoryId = doc.id;
                final date =
                    _sortByUnlockDate
                        ? (memory['unlockedAt'] as Timestamp).toDate()
                        : (memory['createdAt'] as Timestamp).toDate();
                final isBranch = memory['isBranch'] ?? false;
                final branches = branchMap[memoryId] ?? [];

                List<Widget> widgets = [
                  GestureDetector(
                    onLongPress:
                        () => _showMemoryOptions(context, memory, memoryId),
                    child: TimelineTile(
                      alignment: TimelineAlign.manual,
                      lineXY: 0.2 + (branchLevel * 0.1),
                      isFirst:
                          false, // We'll handle first/last visually by spacing
                      isLast: false,
                      indicatorStyle: IndicatorStyle(
                        width: 20,
                        color: isBranch ? Colors.green : Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        iconStyle: IconStyle(
                          color: Colors.white,
                          iconData: isBranch ? Icons.call_split : Icons.circle,
                        ),
                      ),
                      startChild: Container(
                        padding: EdgeInsets.only(
                          left: 16.0 + branchLevel * 24,
                          right: 8,
                        ),
                        child: Text(
                          DateFormat('MMM dd').format(date),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      endChild: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (isBranch)
                                  const Icon(
                                    Icons.call_split,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    memory['title'] ?? 'Untitled',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (memory['photoUrls'] != null &&
                                (memory['photoUrls'] as List).isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  memory['photoUrls'][0],
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('MMM dd, yyyy').format(date),
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                Wrap(
                                  spacing: 4,
                                  children: [
                                    if (!isBranch)
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          minimumSize: Size(0, 32),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 0,
                                          ),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed:
                                            () => _showBranchCreationDialog(
                                              context,
                                              {...memory, 'id': memoryId},
                                            ),
                                        icon: const Icon(
                                          Icons.call_split,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Branch',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        minimumSize: Size(0, 32),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 0,
                                        ),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => MemoryDetailPage(
                                                  memoryId: memoryId,
                                                  memoryData: memory,
                                                ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'View Details',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
                // Recursively add branches below
                for (var branch in branches) {
                  widgets.addAll(
                    buildMemoryWithBranches(branch, branchLevel + 1),
                  );
                }
                return widgets;
              }

              // Sort main memories by date
              mainMemories.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aDate =
                    _sortByUnlockDate
                        ? (aData['unlockedAt'] as Timestamp).toDate()
                        : (aData['createdAt'] as Timestamp).toDate();
                final bDate =
                    _sortByUnlockDate
                        ? (bData['unlockedAt'] as Timestamp).toDate()
                        : (bData['createdAt'] as Timestamp).toDate();
                return bDate.compareTo(aDate);
              });

              // Build the timeline list
              List<Widget> timelineList = [];
              for (var doc in mainMemories) {
                timelineList.addAll(buildMemoryWithBranches(doc, 0));
              }

              return ListView(children: timelineList);
            },
          ),
        ),
      ],
    );
  }
}
