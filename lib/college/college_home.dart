import 'package:college_app/college/voicecollege.dart';
import 'package:college_app/chatBot/chat_bot_ai.dart';
import 'package:college_app/widgets/drawer_college.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:college_app/college/c_notes/college_selection.dart';
import 'package:college_app/college/c_time_table/college.dart';
import 'package:google_fonts/google_fonts.dart';

class CoHomePage extends StatefulWidget {
  const CoHomePage({super.key});

  @override
  State<CoHomePage> createState() => _CoHomePageState();
}

class _CoHomePageState extends State<CoHomePage> {
  final user = FirebaseAuth.instance.currentUser;
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
      "description": "Manage study materials",
    },
    {
      "icon": "assets/images/study-time.png",
      "title": "Time Table",
      "description": "Manage schedules",
    },
  ];

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
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(40),
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
      onTap: () {
        Widget? nextPage = _navigateToPage(index);
        if (nextPage != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => nextPage),
          );
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
      case 0:
        return const CollegeSelectionPage();
      case 1:
        return const CollegePage();
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
      drawer: const AdminDrawer(),
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
                    const SizedBox(height: 20),
                    Text(
                      "Shiksha Hub!",
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ).animate()
                      .fadeIn(duration: 500.ms)
                      .slide(begin: const Offset(-0.2, 0)),
                    SizedBox(height: height * 0.01),
                    Text(
                      "Manage, Monitor, Enhance ..",
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
                  SizedBox(height: height * 0.09),
                  _buildQuickActions(),
                  SizedBox(height: height * 0.09),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add your admin support/help functionality here
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.admin_panel_settings, color: Colors.white),
      ),
    );
  }
}