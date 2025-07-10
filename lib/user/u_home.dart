import 'package:college_app/login.dart';
import 'package:college_app/user/cgpa.dart';
import 'package:college_app/user/result.dart';
import 'package:college_app/user/u_time_table/select_branch_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:college_app/user/u_notes/select_branch.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
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
            Column(
              children: [
                const SizedBox(height: 20), // Adjust this value to bring down the app bar
                AppBar(
                  title: const Text('Home'),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: const Icon(Icons.menu),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {},
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 228, 227, 227),
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(height: 100),
                              CircleAvatar(
                                radius: 30,
                                backgroundImage:
                                    AssetImage('assets/images/partners.png'),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Welcome to Siksha Hub!',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 50),
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            children: [
                              _GridItem(
                                title: 'Notes',
                                imagePath: 'assets/images/edit.png',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SelectBranch(),
                                  ),
                                ),
                              ),
                              _GridItem(
                                title: 'Time Table',
                                imagePath: 'assets/images/study-time.png',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SelectBranchPage(),
                                  ),
                                ),
                              ),
                              _GridItem(
                                title: 'Result',
                                imagePath: 'assets/images/result.png',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ResultPage(),
                                  ),
                                ),
                              ),
                              _GridItem(
                                title: 'CGPA Calculator',
                                imagePath: 'assets/images/calculator.png',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CgpaSgpaPage(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Theme(
        data: ThemeData(
          canvasColor: const Color.fromARGB(255, 97, 169, 228), // Background color
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            selectedItemColor: Color.fromARGB(255, 3, 3, 3), // Selected item color
            unselectedItemColor: Colors.white, // Unselected item color
          ),
        ),
        child: BottomNavigationBar(
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomePage(),
                  ),
                );
                break;
              case 1:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountPage(),
                  ),
                );
                break;
              case 2:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VoiceCommandPage(),
                  ),
                );
                break;
              case 3:
                // Correct Logout Functionality
                FirebaseAuth.instance.signOut().then((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                  );
                });
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(IconData(0xee67, fontFamily: 'MaterialIcons')),
              label: 'Bot',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.logout),
              label: 'LogOut',
            ),
          ],
        ),
      ),
    );
  }
}


class _GridItem extends StatelessWidget {
  const _GridItem({
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  final String title;
  final String imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(imagePath, width: 80, height: 80),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignOutPage extends StatelessWidget {
  const SignOutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: const Center(child: Text('Signed Out')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        },
        child: const Icon(Icons.login_rounded),
      ),
    );
  }
}

class VoiceCommandPage extends StatelessWidget {
  const VoiceCommandPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Command')),
      body: const Center(child: Text('Voice Command Page')),
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Page')),
      body: const Center(child: Text('Account Page')),
    );
  }
}

