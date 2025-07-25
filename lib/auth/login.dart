import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:college_app/admin/home.dart';
import 'package:college_app/auth/email_service.dart';
import 'package:college_app/auth/email_verification_page.dart';
import 'package:college_app/college/college_home.dart';
import 'package:college_app/user/user_home.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:college_app/auth/register.dart';
import 'package:college_app/auth/forgot_password.dart';
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
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Custom colors
  static const primaryBlue = Color(0xFF1A237E);
  static const accentYellow = Color(0xFFFFD700);
  static const deepBlack = Color(0xFF121212);

  @override
  void initState() {
    super.initState();
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
      case 'account-inactive':
        return 'Your account is inactive. Please contact the administrator.';
      case 'no-user-record':
        return 'Account data not found. Please contact support.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  Future<void> signIn() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-input',
          message: 'Please fill in all fields.',
        );
      }

      // Direct admin access without Firebase auth - bypass all checks
      if (_emailController.text.trim() == 'admin@gmail.com' && 
          _passwordController.text == 'admin@123') {
        Get.off(() => const AdminDashboard());
        return;
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

      // Check user metadata first
      final metadataDoc = await FirebaseFirestore.instance
          .collection('user_metadata')
          .doc(user.uid)
          .get();

      if (!metadataDoc.exists) {
        await FirebaseAuth.instance.signOut();
        throw FirebaseAuthException(
          code: 'no-user-record',
          message: 'Account not found in system. Please register again.',
        );
      }

      final metadataData = metadataDoc.data() as Map<String, dynamic>;
      final String userType = metadataData['userType'] ?? '';
      final String accountStatus = metadataData['accountStatus'] ?? '';

      // Handle pending verification for both students and college staff
      if (accountStatus == 'pending_verification') {
        String collectionPath = '';
        if (userType == 'student') {
          collectionPath = 'pending_students';
        } else if (userType == 'college_staff') {
          collectionPath = 'college_staff';
        }

        if (collectionPath.isNotEmpty) {
          final pendingDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(collectionPath)
              .collection('data')
              .doc(user.uid)
              .get();

          if (pendingDoc.exists) {
            final pendingData = pendingDoc.data() as Map<String, dynamic>;
            final String storedEmail = pendingData['email'] ?? user.email ?? '';
            
            // Generate new OTP
            final newOtp = (math.Random().nextInt(900000) + 100000).toString();
            
            // Update OTP in Firestore
            await pendingDoc.reference.update({
              'verificationOtp': newOtp,
              'otpCreatedAt': FieldValue.serverTimestamp(),
            });

            // Send new OTP
            await EmailService.sendOtpEmail(storedEmail, newOtp);

            Get.off(() => OtpVerificationPage(
              userId: user.uid,
              email: storedEmail,
              userType: userType,
            ));
            return;
          }
        }
      }

      if (accountStatus != 'active') {
        await FirebaseAuth.instance.signOut();
        throw FirebaseAuthException(
          code: 'account-inactive',
          message: 'Your account is inactive. Please contact the administrator.',
        );
      }

      // Route based on user type
      switch (userType) {
        case 'student':
          final studentDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc('students')
              .collection('data')
              .doc(user.uid)
              .get();

          if (!studentDoc.exists) {
            await FirebaseAuth.instance.signOut();
            throw FirebaseAuthException(
              code: 'no-user-record',
              message: 'Student account data not found.',
            );
          }

          Get.off(() => const HomePage());
          break;

        case 'college_staff':
          final staffDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc('college_staff')
              .collection('data')
              .doc(user.uid)
              .get();

          if (!staffDoc.exists) {
            await FirebaseAuth.instance.signOut();
            throw FirebaseAuthException(
              code: 'no-user-record',
              message: 'College staff account data not found.',
            );
          }

          Get.off(() => const CoHomePage());
          break;

        case 'admin':
          final adminDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc('admin')
              .collection('data')
              .doc(user.uid)
              .get();

          if (!adminDoc.exists) {
            await FirebaseAuth.instance.signOut();
            throw FirebaseAuthException(
              code: 'no-user-record',
              message: 'Admin account data not found.',
            );
          }

          Get.off(() => const AdminDashboard());
          break;

        default:
          await FirebaseAuth.instance.signOut();
          throw FirebaseAuthException(
            code: 'no-user-record',
            message: 'Invalid user type. Please contact support.',
          );
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
    } catch (e) {
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: const Text(
            'Error',
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
                'An unexpected error occurred. Please try again.',
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
    } finally {
      setState(() => _isLoading = false);
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
          onPressed: _isLoading ? null : signIn,
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