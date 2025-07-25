import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:college_app/auth/email_service.dart';
import 'package:college_app/auth/wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class OtpVerificationPage extends StatefulWidget {
  final String userId;
  final String email;
  final String userType;

  const OtpVerificationPage({
    super.key,
    required this.userId,
    required this.email,
    required this.userType,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage>
    with TickerProviderStateMixin {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  bool _canResendOtp = false;
  int _remainingSeconds = 60;
  Timer? _resendTimer;
  String? _errorMessage;
  String? _successMessage;

  late AnimationController _bounceController;
  late AnimationController _shakeController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _shakeAnimation;

  static const primaryBlue = Color(0xFF1A237E);
  static const lightBlue = Color(0xFF3F51B5);
  static const backgroundColor = Color(0xFFF8F9FB);

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _setupAnimations();
    _setupFocusListeners();
  }

  void _setupAnimations() {
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  void _setupFocusListeners() {
    for (int i = 0; i < _otpFocusNodes.length; i++) {
      _otpFocusNodes[i].addListener(() {
        if (_otpFocusNodes[i].hasFocus) {
          _otpControllers[i].selection = TextSelection.fromPosition(
            TextPosition(offset: _otpControllers[i].text.length),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    _resendTimer?.cancel();
    _bounceController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResendOtp = false;
      _remainingSeconds = 60;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _canResendOtp = true;
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> _resendOtp() async {
    if (!_canResendOtp) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final newOtp = (Random().nextInt(900000) + 100000).toString();
      final collectionPath = widget.userType == 'student' 
          ? 'pending_students' 
          : 'college_staff';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(collectionPath)
          .collection('data')
          .doc(widget.userId)
          .update({
        'verificationOtp': newOtp,
        'otpCreatedAt': FieldValue.serverTimestamp(),
      });

      final otpSent = await EmailService.sendOtpEmail(widget.email, newOtp);

      if (!otpSent) {
        throw Exception('Failed to send OTP email');
      }

      _startResendTimer();
      _clearOtpFields();

      setState(() {
        _successMessage = 'A new OTP has been sent to your email';
      });

      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _successMessage = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to resend OTP. Please try again.';
      });
      _shakeController.forward().then((_) => _shakeController.reset());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearOtpFields() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    FocusScope.of(context).requestFocus(_otpFocusNodes[0]);
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final enteredOtp = _otpControllers.map((c) => c.text).join();

      if (enteredOtp.length != 6) {
        throw Exception('Please enter a valid 6-digit OTP');
      }

      // Determine the collection path based on user type
      final collectionPath = widget.userType == 'student' 
          ? 'pending_students' 
          : 'college_staff';

      // Get user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(collectionPath)
          .collection('data')
          .doc(widget.userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found. Please register again.');
      }

      final storedOtp = userDoc['verificationOtp'] as String?;
      final otpCreatedAt = userDoc['otpCreatedAt'] as Timestamp?;

      if (storedOtp == null || otpCreatedAt == null) {
        throw Exception('OTP not found. Please request a new OTP.');
      }

      final now = DateTime.now();
      final otpExpiryTime = otpCreatedAt.toDate().add(const Duration(minutes: 10));

      if (now.isAfter(otpExpiryTime)) {
        throw Exception('OTP has expired. Please request a new one.');
      }

      if (enteredOtp != storedOtp) {
        throw Exception('Invalid OTP. Please try again.');
      }

      _bounceController.forward().then((_) => _bounceController.reverse());
      await _completeVerification();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      _shakeController.forward().then((_) => _shakeController.reset());
      _clearOtpFields();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeVerification() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final user = FirebaseAuth.instance.currentUser;

      if (widget.userType == 'student') {
        // Handle student verification
        final pendingRef = FirebaseFirestore.instance
            .collection('users')
            .doc('pending_students')
            .collection('data')
            .doc(widget.userId);

        final studentRef = FirebaseFirestore.instance
            .collection('users')
            .doc('students')
            .collection('data')
            .doc(widget.userId);

        final pendingDoc = await pendingRef.get();

        batch.set(studentRef, {
          ...pendingDoc.data()!,
          'isEmailVerified': true,
          'isActive': true,
          'accountStatus': 'active',
          'verifiedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        batch.delete(pendingRef);

        // Verify email in Firebase Auth
        if (user != null) {
          await user.sendEmailVerification();
        }
      } else if (widget.userType == 'college_staff') {
        // Handle college staff verification
        final staffRef = FirebaseFirestore.instance
            .collection('users')
            .doc('college_staff')
            .collection('data')
            .doc(widget.userId);

        batch.update(staffRef, {
          'isEmailVerified': true,
          'isActive': true,
          'accountStatus': 'active',
          'verifiedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Verify email in Firebase Auth
        if (user != null) {
          await user.sendEmailVerification();
        }
      }

      // Update metadata for both user types
      final metadataRef = FirebaseFirestore.instance
          .collection('user_metadata')
          .doc(widget.userId);

      batch.update(metadataRef, {
        'accountStatus': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      setState(() {
        _successMessage = 'Email verified successfully! Welcome to the platform.';
      });

      await Future.delayed(const Duration(seconds: 2));
      Get.offAll(() => const Wrapper());
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to complete verification. Please try again.';
      });
    }
  }

  void _handleOtpInput(String value, int index) {
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (value.length > 1) {
      _handlePastedOtp(value, index);
      return;
    }

    _otpControllers[index].text = value;

    if (value.isNotEmpty && index < _otpControllers.length - 1) {
      FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
    }

    if (index == _otpControllers.length - 1 && value.isNotEmpty) {
      final isComplete = _otpControllers.every((controller) => controller.text.isNotEmpty);
      if (isComplete) {
        FocusScope.of(context).unfocus();
        _verifyOtp();
      }
    }
  }

  void _handlePastedOtp(String pastedText, int startIndex) {
    final digits = pastedText.replaceAll(RegExp(r'[^0-9]'), '');
    
    for (int i = 0; i < digits.length && (startIndex + i) < _otpControllers.length; i++) {
      _otpControllers[startIndex + i].text = digits[i];
    }

    final lastFilledIndex = startIndex + digits.length - 1;
    if (lastFilledIndex < _otpControllers.length - 1) {
      FocusScope.of(context).requestFocus(_otpFocusNodes[lastFilledIndex + 1]);
    } else {
      FocusScope.of(context).unfocus();
      if (_otpControllers.every((controller) => controller.text.isNotEmpty)) {
        _verifyOtp();
      }
    }
  }

  Future<void> _handleCancel() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Verification?'),
        content: const Text(
          'Are you sure you want to cancel the email verification?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, Continue'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      try {
        setState(() => _isLoading = true);
        
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          if (widget.userType == 'student') {
            final batch = FirebaseFirestore.instance.batch();

            final pendingRef = FirebaseFirestore.instance
                .collection('users')
                .doc('pending_students')
                .collection('data')
                .doc(user.uid);

            batch.delete(pendingRef);

            final metadataRef = FirebaseFirestore.instance
                .collection('user_metadata')
                .doc(user.uid);

            batch.delete(metadataRef);

            await batch.commit();
            await user.delete();
          } else {
            await FirebaseAuth.instance.signOut();
          }
        }
      } catch (e) {
        print('Error during cleanup: $e');
        await FirebaseAuth.instance.signOut();
      } finally {
        Get.offAll(() => const Wrapper());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: primaryBlue, size: 18),
          ),
          onPressed: () => _handleCancel(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: () => _handleCancel(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _bounceAnimation.value,
                    child: Container(
                      height: 180,
                      width: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(90),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Lottie.asset(
                        'assets/lottie/email.json',
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'We\'ve sent a 6-digit verification code to\n'),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: (_errorMessage != null || _successMessage != null) ? 60 : 0,
                child: AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(sin(_shakeAnimation.value * pi * 4) * 5, 0),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _errorMessage != null 
                              ? Colors.red.shade50 
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _errorMessage != null 
                                ? Colors.red.shade200 
                                : Colors.green.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _errorMessage != null ? Icons.error_outline : Icons.check_circle_outline,
                              color: _errorMessage != null ? Colors.red : Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage ?? _successMessage ?? '',
                                style: TextStyle(
                                  color: _errorMessage != null ? Colors.red.shade700 : Colors.green.shade700,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return Container(
                      width: 45,
                      height: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _otpControllers[index].text.isNotEmpty
                              ? primaryBlue
                              : Colors.grey.shade300,
                          width: _otpFocusNodes[index].hasFocus ? 2 : 1,
                        ),
                        color: _otpControllers[index].text.isNotEmpty
                            ? primaryBlue.withOpacity(0.05)
                            : Colors.grey.shade50,
                      ),
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _otpFocusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _otpControllers[index].text.isNotEmpty
                              ? primaryBlue
                              : Colors.grey.shade600,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                        ),
                        onChanged: (value) => _handleOtpInput(value, index),
                      ),
                    );
                  }),
                ),
              ),
              
              const SizedBox(height: 40),
              
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [primaryBlue, lightBlue],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isLoading ? null : _verifyOtp,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify OTP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    if (!_canResendOtp) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer_outlined, 
                               color: Colors.grey.shade600, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Resend code in $_remainingSeconds seconds',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      TextButton.icon(
                        onPressed: _resendOtp,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Resend OTP'),
                        style: TextButton.styleFrom(
                          foregroundColor: primaryBlue,
                          backgroundColor: primaryBlue.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, 
                             color: Colors.grey.shade500, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Code expires in 10 minutes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}