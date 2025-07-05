import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDate;
  File? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage({required bool fromCamera}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<String?> _uploadImage(File image) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref().child('event_images/$fileName.jpg');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<void> _addEvent() async {
    if (_titleController.text.isEmpty || _selectedDate == null || _selectedImage == null) return;

    setState(() => _isUploading = true);
    try {
      final imageUrl = await _uploadImage(_selectedImage!);
      await FirebaseFirestore.instance.collection('upcoming_events').add({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'date': _selectedDate,
        'imageUrl': imageUrl ?? '',
      });

      _titleController.clear();
      _descController.clear();
      setState(() {
        _selectedDate = null;
        _selectedImage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event added successfully!')),
      );
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add event.')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Logout'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Add Upcoming Event"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? 'No date selected'
                              : DateFormat.yMMMd().format(_selectedDate!),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Select Date'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _selectedImage != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Container(
                    height: 150,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('No image selected', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.photo, color: Colors.white),
                          label: const Text('Gallery', style: TextStyle(color: Colors.white)),
                          onPressed: () => _pickImage(fromCamera: false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          label: const Text('Camera', style: TextStyle(color: Colors.white)),
                          onPressed: () => _pickImage(fromCamera: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isUploading ? null : _addEvent,
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Add Event', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle("Current Events"),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('upcoming_events')
                  .orderBy('date')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final events = snapshot.data!.docs;
                if (events.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No events yet.', style: TextStyle(color: Colors.grey)),
                  ));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final title = event['title'] ?? '';
                    final date = (event['date'] as Timestamp).toDate();
                    final desc = event['description'] ?? '';
                    final imageUrl = event['imageUrl'] ?? '';

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 4,
                      child: ListTile(
                        leading: imageUrl.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        )
                            : const Icon(Icons.event, size: 40, color: Colors.deepPurple),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${DateFormat.yMMMd().format(date)}\n$desc',
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('upcoming_events')
                                .doc(event.id)
                                .delete();
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
