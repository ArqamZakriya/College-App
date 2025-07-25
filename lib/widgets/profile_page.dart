import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shimmer/shimmer.dart';

class ProfileUserPage extends StatefulWidget {
  const ProfileUserPage({super.key});

  @override
  State<ProfileUserPage> createState() => _ProfileUserPageState();
}

class _ProfileUserPageState extends State<ProfileUserPage> with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String? _selectedCollege;
  bool _isEditingName = false;
  bool _isEditingBranch = false;
  bool _isLoading = false;
  // ignore: unused_field
  String? _imagePath;
  String? _imageUrl;
  
  late double screenWidth;
  late double screenHeight;
  late bool isSmallScreen;

  final List<Color> _gradientColors = [
    const Color(0xFF1A237E), // Deeper blue
    const Color(0xFF3949AB), // Rich blue
    const Color(0xFF1E88E5), // Vibrant blue
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    
    if (user != null) {
      _nameController.text = user!.displayName ?? '';
      _emailController.text = user!.email ?? '';
      _fetchAdditionalData();
    }
  }

  void _initializeScreenSize() {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    isSmallScreen = screenWidth < 600;
  }

  Future<void> _fetchAdditionalData() async {
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
        if (doc.exists) {
          setState(() {
            _branchController.text = doc.data()?['branch'] ?? '';
            _imageUrl = doc.data()?['imageUrl'];
            _selectedCollege = doc.data()?['college'];
          });
        }
      } catch (e) {
        _showSnackBar('Error fetching data: $e');
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty || _branchController.text.isEmpty) {
      _showSnackBar('Fields cannot be empty');
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      await user!.updateProfile(displayName: _nameController.text);
      await user!.reload();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({
        'branch': _branchController.text,
        'college': _selectedCollege,
        'imageUrl': _imageUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _showSnackBar('Profile updated successfully!');
      setState(() {
        _isEditingName = false;
        _isEditingBranch = false;
      });
    } catch (e) {
      _showSnackBar('Error updating profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _imagePath = image.path;
          _isLoading = true;
        });

        await _uploadImageToFirebase(image);
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadImageToFirebase(XFile image) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images/${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await ref.putFile(File(image.path));
      final newImageUrl = await ref.getDownloadURL();

      if (_imageUrl != null) {
        try {
          final oldRef = FirebaseStorage.instance.refFromURL(_imageUrl!);
          await oldRef.delete();
        } catch (e) {
          print('Error deleting old image: $e');
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'imageUrl': newImageUrl,
      });

      setState(() {
        _imageUrl = newImageUrl;
      });

      _showSnackBar('Profile image updated successfully!');
    } catch (e) {
      _showSnackBar('Error uploading image: $e');
      setState(() {
        _imagePath = null;
      });
    }
  }

  Future<void> _deleteImage() async {
    if (_imageUrl != null) {
      try {
        setState(() => _isLoading = true);
        
        final ref = FirebaseStorage.instance.refFromURL(_imageUrl!);
        await ref.delete();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
          'imageUrl': null,
        });

        setState(() {
          _imagePath = null;
          _imageUrl = null;
        });

        _showSnackBar('Profile image deleted successfully');
      } catch (e) {
        _showSnackBar('Error deleting image: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmDeleteImage() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Confirm Delete',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text('Are you sure you want to delete your profile image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _deleteImage();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _initializeScreenSize();
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildShimmerTitle(),
                  Expanded(
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        _buildProfileSection(),
                        SliverToBoxAdapter(
                          child: _buildMainContent(),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).padding.bottom + 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.white),
          onPressed: () => _showHelpDialog(),
        ),
      ],
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedContainer(
      duration: const Duration(seconds: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors,
        ),
      ),
      child: CustomPaint(
        painter: BackgroundPainter(),
        child: Container(),
      ),
    );
  }

  Widget _buildShimmerTitle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 5),
      child: Shimmer.fromColors(
        baseColor: Colors.white,
        highlightColor: Colors.blue.shade100,
        period: const Duration(seconds: 2),
        child: Text(
          "Profile",
          style: TextStyle(
            fontSize: isSmallScreen ? 40 : 50,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return SliverToBoxAdapter(
      child: Container(
        height: screenHeight * 0.35,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildProfileImage(),
            const SizedBox(height: 20),
            _buildImageActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    double imageSize = isSmallScreen ? screenWidth * 0.45 : screenWidth * 0.35;
    
    return Hero(
      tag: 'profileImage',
      child: GestureDetector(
        onTap: () => _viewFullImage(),
        child: Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipOval(
            child: _imageUrl != null
                ? Image.network(
                    _imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildImageLoadingIndicator();
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImageErrorWidget();
                    },
                  )
                : _buildDefaultProfileImage(imageSize),
          ),
        ),
      ),
    );
  }

  Widget _buildImageLoadingIndicator() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildImageErrorWidget() {
    return Container(
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'Error loading image',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultProfileImage(double size) {
    return Container(
      color: Colors.white,
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: Colors.blue.shade300,
      ),
    );
  }

  Widget _buildImageActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildImageActionButton(
          icon: Icons.add_a_photo,
          label: 'Change Photo',
          onPressed: _pickImage,
        ),
        const SizedBox(width: 16),
        _buildImageActionButton(
          icon: Icons.delete,
          label: 'Remove',
          onPressed: _confirmDeleteImage,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildImageActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: isDestructive ? Colors.red.shade300 : Colors.white),
            borderRadius: BorderRadius.circular(30),
            gradient: isDestructive ? null : LinearGradient(
              colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isDestructive ? Colors.red.shade300 : Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDestructive ? Colors.red.shade300 : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoField(
                  controller: _nameController,
                  label: 'Name',
                  icon: Icons.person,
                  isEditing: _isEditingName,
                  onToggleEdit: () {
                    setState(() {
                      _isEditingName = !_isEditingName;
                      if (!_isEditingName) {
                        _updateProfile();
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildInfoField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  readOnly: true,
                ),
                const SizedBox(height: 16),
                _buildCollegeField(),
                const SizedBox(height: 16),
                _buildInfoField(
                  controller: _branchController,
                  label: 'Branch',
                  icon: Icons.school,
                  isEditing: _isEditingBranch,
                  onToggleEdit: () {
                    setState(() {
                      _isEditingBranch = !_isEditingBranch;
                      if (!_isEditingBranch) {
                        _updateProfile();
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isEditing = false,
    bool readOnly = false,
    VoidCallback? onToggleEdit,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isEditing ? Colors.blue.shade400 : Colors.grey.shade200,
          width: isEditing ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isEditing 
              ? Colors.blue.shade100.withOpacity(0.3)
              : Colors.black.withOpacity(0.05),
            blurRadius: isEditing ? 8 : 5,
            spreadRadius: isEditing ? 2 : 0,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly || !isEditing,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: isEditing ? Colors.blue.shade700 : Colors.blue.shade400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          suffixIcon: readOnly
              ? null
              : IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return RotationTransition(
                        turns: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Icon(
                      isEditing ? Icons.check_circle : Icons.edit,
                      key: ValueKey<bool>(isEditing),
                      color: isEditing ? Colors.green : Colors.blue.shade700,
                    ),
                  ),
                  onPressed: onToggleEdit,
                ),
          labelStyle: TextStyle(
            color: isEditing ? Colors.blue.shade700 : Colors.grey.shade600,
            fontWeight: isEditing ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 16,
          color: Colors.black87,
          fontWeight: isEditing ? FontWeight.w500 : FontWeight.normal,
        ),
        onSubmitted: isEditing ? (_) => onToggleEdit?.call() : null,
      ),
    );
  }

  Widget _buildCollegeField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
          ),
        ],
      ),
      child: TextField(
        controller: TextEditingController(text: _selectedCollege ?? 'Not Selected'),
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'College',
          prefixIcon: Icon(Icons.account_balance, color: Colors.blue.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: TextStyle(color: Colors.grey.shade600),
        ),
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 16,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Please wait...',
                style: TextStyle(color: Colors.grey.shade800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, 
                  color: Colors.blue.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'How to Edit Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...buildHelpSections(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Got it'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

List<Widget> buildHelpSections() {
  return [
    _buildHelpSection(
      icon: Icons.edit,
      title: 'Editing Information',
      content: 'Tap the edit icon (pencil) next to any field to make changes. '
          'Once you\'re done, tap the checkmark icon to save your updates.',
    ),
    const SizedBox(height: 16),
    _buildHelpSection(
      icon: Icons.photo_camera,
      title: 'Profile Picture',
      content: 'Use the "Change Photo" button to upload a new profile picture '
          'from your gallery. The "Remove" button will delete your current profile picture.',
    ),
  ];
}

Widget _buildHelpSection({
  required IconData icon,
  required String title,
  required String content,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: Colors.blue.shade700,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              content,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

  void _viewFullImage() {
    if (_imageUrl != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullImagePage(imageUrl: _imageUrl!),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _branchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.7,
        size.width * 0.5,
        size.height * 0.8,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.9,
        size.width,
        size.height * 0.8,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FullImagePage extends StatelessWidget {
  final String imageUrl;

  const FullImagePage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: 'profileImage',
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Error loading image',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}