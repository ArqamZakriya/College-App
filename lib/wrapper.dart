import 'package:college_app/college/ad_home.dart';
import 'package:college_app/email_verification_page.dart';
import 'package:college_app/login.dart';
import 'package:college_app/user/user_home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
Widget build(BuildContext context) {
  return StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (!snapshot.hasData || snapshot.data == null) {
        return const LoginPage();
      }

      final User user = snapshot.data!;
      
      // Special case for admin
      if (user.email == "admin@gmail.com") {
        return const AdHomePage();
      }

      // For all other users, strictly enforce email verification
      if (!user.emailVerified) {
        return const EmailVerificationPage();
      }

      // Email is verified, check user document
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            return const HomePage();
          }

          // No user document found, sign out
          FirebaseAuth.instance.signOut();
          return const LoginPage();
        },
      );
    },
  );
}
}