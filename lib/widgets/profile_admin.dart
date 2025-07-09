// ignore_for_file: unused_field, no_leading_underscores_for_local_identifiers, unused_element, sort_child_properties_last

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_animated_button/flutter_animated_button.dart'; // Import Animated Button package

class ProfileAdminPage extends StatefulWidget {
  const ProfileAdminPage({super.key});

  @override
  State<ProfileAdminPage> createState() => _ProfileAdminPageState();
}

class _ProfileAdminPageState extends State<ProfileAdminPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  
  String? _selectedCollege; // Selected college
  List<String> _colleges = []; // List of colleges

  bool _isEditingName = false;
  bool _isEditingBranch = false;
  bool _isLoading = false;
  String? _imagePath;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _nameController.text = user!.displayName ?? '';
      _emailController.text = user!.email ?? '';
      _fetchAdditionalData();
      _fetchColleges(); // Fetch colleges
    }
  }

  Future<void> _fetchAdditionalData() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        setState(() {
          _branchController.text = doc.data()?['branch'] ?? '';
          _imageUrl = doc.data()?['imageUrl'];
          _selectedCollege = doc.data()?['college']; // Load user's college
        });
      }
    }
  }

  Future<void> _fetchColleges() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('colleges').get();
      setState(() {
        _colleges = snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (e) {
      _showSnackBar('Error fetching colleges: $e');
    }
  }

  Future<void> _updateProfile() async {
  if (_nameController.text.isEmpty || _branchController.text.isEmpty || _selectedCollege == null) {
    _showSnackBar('Fields cannot be empty');
    return;
  }

  try {
    setState(() => _isLoading = true);
    await user!.updateProfile(displayName: _nameController.text);
    await user!.reload();

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'branch': _branchController.text,
      'college': _selectedCollege, // Save selected college
      'imageUrl': _imageUrl,
    }, SetOptions(merge: true));

    _showSnackBar('Profile updated successfully!');

    // Navigate to AdHomePage and pass the selected college
  } catch (e) {
    _showSnackBar('Error updating profile: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}


  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });

      await _uploadImageToFirebase(image);
    }
  }

  Future<void> _uploadImageToFirebase(XFile image) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('profile_images/${user!.uid}.jpg');
      await ref.putFile(File(image.path));
      _imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'imageUrl': _imageUrl,
      });

      setState(() {});
    } catch (e) {
      _showSnackBar('Error uploading image: $e');
    }
  }

  Future<void> _deleteImage() async {
    if (_imageUrl != null) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(_imageUrl!);
        await ref.delete();

        setState(() {
          _imagePath = null;
          _imageUrl = null;
        });

        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
          'imageUrl': null,
        });
      } catch (e) {
        _showSnackBar('Error deleting image: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _viewFullImage() {
    if (_imageUrl != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FullImagePage(imageUrl: _imageUrl!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileImage(),
                const SizedBox(height: 16),
                _buildEditableField(controller: _nameController, isEditing: _isEditingName, label: 'Name', onEdit: _updateProfile),
                _buildEditableField(controller: _emailController, isEditing: false, label: 'Email', readOnly: true),
                _buildCollegeDropdown(), // Dropdown for colleges
                _buildEditableField(controller: _branchController, isEditing: _isEditingBranch, label: 'Branch', onEdit: _updateProfile),
                const SizedBox(height: 20),
                _buildUpdateProfileButton(), // Using AnimatedButton
                if (_isLoading) const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _viewFullImage,
            child: ClipOval(
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.blue],
                  ),
                ),
                child: ClipOval(
                  child: _imageUrl != null
                      ? Image.network(
                          _imageUrl!,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        )
                      : const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildProfileImageActions(),
        ],
      ),
    );
  }

  Widget _buildProfileImageActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.add_a_photo, color: Colors.blueAccent),
          onPressed: _pickImage,
          tooltip: 'Add Image',
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: _confirmDeleteImage,
          tooltip: 'Delete Image',
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required bool isEditing,
    required String label,
    void Function()? onEdit,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: readOnly
              ? null
              : (isEditing
                  ? IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () {
                        if (onEdit != null) {
                          onEdit();
                          setState(() {
                            if (label == "Name") _isEditingName = false;
                            if (label == "Branch") _isEditingBranch = false;
                          });
                        }
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        setState(() {
                          if (label == "Name") _isEditingName = true;
                          if (label == "Branch") _isEditingBranch = true;
                        });
                      },
                    )),
        ),
        readOnly: readOnly,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildCollegeDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Select College',
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        value: _selectedCollege,
        items: _colleges.map((college) {
          return DropdownMenuItem<String>(
            value: college,
            child: Text(college),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCollege = value;
          });
        },
        hint: const Text('Choose a college'),
      ),
    );
  }

  Widget _buildUpdateProfileButton() {
    return Center(
      child: AnimatedButton(
        onPress: _updateProfile, // Ensure this parameter is included
        text: 'Update Profile', // Required argument
        isReverse: true,
        selectedTextColor: Colors.black,
        transitionType: TransitionType.LEFT_TO_RIGHT,
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        backgroundColor: Colors.blueAccent,
        borderColor: const Color.fromARGB(255, 0, 0, 0),
        borderRadius: 50,
        borderWidth: 2,
      ),
    );
  }

  Future<void> _confirmDeleteImage() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete your profile image?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteImage();
    }
  }
}

class FullImagePage extends StatelessWidget {
  final String imageUrl;

  const FullImagePage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Full Image'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}
