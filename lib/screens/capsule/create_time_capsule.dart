import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../../app.dart';
import '../capsule/select_friend.dart';
import '../../services/capsule_service.dart';
import '../../models/time_capsule.dart';


class CreateTimeCapsulePage extends StatefulWidget {
  const CreateTimeCapsulePage({super.key});

  @override
  State<CreateTimeCapsulePage> createState() => _CreateTimeCapsulePageState();
}

class _CreateTimeCapsulePageState extends State<CreateTimeCapsulePage> {
  final TextEditingController _titleController = TextEditingController();
  final quill.QuillController _quillController = quill.QuillController.basic();
  static const int _maxDescriptionLength = 500;

  bool _showToolbar = false;
  bool _isLoading = false;
  bool _showMediaSection = false;

  DateTime? _selectedDate;
  String _privacy = 'Private';

  final ImagePicker _picker = ImagePicker();

  final List<File> _photoFiles = [];
  final List<File> _videoFiles = [];
  final List<File> _audioFiles = [];
  final List<File> _otherFiles = [];

  bool _isPickingImage = false; 
  bool _isPickingVideo = false; 
  bool _isPickingAudio = false; 
  bool _isPickingFile = false; 


  Future<void> _addPhoto() async {
    if (_isPickingImage) return;
    _isPickingImage = true;

    try {
      final status = await Permission.photos.request();
      final storageStatus = await Permission.storage.request();

      if (status.isGranted || storageStatus.isGranted) {
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          setState(() {
            _photoFiles.add(File(image.path));
          });
        }
      } else {
        debugPrint('Permission denied');
        showErrorMessage('Permission denied to access photos.');
      }
    } catch (e) {
      debugPrint('Error picking photo: $e');
      showErrorMessage('An error occurred while picking photo.');
    } finally {
      _isPickingImage = false;
    }
  }

  Future<void> _addVideo() async {
    if (_isPickingVideo) return;
    _isPickingVideo = true;

    try {
      final status = await Permission.photos.request();
      final storageStatus = await Permission.storage.request();

      if (status.isGranted || storageStatus.isGranted) {
        final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
        if (video != null) {
          setState(() {
            _videoFiles.add(File(video.path));
          });
        }
      } else {
        debugPrint('Permission denied for video');
        showErrorMessage('Permission denied to access videos.');
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
      showErrorMessage('An error occurred while picking video.');
    } finally {
      _isPickingVideo = false;
    }
  }

  Future<void> _addAudio() async {
    if (_isPickingAudio || _isLoading) return;
    _isPickingAudio = true;
    setState(() => _isLoading = true);

    try {
      final granted = await Permission.storage.isGranted || await Permission.manageExternalStorage.isGranted;
      if (!granted) {
        final statuses = await [Permission.storage, Permission.manageExternalStorage].request();
        if (!(statuses[Permission.storage]?.isGranted ?? false) &&
            !(statuses[Permission.manageExternalStorage]?.isGranted ?? false)) {
          debugPrint('Permission denied for audio');
          showErrorMessage('Permission denied to access audio files.');
          return;
        }
      }

      final result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result != null && result.files.single.path != null) {
        setState(() {
          _audioFiles.add(File(result.files.single.path!));
        });
      }
    } catch (e) {
      debugPrint('Error picking audio: $e');
      showErrorMessage('An error occurred while picking audio.');
    } finally {
      _isPickingAudio = false;
      setState(() => _isLoading = false);
    }
  }


  Future<void> _addFile() async {
  if (_isPickingFile || _isLoading) return;
  _isPickingFile = true;
  setState(() => _isLoading = true);

  try {
    final hasPermission = await Permission.storage.isGranted || await Permission.manageExternalStorage.isGranted;

    if (!hasPermission) {
      final statuses = await [Permission.storage, Permission.manageExternalStorage].request();
      if (!(statuses[Permission.storage]?.isGranted ?? false) &&
          !(statuses[Permission.manageExternalStorage]?.isGranted ?? false)) {
        debugPrint('Permission denied for file');
        showErrorMessage('Permission denied to access files.');
        return;
      }
    }

    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _otherFiles.add(File(result.files.single.path!));
      });
    }
  } catch (e) {
    debugPrint('Error picking file: $e');
    showErrorMessage('An error occurred while picking file.');
  } finally {
    _isPickingFile = false;
    setState(() => _isLoading = false);
  }
}


  // Future<void> _pickAnyFile() async {
  //   final result = await FilePicker.platform.pickFiles(type: FileType.any);
  //   if (result != null && result.files.single.path != null) {
  //     setState(() {
  //       _otherFiles.add(File(result.files.single.path!));
  //     });
  //   }
  // }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<String> _uploadFileToFirebase(File file, String folderName) async {
    try {
      // 1. Check if file exists
      if (!file.existsSync()) {
        debugPrint('File does not exist at path: ${file.path}');
        return '';
      }

      // 2. Create a unique file name and reference
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = FirebaseStorage.instance.ref().child('$folderName/$fileName');

      // 3. Upload the file
      final uploadTask = await ref.putFile(file);

      // 4. Wait for the upload to complete and get the download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      debugPrint('Upload successful: $downloadUrl');
      return downloadUrl;

    } catch (e) {
      debugPrint('Upload failed: $e');
      return '';
    }
  }


  Widget _buildSectionCard(String title, IconData icon, List<File> files, VoidCallback onAdd) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                const Spacer(),
                IconButton(
                  onPressed: onAdd,
                  icon: Icon(Icons.add_circle_outline, color: Colors.blue.shade700),
                  tooltip: 'Add $title',
                )
              ],
            ),
            if (files.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: files.map((file) {
                  bool isImage = file.path.endsWith('.jpg') || file.path.endsWith('.jpeg') || file.path.endsWith('.png');
                  bool isVideo = file.path.endsWith('.mp4') || file.path.endsWith('.mov') || file.path.endsWith('.avi');

                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade200,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: isImage
                              ? Image.file(file, fit: BoxFit.cover)
                              : isVideo
                                  ? Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/video_placehorder.jpg',
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                        ),
                                        const Icon(Icons.play_circle_outline, size: 32, color: Colors.white),
                                      ],
                                    )
                                  : Center(
                                      child: Text(
                                        file.path.split('/').last,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => setState(() => files.remove(file)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black54,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              )
          ],
        ),
      ),
    );
  }

  final List<String> _privacyOptions = ['Private', 'Public', 'Specific'];
  List<String> _selectedFriendIds = [];

  Widget _buildPrivacyToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Privacy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        ToggleButtons(
          isSelected: _privacyOptions.map((e) => e == _privacy).toList(),
          onPressed: (index) async {
            final selected = _privacyOptions[index];
            if (selected == 'Specific') {
              // Navigate to friend selection page
              final List<String>? result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SelectFriendsPage()),
              );
              if (result != null && result.isNotEmpty) {
                setState(() {
                  _privacy = selected;
                  _selectedFriendIds = result;
                });
              } else {
                // User backed out or selected none, fallback to Private
                setState(() {
                  _privacy = 'Private';
                  _selectedFriendIds = [];
                });
              }
            } else {
              setState(() {
                _privacy = selected;
                _selectedFriendIds = [];
              });
            }
          },
          borderRadius: BorderRadius.circular(8),
          selectedColor: Colors.white,
          fillColor: Colors.blue.shade700,
          renderBorder: false,
          constraints: const BoxConstraints(minHeight: 40, minWidth: 90),
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('Private'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('Public'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('Specific'),
            ),
          ],
        ),
        if (_privacy == 'Specific' && _selectedFriendIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Shared with ${_selectedFriendIds.length} friend(s)',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
      ],
    );
  }

  void _handleFormSubmission() async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final CapsuleService capsuleService = CapsuleService(userId);
    final String title = _titleController.text.trim();
    final String description = _quillController.document.toPlainText().trim();

    if (title.isEmpty) {
      showErrorMessage('Please enter a title for your capsule.');
      return;
    }

    if (description.isEmpty) {
      showErrorMessage('Please enter a description for your capsule.');
      return;
    }

    if (description.length > _maxDescriptionLength) {
      showErrorMessage('Description cannot exceed $_maxDescriptionLength characters.');
      return;
    }

    if (_selectedDate == null) {
      showErrorMessage('Please select an unlock date.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload all media files concurrently, ignoring empty lists gracefully
      final photoUrls = _photoFiles.isNotEmpty
          ? await Future.wait(_photoFiles.map((file) => _uploadFileToFirebase(file, 'photos')))
          : <String>[];

      final videoUrls = _videoFiles.isNotEmpty
          ? await Future.wait(_videoFiles.map((file) => _uploadFileToFirebase(file, 'videos')))
          : <String>[];

      final audioUrls = _audioFiles.isNotEmpty
          ? await Future.wait(_audioFiles.map((file) => _uploadFileToFirebase(file, 'audio')))
          : <String>[];

      final fileUrls = _otherFiles.isNotEmpty
          ? await Future.wait(_otherFiles.map((file) => _uploadFileToFirebase(file, 'files')))
          : <String>[];

      // Check if any uploads failed (empty URL)
      final allUrls = [...photoUrls, ...videoUrls, ...audioUrls, ...fileUrls];
      if (allUrls.any((url) => url.isEmpty)) {
        showErrorMessage('One or more files failed to upload. Please try again.');
        setState(() => _isLoading = false);
        return;
      }

      final visibleTo = await _computeVisibleToUids(_privacy);

      final capsule = TimeCapsule(
            id: '', 
            title: title,
            description: description,
            unlockDate: _selectedDate!,
            privacy: _privacy.toLowerCase(),
            visibleTo: visibleTo,
            photoUrls: photoUrls,
            videoUrls: videoUrls,
            audioUrls: audioUrls,
            fileUrls: fileUrls,
            createdAt: DateTime.now(),
            status: 'locked',
          );

      await capsuleService.createCapsule(capsule);
      debugPrint('Title: $title');
      debugPrint('Description: $description');
      debugPrint('Unlock Date: $_selectedDate');
      debugPrint('Privacy: $_privacy');
      debugPrint('Photos: $photoUrls');
      debugPrint('Videos: $videoUrls');
      debugPrint('Audio: $audioUrls');
      debugPrint('Other Files: $fileUrls');



      showSuccessMessage('Capsule created and files uploaded successfully!');
      Navigator.pop(context);

    } catch (e) {
      debugPrint('Submission error: $e');
      showErrorMessage('Failed to create capsule. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<List<String>> _computeVisibleToUids(String privacy) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    if (privacy == 'Private') {
      return []; 
    }

    if (privacy == 'Public') {
      final firestore = FirebaseFirestore.instance;

      final asOwner = await firestore
          .collection('friendList')
          .where('ownerId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();

      final asFriend = await firestore
          .collection('friendList')
          .where('friendId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();

      final friendUids = <String>{};

      for (var doc in asOwner.docs) {
        friendUids.add(doc['friendId']);
      }
      for (var doc in asFriend.docs) {
        friendUids.add(doc['ownerId']);
      }

      return friendUids.toList();
    }

    if (privacy == 'Specific') {
      return _selectedFriendIds;
    }

    return [userId]; // Fallback to private
  }


  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  static const double _verticalSpace = 12.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          title: const Text('Create Capsule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ListView(
              children: [
               const Text.rich(
                  TextSpan(
                    text: 'Title ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))],
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'Enter capsule title',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),

                SizedBox(height: _verticalSpace),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.perm_media, color: Colors.blue, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Add Media',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                            SizedBox(height: 4),
                            Text(
                              'Make your capsule more memorable with photos, videos, and files',
                              style: TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _showMediaSection ? Icons.expand_less : Icons.expand_more,
                          color: Colors.blue,
                        ),
                        onPressed: () => setState(() => _showMediaSection = !_showMediaSection),
                        tooltip: _showMediaSection ? 'Hide media section' : 'Show media section',
                      ),
                    ],
                  ),
                ),

                if (_showMediaSection) ...[
                  _buildSectionCard('Photos', Icons.photo, _photoFiles, _addPhoto),
                  _buildSectionCard('Videos', Icons.videocam, _videoFiles, _addVideo),
                  _buildSectionCard('Audio', Icons.audiotrack, _audioFiles, _addAudio),
                  _buildSectionCard('Files', Icons.insert_drive_file, _otherFiles, _addFile),
                ],

                SizedBox(height: _verticalSpace),

                // Description Editor
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(' *', style: TextStyle(color: Colors.red, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Maximum 500 characters',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                  height: 200,
                                  child: quill.QuillEditor.basic(
                                    controller: _quillController,
                                  ),
                                ),
                              if (_showToolbar) quill.QuillSimpleToolbar(controller: _quillController),
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: Icon(_showToolbar ? Icons.expand_less : Icons.expand_more,
                                      color: Colors.blue.shade700),
                                  onPressed: () => setState(() => _showToolbar = !_showToolbar),
                                  tooltip: _showToolbar ? 'Hide toolbar' : 'Show toolbar',
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: _verticalSpace),

                // Unlock Date
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Unlock Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _pickDate,
                          child: AbsorbPointer(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: _selectedDate != null
                                    ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                                    : 'DD/MM/YYYY',
                                suffixIcon: Icon(Icons.calendar_today, color: Colors.blue.shade700),
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: _verticalSpace),

                // Privacy
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _buildPrivacyToggle(),
                  ),
                ),

                SizedBox(height: _verticalSpace),

                // Submit
                ElevatedButton(
                  onPressed: _handleFormSubmission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Create Capsule', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),

                SizedBox(height: _verticalSpace),
              ],
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}