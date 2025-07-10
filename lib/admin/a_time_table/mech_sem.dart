import 'package:college_app/login.dart';
import 'package:college_app/admin/adhome.dart';
import 'package:flutter/material.dart';

class MechSem extends StatelessWidget {
  const MechSem({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 12, 215, 246),
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.5),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Flexible(
                child: Image.asset(
                  'assets/images/partners.png',
                  fit: BoxFit.contain,
                  height: 50,
                ),
              ),
            ],
          ),
        ),
        title: const Text(
          'Shiksha Hub',
          style: TextStyle(
            fontFamily: 'Lobster',
            fontSize: 22,
            color: Color.fromARGB(255, 219, 64, 25),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: Colors.white, // Set your desired color here
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 12, 215, 246),
                Color.fromARGB(255, 0, 123, 255)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20), // Reduced height
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 15.0, horizontal: 60.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 0, 250, 63),
                    Color.fromARGB(255, 0, 150, 100)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(0, 4),
                    blurRadius: 8.0,
                  ),
                ],
                border: Border.all(
                  color: const Color.fromARGB(255, 0, 100, 50),
                  width: 2.0,
                ),
              ),
              child: const Text(
                'Select Semister',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(2, 2),
                      color: Colors.black54,
                      blurRadius: 4.0,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // Reduced height
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 25.0), // Adjust padding as needed
                child: Padding(
                  padding: const EdgeInsets.only(
                      bottom:
                          5.0), // Padding between grid and bottom navigation bar
                  child: GridView.count(
                    crossAxisCount: 1,
                    childAspectRatio: (2 / .4),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 15,
                    children: [
                      _BranchButton(title: 'III', onTap: () {}),
                      _BranchButton(title: 'IV', onTap: () {}),
                      _BranchButton(title: 'V', onTap: () {}),
                      _BranchButton(title: 'VI', onTap: () {}),
                      _BranchButton(title: 'VII', onTap: () {}),
                      _BranchButton(title: 'VIII', onTap: () {}),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Theme(
        data: ThemeData(
          canvasColor: const Color.fromARGB(255, 97, 169, 228),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            selectedItemColor: Color.fromARGB(255, 3, 3, 3),
            unselectedItemColor: Colors.white,
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

class _BranchButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _BranchButton({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.identity()
        ..rotateX(0.1)
        ..rotateY(0.1),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(118, 12, 215, 246),
              Color.fromARGB(107, 0, 123, 255),
              Color.fromARGB(118, 12, 246, 184)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 4),
              blurRadius: 8.0,
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            padding: const EdgeInsets.all(20.0),
            elevation:
                0, // Remove elevation to avoid shadow conflict with Container
          ),
          onPressed: onTap,
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'PT_Serif',
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
