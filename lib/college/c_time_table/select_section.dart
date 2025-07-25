import 'package:college_app/college/college_home.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:college_app/college/c_time_table/timetable_page.dart';
// import 'package:college_app/widgets/bottom_navigation_foradmin.dart';

class SelectSectionPage extends StatelessWidget {
  final String selectedCollege;
  final String branch;
  final String semester;

  const SelectSectionPage({super.key, required this.branch, required this.semester, required this.selectedCollege});

  @override
  Widget build(BuildContext context) {
    List<String> sections = getsections(branch, semester);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 12, 215, 246),
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.5),
        leading: InkWell(
          onTap: () {
            Get.to(() => const CoHomePage());
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
          'Select section for $branch - $semester',
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
          child: ListView.builder(
            itemCount: sections.length,
            itemBuilder: (context, index) {
              return _SectionButton(
                title: sections[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TimetablePage(
                        selectedCollege: selectedCollege,
                        branch: branch,
                        semester: semester,
                        section: sections[index], // Pass the correct section
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

  List<String> getsections(String branch, String semester) {
    return ['A', 'B', 'C', 'D']; // Update as needed
  }
}

class _SectionButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SectionButton({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
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
          padding: const EdgeInsets.symmetric(vertical: 15.0),
        ),
        onPressed: onTap,
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Lobster',
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
