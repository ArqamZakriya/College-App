
import 'package:college_app/college/a_time_table/semester.dart';
import 'package:college_app/college/ad_home.dart';
// import 'package:college_app/widgets/bottom_navigation_foradmin.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BranchAdmin extends StatelessWidget {
  final String selectedCollege;
  const BranchAdmin({super.key, required this.selectedCollege,});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 12, 215, 246),
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.5),
        leading: InkWell(
          onTap: () {
            // Navigate to AdHomePage using GetX when image is tapped
            Get.to(() => const AdHomePage());
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/partners.png',
              fit: BoxFit.contain,
              height: 50,
            ),
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
            color: Colors.white,
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
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 60.0),
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
                'Select Branch',
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
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: GridView.count(
                    crossAxisCount: 1,
                    childAspectRatio: (2 / .4),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 15,
                    children: [
                      _BranchButton(title: 'AIML', onTap: () {
                        _navigateToSemesterPage(context, 'AIML');
                      }),
                      _BranchButton(title: 'CSE', onTap: () {
                        _navigateToSemesterPage(context, 'CSE');
                      }),
                      _BranchButton(title: 'ISE', onTap: () {
                        _navigateToSemesterPage(context, 'ISE');
                      }),
                      _BranchButton(title: 'ECE', onTap: () {
                        _navigateToSemesterPage(context, 'ECE');
                      }),
                      _BranchButton(title: 'EEE', onTap: () {
                        _navigateToSemesterPage(context, 'EEE');
                      }),
                      _BranchButton(title: 'MECH', onTap: () {
                        _navigateToSemesterPage(context, 'MECH');
                      }),
                      _BranchButton(title: 'CIVIL', onTap: () {
                        _navigateToSemesterPage(context, 'CIVIL');
                      }),
                      _BranchButton(title: 'RAI', onTap: () {
                        _navigateToSemesterPage(context, 'RAI');
                      }),
                      _BranchButton(title: 'Basic Science', onTap: () {
                        _navigateToSemesterPage(context, 'Basic Science');
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSemesterPage(BuildContext context, String branch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SemesterPage(selectedCollege: selectedCollege, branch: branch),
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
            elevation: 0,
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
