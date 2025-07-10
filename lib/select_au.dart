import 'package:college_app/adlogin.dart';
import 'package:flutter/material.dart';
import 'package:college_app/register.dart';

class SelectPage extends StatelessWidget {
  const SelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top bar with time and icons
                const Padding(
                  padding: EdgeInsets.all(50.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  ),
                ),
                // Image section
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/images/1.png',
                      width: 550,
                      height: 550,
                    ),
                  ),
                ),
                // Bottom section with buttons
                Container(
                  width: double.infinity,
                  color: Colors.lightBlue.shade100,
                  padding: const EdgeInsets.symmetric(
                      vertical: 40.0, horizontal: 20.0),
                  child: Column(
                    children: [
                      const Text(
                        'Select type',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.lightBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ADLoginPage()),
                          );
                        },
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.lightBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterPage()),
                          );
                        },
                        child: const Text(
                          'USER',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Positioned circles at the top left
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
          ],
        ),
      ),
    );
  }
}
