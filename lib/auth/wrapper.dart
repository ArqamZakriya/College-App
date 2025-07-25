import 'package:college_app/admin/home.dart';
import 'package:college_app/auth/email_verification_page.dart';
import 'package:college_app/college/college_home.dart';

import 'package:college_app/auth/login.dart';
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
        
        // Special case for admin - check if admin exists in new structure
        if (user.email == "admin@gmail.com") {
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc('admin')
                .collection('data')
                .doc(user.uid)
                .snapshots(),
            builder: (context, adminSnapshot) {
              if (adminSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (adminSnapshot.hasData && adminSnapshot.data!.exists) {
                return const AdminDashboard();
              }

              // Admin document doesn't exist, sign out
              FirebaseAuth.instance.signOut();
              return const LoginPage();
            },
          );
        }

        // For all other users, check if they need OTP verification
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('user_metadata')
              .doc(user.uid)
              .snapshots(),
          builder: (context, metadataSnapshot) {
            if (metadataSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!metadataSnapshot.hasData || !metadataSnapshot.data!.exists) {
              // No metadata found, sign out
              FirebaseAuth.instance.signOut();
              return const LoginPage();
            }

            final metadataData = metadataSnapshot.data!.data() as Map<String, dynamic>;
            final String userType = metadataData['userType'] ?? '';
            final String accountStatus = metadataData['accountStatus'] ?? '';

            // Check if account is pending verification
            if (accountStatus == 'pending_verification') {
              return OtpVerificationPage(
                userId: user.uid,
                email: user.email ?? '', userType: '',
              );
            }

            // Check if account is inactive
            if (accountStatus != 'active') {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.block,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Account Inactive',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your account is currently inactive.\nPlease contact the administrator.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          FirebaseAuth.instance.signOut();
                        },
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Route based on user type
            switch (userType) {
              case 'student':
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc('students')
                      .collection('data')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, studentSnapshot) {
                    if (studentSnapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (studentSnapshot.hasData && studentSnapshot.data!.exists) {
                      return const HomePage();
                    }

                    // Student document doesn't exist, sign out
                    FirebaseAuth.instance.signOut();
                    return const LoginPage();
                  },
                );

              case 'college_staff':
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc('college_staff')
                      .collection('data')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, staffSnapshot) {
                    if (staffSnapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (staffSnapshot.hasData && staffSnapshot.data!.exists) {
                      return const CoHomePage();
                    }

                    // Staff document doesn't exist, sign out
                    FirebaseAuth.instance.signOut();
                    return const LoginPage();
                  },
                );

              case 'admin':
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc('admin')
                      .collection('data')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, adminSnapshot) {
                    if (adminSnapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (adminSnapshot.hasData && adminSnapshot.data!.exists) {
                      return const AdminDashboard();
                    }

                    // Admin document doesn't exist, sign out
                    FirebaseAuth.instance.signOut();
                    return const LoginPage();
                  },
                );

              default:
                // Unknown user type, sign out
                FirebaseAuth.instance.signOut();
                return const LoginPage();
            }
          },
        );
      },
    );
  }
}