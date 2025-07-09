import 'package:college_app/user/u_time_table/timetable_page.dart';
import 'package:college_app/user/user_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

class SelectSectionPage extends StatefulWidget {
  final String selectedCollege;
  final String branch;
  final String semester;

  const SelectSectionPage({
    super.key, 
    required this.branch, 
    required this.semester, 
    required this.selectedCollege
  });

  @override
  State<SelectSectionPage> createState() => _SelectSectionPageState();
}

class _SelectSectionPageState extends State<SelectSectionPage> 
    with TickerProviderStateMixin {
  late AnimationController _cardsController;
  late AnimationController _backgroundController;
  final List<Bubble> bubbles = List.generate(15, (index) => Bubble());
  
  static const primaryIndigo = Color(0xFF3F51B5);
  static const primaryBlue = Color(0xFF1A237E);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: primaryIndigo,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    
    _cardsController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    _cardsController.forward();
  }

  @override
  void dispose() {
    _cardsController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getSectionData() {
    final List<String> sections = ['A', 'B', 'C', 'D']; // Standard sections
    final List<Map<String, dynamic>> sectionData = [];
    
    for (int i = 0; i < sections.length; i++) {
      sectionData.add({
        'title': 'Section ${sections[i]}',
        'subtitle': 'View timetable for this section',
        'icon': Icons.group,
        'color': i % 2 == 0 ? primaryBlue : primaryIndigo,
      });
    }
    return sectionData;
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double cardHeight = size.height * 0.11;
    final double iconSize = size.width * 0.08;
    final double titleFontSize = size.width * 0.055;
    final double subtitleFontSize = size.width * 0.036;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: primaryIndigo,
          statusBarIconBrightness: Brightness.light,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              AnimatedBackground(
                controller: _backgroundController,
                bubbles: bubbles,
              ),
              Column(
                children: [
                  Container(
                    height: kToolbarHeight + 60,
                    decoration: BoxDecoration(
                      color: primaryIndigo,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: () => Get.to(() => const HomePage()),
                              child: Padding(
                                padding: EdgeInsets.all(size.width * 0.025),
                                child: Image.asset(
                                  'assets/images/partners.png',
                                  height: size.width * 0.08,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                'Shiksha Hub',
                                style: TextStyle(
                                  fontFamily: 'Lobster',
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              color: Colors.white,
                              onPressed: () => Navigator.pop(context),
                              iconSize: size.width * 0.06,
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: size.height * 0.01),
                          child: Text(
                            'Select Section',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: size.width * 0.07,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.04,
                        vertical: size.width * 0.03,
                      ),
                      itemCount: _getSectionData().length,
                      itemBuilder: (context, index) {
                        final section = _getSectionData()[index];
                        return CustomSection(
                          title: section['title'],
                          subtitle: section['subtitle'],
                          icon: section['icon'],
                          color: section['color'],
                          onTap: () => _navigateToTimetablePage(
                            context, 
                            section['title'].split(' ')[1] // Extract the section letter
                          ),
                          index: index,
                          totalItems: _getSectionData().length,
                          animation: _cardsController,
                          cardHeight: cardHeight,
                          iconSize: iconSize,
                          titleFontSize: titleFontSize,
                          subtitleFontSize: subtitleFontSize,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToTimetablePage(BuildContext context, String section) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserTimetablePage(
          selectedCollege: widget.selectedCollege,
          branch: widget.branch,
          semester: widget.semester,
          section: section,
        ),
      ),
    );
  }
}

class Bubble {
  double x = math.Random().nextDouble() * 1.5 - 0.2;
  double y = math.Random().nextDouble() * 1.2 - 0.2;
  double size = math.Random().nextDouble() * 20 + 5;
  double speed = math.Random().nextDouble() * 0.5 + 0.1;
}

class AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  final List<Bubble> bubbles;

  const AnimatedBackground({
    super.key,
    required this.controller,
    required this.bubbles,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: BubblePainter(
            bubbles: bubbles,
            animation: controller,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class BubblePainter extends CustomPainter {
  final List<Bubble> bubbles;
  final Animation<double> animation;

  BubblePainter({required this.bubbles, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    for (var bubble in bubbles) {
      final paint = Paint()
        ..color = const Color(0xFF3F51B5).withOpacity(0.1)
        ..style = PaintingStyle.fill;

      final position = Offset(
        (bubble.x * size.width + animation.value * bubble.speed * size.width) % size.width,
        (bubble.y * size.height + animation.value * bubble.speed * size.height) % size.height,
      );

      canvas.drawCircle(position, bubble.size, paint);
    }
  }

  @override
  bool shouldRepaint(BubblePainter oldDelegate) => true;
}

class CustomSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int index;
  final int totalItems;
  final Animation<double> animation;
  final double cardHeight;
  final double iconSize;
  final double titleFontSize;
  final double subtitleFontSize;

  const CustomSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.index,
    required this.totalItems,
    required this.animation,
    required this.cardHeight,
    required this.iconSize,
    required this.titleFontSize,
    required this.subtitleFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double intervalStart = (index / totalItems) * 0.6;
        final double intervalEnd = intervalStart + (0.4 / totalItems);

        final slideAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Interval(
              intervalStart,
              intervalEnd,
              curve: Curves.easeOutCubic,
            ),
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: cardHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.9),
                      color.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: cardHeight * 0.75,
                      height: cardHeight * 0.75,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        icon,
                        size: iconSize,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: subtitleFontSize,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: iconSize * 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}