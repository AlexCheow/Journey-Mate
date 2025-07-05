// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isEditing = false;
  bool isSaving = false;
  final picker = ImagePicker();
  File? _newProfileImage;
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final bioController = TextEditingController();
  final addressController = TextEditingController();
  String unit = 'km';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('JourneyMate').doc(uid).get();
      if (doc.exists) {
        setState(() {
          userData = doc.data();
          nameController.text = userData?['name'] ?? '';
          bioController.text = userData?['bio'] ?? '';
          addressController.text = userData?['address'] ?? '';
          unit = userData?['preferences']?['units'] ?? 'km';
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    if (uid == null) return;

    final updatedData = {
      'name': nameController.text.trim(),
      'bio': bioController.text.trim(),
      'address': addressController.text.trim(),
      'preferences': {
        'units': unit,
      }
    };

    if (_newProfileImage != null) {
      final ref = FirebaseStorage.instance.ref().child('profile_pics/profile_$uid.jpg');
      await ref.putFile(_newProfileImage!);
      final photoUrl = await ref.getDownloadURL();
      updatedData['photoUrl'] = photoUrl;
    }

    await FirebaseFirestore.instance.collection('JourneyMate').doc(uid).update(updatedData);
    setState(() {
      isEditing = false;
      isSaving = false;
      _newProfileImage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Profile updated successfully!')),
    );
    _fetchUserData();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source != null) {
      final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() => _newProfileImage = File(pickedFile.path));
      }
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text("Logout"),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600);
    final labelStyle = GoogleFonts.poppins(fontSize: 14);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.close : Icons.edit),
            onPressed: () => setState(() => isEditing = !isEditing),
          )
        ],
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Column(
              key: ValueKey(isEditing),
              children: [
                Hero(
                  tag: 'profile-pic',
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _newProfileImage != null
                            ? FileImage(_newProfileImage!)
                            : (userData?['photoUrl'] != null && userData!['photoUrl'] != ''
                            ? NetworkImage(userData!['photoUrl'])
                            : const AssetImage('assets/default_profile.png')) as ImageProvider,
                      ),
                      if (isEditing)
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _sectionHeader("Personal Info", titleStyle),
                _buildTextField("Name", nameController, isEditing, Icons.person, labelStyle, required: true),
                _buildTextField("Bio", bioController, isEditing, Icons.info_outline, labelStyle),
                _buildTextField("Address", addressController, isEditing, Icons.location_on, labelStyle),
                const Divider(height: 30),
                _sectionHeader("Preferences", titleStyle),
                _buildDropdown("Distance Units", ['km', 'mi'], unit,
                        (val) => setState(() => unit = val ?? 'km'), isEditing, Icons.straighten, labelStyle),
                const Divider(height: 30),
                _sectionHeader("Security", titleStyle),
                TextButton.icon(
                  icon: const Icon(Icons.logout),
                  onPressed: _confirmLogout,
                  label: const Text("Logout"),
                ),
                const SizedBox(height: 20),
                if (isEditing)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : _saveChanges,
                      icon: isSaving
                          ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: const Text("Save Changes"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _sectionHeader(String text, TextStyle style) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(text, style: style),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool editable,
      IconData icon, TextStyle labelStyle, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: editable,
        validator: required ? (val) => val == null || val.isEmpty ? 'Required' : null : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: labelStyle,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          filled: !editable,
          fillColor: editable ? null : Colors.grey.shade200,
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String selected, ValueChanged<String?>? onChanged,
      bool editable, IconData icon, TextStyle labelStyle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: selected,
        onChanged: editable ? onChanged : null,
        items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: labelStyle,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
