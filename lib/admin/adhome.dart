import 'package:college_app/admin/a_notes/select_branch_ad.dart';
import 'package:college_app/admin/a_time_table/select_branch_page_ad.dart';
// ignore: unused_import
import 'package:college_app/login.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: AdHomePage(),
  ));
}

class AdHomePage extends StatelessWidget {
  const AdHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Positioned circles at the top left
            const Positioned(
              top: -25,
              left: -25,
              child: CircleAvatar(
                radius: 65,
                backgroundColor: Color.fromARGB(255, 114, 206, 249),
              ),
            ),
            const Positioned(
              top: -60,
              left: 40,
              child: CircleAvatar(
                radius: 65,
                backgroundColor: Color.fromARGB(255, 88, 145, 242),
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
                        const SizedBox(height: 30),
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
                                backgroundImage: AssetImage('assets/images/partners.png'),
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
                        const SizedBox(height:50),
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            children: [
                              _GridItem(
                                title: 'Notes Upload',
                                imagePath: 'assets/images/edit.png',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SelectBranchAd(),
                                  ),
                                ),
                              ),
                              _GridItem(
                                title: 'Time Table Upload',
                                imagePath: 'assets/images/study-time.png',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SelectBranchPageAd(),
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
            unselectedItemColor: Colors.white,// Unselected item color
          ),
        ),
        child: BottomNavigationBar(
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdHomePage(),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
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
                  fontSize: 18,
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

// Placeholder pages for navigation
class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: const Center(child: Text('Notes Page')),
    );
  }
}

class TimeTablePage extends StatelessWidget {
  const TimeTablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Time Table')),
      body: const Center(child: Text('Time Table Page')),
    );
  }
}



class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: const Center(child: Text('Account Page')),
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
