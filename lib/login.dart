import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:college_app/register.dart';
import 'package:college_app/user/u_home.dart';
import 'package:college_app/admin/adhome.dart'; // Import the AdHomePage

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isPasswordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Function to sign in using Firebase Authentication
  Future<void> signIn() async {
    try {
      // Check if the user is an admin with hardcoded credentials
      if (_emailController.text == 'admin@gmail.com' && _passwordController.text == 'admin@123') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdHomePage()),
        );
      } else {
        // Sign in using Firebase Authentication for regular users
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        
        // Navigate to HomePage after successful login
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      // Display error message
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Dismiss keyboard on tap outside
        },
        child: Stack(
          children: [
            // Background decoration
            Positioned(
              top: -25,
              left: -25,
              child: Container(
                width: 130,
                height: 130,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 114, 206, 249),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: -60,
              left: 40,
              child: Container(
                width: 130,
                height: 130,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 88, 145, 242),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 100), // Space at the top
                  FadeTransition(
                    opacity: _animation,
                    child: Center(
                      child: Image.asset(
                        'assets/images/3.png', // Change this path to your login image
                        width: 600,
                        height: 350,
                      ),
                    ),
                  ),
                  const SizedBox(height: 0),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          FadeTransition(
                            opacity: _animation,
                            child: const Text(
                              'Hello! Login Here',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          FadeTransition(
                            opacity: _animation,
                            child: TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                hintText: 'Email or Phone',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          FadeTransition(
                            opacity: _animation,
                            child: TextField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                hintText: 'Enter password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              obscureText: !_isPasswordVisible,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FadeTransition(
                            opacity: _animation,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                backgroundColor: Colors.lightBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                              onPressed: signIn, // Updated to use signIn function
                              child: const Text(
                                'Login',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Don\'t have an account?'),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                                  );
                                },
                                child: const Text(
                                  'Register',
                                  style: TextStyle(
                                    color: Colors.lightBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 60), // Space at the bottom
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
