import 'package:college_app/college_selection_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:college_app/login.dart';
// import 'package:college_app/wrapper.dart';
import 'package:college_app/email_verification_page.dart';
import 'dart:math' as math;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with TickerProviderStateMixin {
  late AnimationController _lottieController;
  late AnimationController _formController;
  late AnimationController _rotationController;
  late Animation<double> _lottieScaleAnimation;
  late Animation<Offset> _formSlideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _buttonScaleAnimation;

  bool _isPasswordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _collegeController = TextEditingController();
  List<String> _colleges = [];

  // Custom colors
  static const primaryBlue = Color(0xFF1A237E);
  static const accentYellow = Color(0xFFFFD700);
  static const deepBlack = Color(0xFF121212);

  @override
  void initState() {
    super.initState();
    _fetchColleges();
    _setupAnimations();
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

  Future<void> _fetchColleges() async {
    final snapshot = await FirebaseFirestore.instance.collection('colleges').get();
    setState(() {
      _colleges = snapshot.docs.map((doc) => doc['name'].toString()).toList();
    });
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _formController.dispose();
    _rotationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _collegeController.dispose();
    super.dispose();
  }

  Future<void> signup() async {
  try {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _collegeController.text.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-argument',
        message: 'All fields are required.',
      );
    }

    // Check if email already exists in both pending_users and users collections
    final emailQueryPending = await FirebaseFirestore.instance
        .collection('pending_users')
        .where('email', isEqualTo: _emailController.text)
        .get();

    final emailQueryUsers = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: _emailController.text)
        .get();

    if (emailQueryPending.docs.isNotEmpty || emailQueryUsers.docs.isNotEmpty) {
      throw FirebaseAuthException(
        code: 'email-already-registered',
        message: 'This email is already registered. Please verify your email or use a different email.',
      );
    }

    // Create user in Firebase Auth
    UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
    );

    User? user = userCredential.user;

    if (user != null) {
      // Store temporary user data in pending_users collection
      await FirebaseFirestore.instance
          .collection('pending_users')
          .doc(user.uid)
          .set({
        'email': user.email,
        'college': _collegeController.text,
        'createdAt': FieldValue.serverTimestamp(),
        'isEmailVerified': false,
      });

      // Send verification email
      await user.sendEmailVerification();

      // Navigate to email verification page
      Get.offAll(() => const EmailVerificationPage());
    }
  } on FirebaseAuthException catch (e) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text(
          'Registration Error',
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: primaryBlue,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              e.message ?? 'An unknown error occurred.',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Size size,
    bool isPassword = false,
  }) {
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
                    onPressed: () =>
                        setState(() => _isPasswordVisible = !_isPasswordVisible),
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

  Widget _buildRegisterButton(Size size) {
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
          onPressed: signup,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Text(
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
              child: AutofillGroup(
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.05),
                    ScaleTransition(
                      scale: _lottieScaleAnimation,
                      child: Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(math.pi * _lottieScaleAnimation.value * 0.0),
                        alignment: Alignment.center,
                        child: SizedBox(
                          height: size.height * 0.34,
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
                              SizedBox(height: size.height * 0.025),
                              _buildTextField(
                                controller: _emailController,
                                hint: 'College Email',
                                icon: Icons.email_rounded,
                                size: size,
                              ),
                              _buildTextField(
                                controller: _passwordController,
                                hint: 'Password',
                                icon: Icons.lock_rounded,
                                isPassword: true,
                                size: size,
                              ),
                              SearchableDropdown(
                                controller: _collegeController,
                                items: _colleges,
                                hint: 'Select College',
                                icon: Icons.school_rounded,
                                size: size,
                                onSelected: (String value) {
                                  setState(() {
                                    _collegeController.text = value;
                                  });
                                },
                              ),
                              SizedBox(height: size.height * 0.02),
                              _buildRegisterButton(size),
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
      ),
    );
  }
}