import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isEditing = false;
  final picker = ImagePicker();
  File? _newProfileImage;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  String theme = 'dark';
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
          theme = userData?['preferences']?['theme'] ?? 'dark';
          unit = userData?['preferences']?['units'] ?? 'km';
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    if (uid == null) return;

    final updatedData = {
      'name': nameController.text.trim(),
      'bio': bioController.text.trim(),
      'address': addressController.text.trim(),
      'preferences': {
        'theme': theme,
        'units': unit,
      }
    };

    if (_newProfileImage != null) {
      final fileName = 'profile_$uid.jpg';
      final ref = FirebaseStorage.instance.ref().child('profile_pics/$fileName');
      await ref.putFile(_newProfileImage!);
      final photoUrl = await ref.getDownloadURL();
      updatedData['photoUrl'] = photoUrl;
    }

    await FirebaseFirestore.instance.collection('JourneyMate').doc(uid).update(updatedData);
    setState(() => isEditing = false);
    _fetchUserData();
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newProfileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => isEditing = true),
            ),
        ],
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: isEditing ? _pickImage : null,
                child: CircleAvatar(
                  radius: 55,
                  backgroundImage: _newProfileImage != null
                      ? FileImage(_newProfileImage!)
                      : (userData?['photoUrl'] != null && userData!['photoUrl'] != ''
                      ? NetworkImage(userData!['photoUrl'])
                      : const AssetImage('assets/default_profile.png')) as ImageProvider,
                ),
              ),
              const SizedBox(height: 20),
              _buildEditableField("Name", nameController, isEditing),
              _buildEditableField("Bio", bioController, isEditing),
              _buildEditableField("Address", addressController, isEditing),
              _buildDropdown("Theme", ['light', 'dark'], theme, (val) => setState(() => theme = 'dark'), isEditing),
              _buildDropdown("Units", ['km', 'mi'], unit, (val) => setState(() => unit = 'KM'), isEditing),
              const SizedBox(height: 20),
              if (isEditing)
                ElevatedButton(
                  onPressed: _saveChanges,
                  child: const Text("Save Changes"),
                ),
              if (!isEditing)
                TextButton(
                  onPressed: () => _showChangeSensitiveDialog(context),
                  child: const Text("Change email, phone, or password"),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, bool editable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          enabled: editable,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            filled: !editable,
            fillColor: editable ? null : Colors.grey.shade200,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> options, String selected, ValueChanged<String?>? onChanged, bool editable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: selected,
          onChanged: editable ? onChanged : null,
          items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
      ],
    );
  }


  void _showChangeSensitiveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sensitive Info"),
        content: const Text("For security, you will need to verify your identity to change email, phone or password."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/account-security');
            },
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }
}
