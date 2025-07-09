
import 'package:college_app/college/a_time_table/select_section.dart';
import 'package:college_app/college/ad_home.dart';
// import 'package:college_app/widgets/bottom_navigation_foradmin.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SemesterPage extends StatelessWidget {
  final String selectedCollege;
  final String branch;

  const SemesterPage({super.key, required this.branch, required this.selectedCollege});

  @override
  Widget build(BuildContext context) {
    // Determine the number of semesters based on the selected branch
    int semesterCount = _getSemesterCount(branch);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 12, 215, 246),
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.5),
        leading: InkWell(
          onTap: () {
            // Navigate to AdHomePage using GetX when image is tapped
            Get.to(() =>  const AdHomePage());
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
        title: Text(
          'Select Semester for $branch',
          style: const TextStyle(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 15,
            ),
            itemCount: semesterCount,
            itemBuilder: (context, index) {
              String semester = branch == 'Basic Science' ? 'Semester ${index + 1}' : 'Semester ${index + 3}';
              return _SemesterButton(
                title: semester,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectSectionPage(
                        selectedCollege: selectedCollege,
                        branch: branch,
                        semester: semester,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // Method to determine the number of semesters based on the branch
  int _getSemesterCount(String branch) {
    switch (branch) {
      case 'Basic Science':
        return 2; // Basic Science has only 2 semesters
      default:
        return 6; // All other branches have 8 semesters
    }
  }
}

class _SemesterButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SemesterButton({required this.title, required this.onTap});

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
