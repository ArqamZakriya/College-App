import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:college_app/college/ad_home.dart';
import 'package:college_app/email_verification_page.dart';
import 'package:college_app/user/user_home.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
// import 'package:college_app/widgets/bottom_navigation.dart';
import 'package:college_app/register.dart';
import 'package:college_app/forgot_password.dart';
import 'dart:math' as math;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
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

  // Custom colors
  static const primaryBlue = Color(0xFF1A237E);
  static const accentYellow = Color(0xFFFFD700);
  static const deepBlack = Color(0xFF121212);

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _lottieController.dispose();
    _formController.dispose();
    _rotationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String getErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid college email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact college support.';
      case 'user-not-found':
        return 'No account found. Please register with your college email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid login credentials. Please check your details.';
      case 'invalid-input':
        return 'Please fill in all required fields.';
      case 'operation-not-allowed':
        return 'Login is not enabled. Please contact college support.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  Future<void> signIn() async {
  try {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-input',
        message: 'Please fill in all fields.',
      );
    }

    final UserCredential userCredential = 
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    final User? user = userCredential.user;
    
    if (user == null) {
      throw FirebaseAuthException(
        code: 'null-user',
        message: 'Unable to sign in. Please try again.',
      );
    }

    // Check if the user is an admin
    if (_emailController.text.trim() == 'admin@gmail.com') {
      Get.off(() => const AdHomePage());
      return;
    }

    // For regular users, verify email status
    if (!user.emailVerified) {
      // Check if user exists in pending_users collection
      final pendingDoc = await FirebaseFirestore.instance
          .collection('pending_users')
          .doc(user.uid)
          .get();

      if (pendingDoc.exists) {
        // User registration is pending, redirect to verification
        Get.off(() => const EmailVerificationPage());
      } else {
        // User might have registered before email verification was implemented
        // Create a pending_users document
        await FirebaseFirestore.instance
            .collection('pending_users')
            .doc(user.uid)
            .set({
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'isEmailVerified': false,
        });
        
        // Send verification email
        await user.sendEmailVerification();
        Get.off(() => const EmailVerificationPage());
      }
    } else {
      // Email is verified, check user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // Handle edge case where user is verified but no document exists
        await FirebaseAuth.instance.signOut();
        throw FirebaseAuthException(
          code: 'no-user-record',
          message: 'Account data not found. Please contact support.',
        );
      }

      Get.off(() => const HomePage());
    }
  } on FirebaseAuthException catch (e) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text(
          'Login Error',
          style: TextStyle(
            color: Color(0xFF1A237E),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFF1A237E),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              getErrorMessage(e.code),
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
                color: Color(0xFF1A237E),
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

  Widget _buildLoginButton(Size size) {
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
          onPressed: signIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Text(
            'Login',
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
                            'assets/lottie/login.json',
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
                                  colors: [primaryBlue, Color.fromARGB(255, 234, 26, 168)],
                                ).createShader(bounds),
                                child: Text(
                                  'Welcome Back!',
                                  style: TextStyle(
                                    fontSize: size.width * 0.08,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(height: size.height * 0.01),
                              Text(
                                'Sign in to continue',
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
                              
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => Get.to(() => const Forgot()),
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: size.width * 0.045,
                                    ),
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: size.height * 0.015),
                              _buildLoginButton(size),
                              SizedBox(height: size.height * 0.02),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'New to the college? ',
                                    style: TextStyle(
                                      color: deepBlack.withOpacity(0.6),
                                      fontSize: size.width * 0.04,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Get.to(() => const RegisterPage()),
                                    child: Text(
                                      'Register Now',
                                      style: TextStyle(
                                        color: primaryBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: size.width * 0.045,
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