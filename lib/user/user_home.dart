import 'package:college_app/widgets/drawer_user.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:college_app/user/cgpa.dart';
import 'package:college_app/user/result.dart';
import 'package:college_app/user/u_notes/select_branch.dart';
import 'package:college_app/user/u_time_table/branch.dart';
import 'package:college_app/chatBot/chat_bot_ai.dart';
import 'package:college_app/user/voice.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;
  // ignore: unused_field
  final int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> menuItems = [
    {
      "icon": "assets/images/edit.png",
      "title": "Notes",
      "description": "Access your study materials",
    },
    {
      "icon": "assets/images/study-time.png",
      "title": "Time Table",
      "description": "View your schedule",
    },
    {
      "icon": "assets/images/result.png",
      "title": "Result",
      "description": "Check your results",
    },
    {
      "icon": "assets/images/calculator.png",
      "title": "CGPA Calsi",
      "description": "Calculate your CGPA",
    },
  ];

  Widget _buildShimmerTitle() {
    return Shimmer.fromColors(
      baseColor: Colors.white,
      highlightColor: const Color.fromARGB(255, 63, 58, 58),
      period: const Duration(seconds: 4),
      child: Text(
        "Shiksha Hub!",
        style: GoogleFonts.poppins(
          fontSize: 32,
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Actions",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionItem(
                  Icons.mic,
                  "Voice\nAssistant",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VoicePage()),
                  ),
                ),
                _buildQuickActionItem(
                  Icons.chat_bubble,
                  "Chat\nBot",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatBot()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.indigo),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(int index, double width) {
    final item = menuItems[index];
    return InkWell(
      onTap: () async {
        if (index == 0 || index == 1) {
          if (user != null) {
            try {
              final userData = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .get();
              
              if (userData.exists) {
                String userCollege = userData.data()?['college'] ?? '';
                if (userCollege.isNotEmpty) {
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => index == 0
                          ? SelectBranch(selectedCollege: userCollege)
                          : BranchUser(selectedCollege: userCollege),
                    ),
                  );
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: College information not found')),
                  );
                }
              }
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${e.toString()}')),
              );
            }
          }
        } else {
          Widget? nextPage = _navigateToPage(index);
          if (nextPage != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => nextPage),
            );
          }
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: 8,
          horizontal: width * 0.05,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              item["icon"],
              width: width * 0.2,
              height: width * 0.2,
            ).animate()
              .fadeIn(duration: 600.ms)
              .scale(delay: 200.ms),
            SizedBox(height: width * 0.03),
            Text(
              item["title"],
              style: GoogleFonts.poppins(
                fontSize: width * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ).animate().fadeIn(delay: 300.ms),
            SizedBox(height: width * 0.015),
            Text(
              item["description"],
              style: GoogleFonts.poppins(
                fontSize: width * 0.035,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget? _navigateToPage(int index) {
    switch (index) {
      case 2:
        return const ResultPage();
      case 3:
        return const CgpaSgpaPage();
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final paddingTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.indigo,
      drawer: const CustomDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: height * 0.25,
            floating: false,
            pinned: true,
            backgroundColor: Colors.indigo,
            elevation: 0,
            leadingWidth: 70,
            leading: Builder(
              builder: (context) => Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: IconButton(
                  icon: const Icon(
                    Icons.sort,
                    color: Colors.white,
                    size: 45,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
            title: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 15
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: EdgeInsets.fromLTRB(
                  width * 0.08,
                  paddingTop + height * 0.08,
                  width * 0.08,
                  height * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    _buildShimmerTitle().animate()
                      .fadeIn(duration: 500.ms)
                      .slide(begin: const Offset(-0.2, 0)),
                    SizedBox(height: height * 0.01),
                    Text(
                      "Learn, Grow, Excel ..",
                      style: GoogleFonts.poppins(
                        fontSize: width * 0.04,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 5,
                        fontWeight: FontWeight.w300,
                      ),
                    ).animate()
                      .fadeIn(delay: 300.ms)
                      .slide(begin: const Offset(-0.2, 0)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: height * 0.01),
                  GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.95,
                      mainAxisSpacing: height * 0.02,
                      crossAxisSpacing: width * 0.02,
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      return _buildCard(index, width);
                    },
                  ),
                  SizedBox(height: height * 0.03),
                  _buildQuickActions(),
                  SizedBox(height: height * 0.03),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatBot()),
          );
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.help_outline, color: Colors.white),
      ),
    );
  }
}