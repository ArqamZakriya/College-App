import 'package:college_app/admin/adhome.dart';
import 'package:college_app/select_au.dart';
import 'package:flutter/material.dart';

class ADLoginPage extends StatelessWidget {
  const ADLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                            MaterialPageRoute(builder: (context) => const SelectPage()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40), // Space at the top
                  // Image section
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'assets/images/2.png', // Change this path to your login image
                        width: 600,
                        height: 600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Hello! Admin',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Email or Phone TextField
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Email or Phone',
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(color: Colors.white), // Set the border color
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Password TextField
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Enter password',
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(color: Colors.white), // Set the border color
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  // Login button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.lightBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    onPressed: () {
                      // Handle login action
                      Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AdHomePage()),
                          );
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 40), // Space at the bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
