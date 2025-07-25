import 'package:college_app/auth/email_service.dart';
import 'package:college_app/auth/email_verification_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:college_app/auth/login.dart';
import 'dart:math' as math;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with TickerProviderStateMixin {
  // Animation controllers and variables
  late AnimationController _lottieController;
  late AnimationController _formController;
  late AnimationController _rotationController;
  late Animation<double> _lottieScaleAnimation;
  late Animation<Offset> _formSlideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _buttonScaleAnimation;

  // Form controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usnController = TextEditingController();

  // Dropdown controllers
  String? _selectedUniversityId;
  String? _selectedCollegeId;
  String? _selectedCourseId;
  String? _selectedBranchId;
  String? _selectedYearOfPassing;
  List<Map<String, dynamic>> _universities = [];
  List<Map<String, dynamic>> _colleges = [];
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _branches = [];
  final List<String> _yearsOfPassing = [
    '2023', '2024', '2025', '2026', '2027', '2028', '2029', '2030'
  ];

  // State variables
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isLoadingUniversities = false;
  bool _isLoadingColleges = false;
  bool _isLoadingCourses = false;
  bool _isLoadingBranches = false;

  // Colors
  static const primaryBlue = Color(0xFF1A237E);
  static const accentYellow = Color(0xFFFFD700);
  static const deepBlack = Color(0xFF121212);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUniversities();
  }

  void _setupAnimations() {
    _lottieController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _formController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _lottieScaleAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _lottieController,
        curve: Curves.elasticOut,
      ),
    );

    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.easeOutCubic,
    ));

    _rotationAnimation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOutBack,
    ));

    _buttonScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
    ));

    _lottieController.forward().then((_) {
      _formController.forward();
      _rotationController.forward();
    });
  }

  Future<void> _loadUniversities() async {
    setState(() => _isLoadingUniversities = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('universities').get();
      setState(() {
        _universities = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'],
          };
        }).toList();
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to load universities: $e');
    } finally {
      setState(() => _isLoadingUniversities = false);
    }
  }

  Future<void> _loadColleges(String universityId) async {
    setState(() {
      _selectedUniversityId = universityId;
      _selectedCollegeId = null;
      _selectedCourseId = null;
      _selectedBranchId = null;
      _colleges = [];
      _courses = [];
      _branches = [];
      _isLoadingColleges = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('colleges')
          .where('universityId', isEqualTo: universityId)
          .get();

      setState(() {
        _colleges = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'],
          };
        }).toList();
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to load colleges: $e');
    } finally {
      setState(() => _isLoadingColleges = false);
    }
  }

  Future<void> _loadCourses(String collegeId) async {
    setState(() {
      _selectedCollegeId = collegeId;
      _selectedCourseId = null;
      _selectedBranchId = null;
      _courses = [];
      _branches = [];
      _isLoadingCourses = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('collegeId', isEqualTo: collegeId)
          .get();

      setState(() {
        _courses = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'],
          };
        }).toList();
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to load courses: $e');
    } finally {
      setState(() => _isLoadingCourses = false);
    }
  }

  Future<void> _loadBranches(String courseId) async {
    setState(() {
      _selectedCourseId = courseId;
      _selectedBranchId = null;
      _branches = [];
      _isLoadingBranches = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('branches')
          .where('courseId', isEqualTo: courseId)
          .get();

      setState(() {
        _branches = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'],
          };
        }).toList();
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to load branches: $e');
    } finally {
      setState(() => _isLoadingBranches = false);
    }
  }

  Future<void> _registerStudent() async {
    setState(() => _isLoading = true);

    try {
      // Validate all fields
      if (_firstNameController.text.isEmpty ||
          _lastNameController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _phoneController.text.isEmpty ||
          _usnController.text.isEmpty ||
          _selectedUniversityId == null ||
          _selectedCollegeId == null ||
          _selectedCourseId == null ||
          _selectedBranchId == null ||
          _selectedYearOfPassing == null) {
        throw FirebaseAuthException(
          code: 'invalid-argument',
          message: 'All fields are required',
        );
      }

      // Check if email already exists
      final emailCheck = await FirebaseFirestore.instance
          .collection('user_metadata')
          .where('email', isEqualTo: _emailController.text.trim())
          .get();

      if (emailCheck.docs.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'email-already-exists',
          message: 'This email is already registered',
        );
      }

      // Generate OTP
      final otp = (math.Random().nextInt(900000) + 100000).toString();
      final email = _emailController.text.trim();

      // Send OTP email first
      final otpSent = await EmailService.sendOtpEmail(email, otp);
      if (!otpSent) {
        throw FirebaseAuthException(
          code: 'otp-send-failed',
          message: 'Failed to send OTP. Please try again.',
        );
      }

      // Create user in Firebase Auth
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: _passwordController.text,
          );

      final User? user = userCredential.user;
      if (user == null) throw Exception('User creation failed');

      // Get selected names for all dropdowns
      final universityName = _universities
          .firstWhere((uni) => uni['id'] == _selectedUniversityId)['name'];
      final collegeName = _colleges
          .firstWhere((col) => col['id'] == _selectedCollegeId)['name'];
      final courseName = _courses
          .firstWhere((course) => course['id'] == _selectedCourseId)['name'];
      final branchName = _branches
          .firstWhere((branch) => branch['id'] == _selectedBranchId)['name'];

      // Prepare student data
      final studentData = {
        'uid': user.uid,
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'fullName': '${_firstNameController.text} ${_lastNameController.text}',
        'email': email,
        'phone': _phoneController.text,
        'usn': _usnController.text.toUpperCase(),
        'accountStatus': 'pending_verification',
        'userType': 'student',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isEmailVerified': false,
        'isActive': false,
        'verificationOtp': otp,
        'otpCreatedAt': FieldValue.serverTimestamp(),
        'universityId': _selectedUniversityId,
        'universityName': universityName,
        'collegeId': _selectedCollegeId,
        'collegeName': collegeName,
        'courseId': _selectedCourseId,
        'courseName': courseName,
        'branchId': _selectedBranchId,
        'branchName': branchName,
        'yearOfPassing': _selectedYearOfPassing,
      };

      final metadata = {
        'uid': user.uid,
        'email': email,
        'userType': 'student',
        'accountStatus': 'pending_verification',
        'dataLocation': 'users/pending_students/data/${user.uid}',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Batch write for atomic operations
      final batch = FirebaseFirestore.instance.batch();
      
      final studentRef = FirebaseFirestore.instance
          .collection('users')
          .doc('pending_students')
          .collection('data')
          .doc(user.uid);
      
      final metadataRef = FirebaseFirestore.instance
          .collection('user_metadata')
          .doc(user.uid);
      
      batch.set(studentRef, studentData);
      batch.set(metadataRef, metadata);

      await batch.commit();

      // Navigate to OTP verification
      Get.off(() => OtpVerificationPage(
        userId: user.uid,
        email: email, 
        userType: 'student',
      ));

    } on FirebaseAuthException catch (e) {
      Get.dialog(
        AlertDialog(
          title: const Text('Registration Error'),
          content: Text(e.message ?? 'An error occurred during registration'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.dialog(
        AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDropdown({
    required String hintText,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required String? selectedValue,
    required Function(String?) onChanged,
    bool isLoading = false,
    bool enabled = true,
  }) {
    final size = MediaQuery.of(context).size;
    
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(_rotationAnimation.value),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryBlue.withOpacity(0.1),
              deepBlack.withOpacity(0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: accentYellow.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: DropdownButtonFormField<String>(
          value: selectedValue,
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(
                'Select $hintText',
                style: TextStyle(
                  color: deepBlack.withOpacity(0.5),
                  fontSize: size.width * 0.04,
                ),
              ),
            ),
            ...items.map((item) {
              return DropdownMenuItem(
                value: item['id'],
                child: Text(
                  item['name'],
                  style: TextStyle(
                    color: deepBlack,
                    fontSize: size.width * 0.04,
                  ),
                ),
              );
            }),
          ],
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: primaryBlue,
              size: size.width * 0.06,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide(
                color: primaryBlue.withOpacity(0.1),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(
                color: primaryBlue,
                width: 2,
              ),
            ),
          ),
          icon: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.arrow_drop_down),
          isExpanded: true,
          validator: (value) {
            if (value == null) {
              return 'Please select a $hintText';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildYearOfPassingDropdown() {
    final size = MediaQuery.of(context).size;
    
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(_rotationAnimation.value),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryBlue.withOpacity(0.1),
              deepBlack.withOpacity(0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: accentYellow.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: DropdownButtonFormField<String>(
          value: _selectedYearOfPassing,
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Select Year of Passing'),
            ),
            ..._yearsOfPassing.map((year) {
              return DropdownMenuItem(
                value: year,
                child: Text(year),
              );
            }),
          ],
          onChanged: (value) => setState(() => _selectedYearOfPassing = value),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.calendar_today,
              color: primaryBlue,
              size: size.width * 0.06,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide(
                color: primaryBlue.withOpacity(0.1),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(
                color: primaryBlue,
                width: 2,
              ),
            ),
          ),
          icon: const Icon(Icons.arrow_drop_down),
          isExpanded: true,
          validator: (value) {
            if (value == null) {
              return 'Please select year of passing';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    final size = MediaQuery.of(context).size;
    
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(_rotationAnimation.value),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryBlue.withOpacity(0.1),
              deepBlack.withOpacity(0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: accentYellow.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          style: TextStyle(
            fontSize: size.width * 0.04,
            color: deepBlack,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: deepBlack.withOpacity(0.5),
              fontSize: size.width * 0.04,
            ),
            prefixIcon: Icon(
              icon,
              color: primaryBlue,
              size: size.width * 0.06,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: primaryBlue,
                      size: size.width * 0.06,
                    ),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide(
                color: primaryBlue.withOpacity(0.1),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(
                color: primaryBlue,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    final size = MediaQuery.of(context).size;
    
    return ScaleTransition(
      scale: _buttonScaleAnimation,
      child: Container(
        width: double.infinity,
        height: size.height * 0.07,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryBlue, Color(0xFF0D47A1)],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: accentYellow.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _registerStudent,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : Text(
                  'Register',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width * 0.06,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.03),
                  ScaleTransition(
                    scale: _lottieScaleAnimation,
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(math.pi * _lottieScaleAnimation.value * 0.0),
                      alignment: Alignment.center,
                      child: SizedBox(
                        height: size.height * 0.25,
                        child: Lottie.asset(
                          'assets/lottie/register.json',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  SlideTransition(
                    position: _formSlideAnimation,
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(_rotationAnimation.value),
                      alignment: Alignment.center,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(size.width * 0.06),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.1),
                              blurRadius: 30,
                              spreadRadius: 5,
                              offset: const Offset(0, -5),
                            ),
                            BoxShadow(
                              color: accentYellow.withOpacity(0.1),
                              blurRadius: 30,
                              spreadRadius: 5,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [primaryBlue, Color(0xFFE91E63)],
                              ).createShader(bounds),
                              child: Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: size.width * 0.08,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: size.height * 0.01),
                            Text(
                              'Sign up to get started',
                              style: TextStyle(
                                fontSize: size.width * 0.04,
                                color: deepBlack.withOpacity(0.6),
                              ),
                            ),
                            SizedBox(height: size.height * 0.02),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _firstNameController,
                                    hint: 'First Name',
                                    icon: Icons.person,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _lastNameController,
                                    hint: 'Last Name',
                                    icon: Icons.person_outline,
                                  ),
                                ),
                              ],
                            ),
                            
                            _buildTextField(
                              controller: _emailController,
                              hint: 'College Email',
                              icon: Icons.email_rounded,
                            ),
                            
                            _buildTextField(
                              controller: _phoneController,
                              hint: 'Phone Number',
                              icon: Icons.phone,
                            ),
                            
                            _buildTextField(
                              controller: _usnController,
                              hint: 'USN',
                              icon: Icons.badge_outlined,
                            ),
                            
                            // University Dropdown
                            _buildDropdown(
                              hintText: 'University',
                              icon: Icons.school,
                              items: _universities,
                              selectedValue: _selectedUniversityId,
                              onChanged: (value) => _loadColleges(value!),
                              isLoading: _isLoadingUniversities,
                            ),
                            
                            // College Dropdown
                            _buildDropdown(
                              hintText: 'College',
                              icon: Icons.business,
                              items: _colleges,
                              selectedValue: _selectedCollegeId,
                              onChanged: (value) => _loadCourses(value!),
                              isLoading: _isLoadingColleges,
                              enabled: _selectedUniversityId != null,
                            ),
                            
                            // Course Dropdown
                            _buildDropdown(
                              hintText: 'Course',
                              icon: Icons.menu_book,
                              items: _courses,
                              selectedValue: _selectedCourseId,
                              onChanged: (value) => _loadBranches(value!),
                              isLoading: _isLoadingCourses,
                              enabled: _selectedCollegeId != null,
                            ),
                            
                            // Branch Dropdown
                            _buildDropdown(
                              hintText: 'Branch',
                              icon: Icons.account_tree,
                              items: _branches,
                              selectedValue: _selectedBranchId,
                              onChanged: (value) => setState(() => _selectedBranchId = value),
                              isLoading: _isLoadingBranches,
                              enabled: _selectedCourseId != null,
                            ),
                            
                            // Year of Passing Dropdown
                            _buildYearOfPassingDropdown(),
                            
                            _buildTextField(
                              controller: _passwordController,
                              hint: 'Password',
                              icon: Icons.lock_rounded,
                              isPassword: true,
                            ),
                            
                            SizedBox(height: size.height * 0.02),
                            _buildRegisterButton(),
                            SizedBox(height: size.height * 0.03),
                            Wrap(
                              alignment: WrapAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    color: deepBlack.withOpacity(0.6),
                                    fontSize: math.min(size.width * 0.035, 14),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Get.to(() => const LoginPage()),
                                  child: Text(
                                    'Login Now',
                                    style: TextStyle(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: math.min(size.width * 0.035, 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.05),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _formController.dispose();
    _rotationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _usnController.dispose();
    super.dispose();
  }
}