import 'package:flutter/material.dart';
import 'package:college_app/login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  RegisterPageState createState() => RegisterPageState(); // Made the state class public
}

// Made the state class public by removing the underscore
class RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isPasswordVisible = false;

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
    super.dispose();
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40), // Space at the top
                  FadeTransition(
                    opacity: _animation,
                    child: Center(
                      child: Image.asset(
                        'assets/images/2.png', // Change this path to your register image
                        width: 600,
                        height: 350,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          FadeTransition(
                            opacity: _animation,
                            child: const Text(
                              'Welcome!',
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
                              decoration: InputDecoration(
                                hintText: 'Enter your full name',
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
                              onPressed: () {
                                // Handle register action
                              },
                              child: const Text(
                                'Register',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account?'),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginPage()),
                                  );
                                },
                                child: const Text(
                                  'Login',
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
