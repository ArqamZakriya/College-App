import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:college_app/wrapper.dart';
import 'package:lottie/lottie.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool isEmailVerified = false;
  bool canResendEmail = true;
  Timer? timer;
  Timer? countdownTimer;
  int remainingSeconds = 60;
  static const primaryBlue = Color(0xFF1A237E);

  @override
  void initState() {
    super.initState();
    
    isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    
    if (!isEmailVerified) {
      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      
      setState(() {
        isEmailVerified = user?.emailVerified ?? false;
      });

      if (isEmailVerified && user != null) {
        timer?.cancel();
        
        // Get pending user data
        final pendingUserDoc = await FirebaseFirestore.instance
            .collection('pending_users')
            .doc(user.uid)
            .get();

        if (pendingUserDoc.exists) {
          try {
            // Start a batch write to ensure atomicity
            final batch = FirebaseFirestore.instance.batch();
            
            // Create document in users collection
            final userRef = FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid);
                
            batch.set(userRef, {
              ...pendingUserDoc.data()!,
              'isEmailVerified': true,
              'verifiedAt': FieldValue.serverTimestamp(),
            });
            
            // Delete from pending_users collection
            final pendingRef = FirebaseFirestore.instance
                .collection('pending_users')
                .doc(user.uid);
                
            batch.delete(pendingRef);
            
            // Commit the batch
            await batch.commit();
            
            // Only navigate after successful data transfer
            Get.offAll(() => const Wrapper());
          } catch (e) {
            Get.snackbar(
              'Error',
              'Failed to complete registration. Please try again.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not verify email status. Please try again later.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      
      setState(() {
        canResendEmail = false;
        remainingSeconds = 60;
      });
      
      countdownTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          setState(() {
            if (remainingSeconds > 0) {
              remainingSeconds--;
            } else {
              canResendEmail = true;
              countdownTimer?.cancel();
            }
          });
        },
      );
      
      Get.snackbar(
        'Email Sent',
        'Verification email has been sent. Please check your inbox.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: primaryBlue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send verification email. Please try again later.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text(
          'Email Verification',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              timer?.cancel();
              countdownTimer?.cancel();
              await FirebaseAuth.instance.signOut();
              Get.offAll(() => const Wrapper());
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                height: 200,
                child: Lottie.asset(
                  'assets/lottie/email.json',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Verify your email',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'We\'ve sent you a verification email.\nPlease check your inbox and verify your email address.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.email, color: Colors.white),
              label: Text(
                canResendEmail 
                    ? 'Resend Email' 
                    : 'Wait ${remainingSeconds}s',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              onPressed: canResendEmail ? resendVerificationEmail : null,
            ),
          ],
        ),
      ),
    );
  }
}