import 'package:college_app/user/u_notes/pdf_viewer_screen.dart';
import 'package:college_app/user/user_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

class ViewPdfUserPage extends StatefulWidget {
  final String selectedCollege;
  final String branch;
  final String semester;
  final String subject;
  final String module;

  const ViewPdfUserPage({
    super.key,
    required this.selectedCollege,
    required this.branch,
    required this.semester,
    required this.subject,
    required this.module,
  });

  @override
  State<ViewPdfUserPage> createState() => _ViewPdfPageState();
}

class _ViewPdfPageState extends State<ViewPdfUserPage> with TickerProviderStateMixin {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> pdfData = [];
  bool isLoading = true;
  bool hasData = false;
  
  late AnimationController _cardsController;
  late AnimationController _backgroundController;
  final List<Bubble> bubbles = List.generate(15, (index) => Bubble());

  static const primaryColor = Color(0xFF3F51B5);
  static const secondaryColor = Color(0xFF1A237E);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: primaryColor,
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
    
    getFilteredPdfs();
  }

  @override
  void dispose() {
    _cardsController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> getFilteredPdfs() async {
    try {
      final querySnapshot = await _firebaseFirestore
          .collection("notes")
          .where("college", isEqualTo: widget.selectedCollege)
          .where("branch", isEqualTo: widget.branch)
          .where("semester", isEqualTo: widget.semester)
          .where("subject", isEqualTo: widget.subject)
          .where("module", isEqualTo: widget.module)
          .get();

      setState(() {
        pdfData = querySnapshot.docs.map((e) => e.data() as Map<String, dynamic>).toList();
        hasData = pdfData.isNotEmpty;
      });
    } catch (e) {
      print("Error fetching PDFs: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double cardHeight = size.height * 0.15;
    final double iconSize = size.width * 0.08;
    final double titleFontSize = size.width * 0.055;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: primaryColor,
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
                    height: kToolbarHeight + 80,
                    decoration: BoxDecoration(
                      color: primaryColor,
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
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                          padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.04),
                          child: Text(
                            "${widget.branch} - ${widget.semester} - ${widget.module}",
                            style: const TextStyle(
                              fontFamily: 'Lobster',
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'Available Notes',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: size.width * 0.07,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : !hasData
                            ? const Center(
                                child: Text(
                                  "No Notes found for the selected criteria.",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              )
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.04,
                                  vertical: size.width * 0.03,
                                ),
                                itemCount: pdfData.length,
                                itemBuilder: (context, index) {
                                  final pdf = pdfData[index];
                                  return CustomPdfCard(
                                    title: pdf['name'],
                                    icon: Icons.picture_as_pdf,
                                    color: index.isEven ? primaryColor : secondaryColor,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => PdfViewerUserScreen(
                                          pdfUrl: pdf['url'],
                                          pdfName: pdf['name'],
                                        ),
                                      ),
                                    ),
                                    index: index,
                                    totalItems: pdfData.length,
                                    animation: _cardsController,
                                    cardHeight: cardHeight,
                                    iconSize: iconSize,
                                    titleFontSize: titleFontSize,
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
        (bubble.x * size.width + animation.value * bubble.speed * size.width) %
            size.width,
        (bubble.y * size.height +
                animation.value * bubble.speed * size.height) %
            size.height,
      );

      canvas.drawCircle(position, bubble.size, paint);
    }
  }

  @override
  bool shouldRepaint(BubblePainter oldDelegate) => true;
}

class CustomPdfCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int index;
  final int totalItems;
  final Animation<double> animation;
  final double cardHeight;
  final double iconSize;
  final double titleFontSize;

  const CustomPdfCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.index,
    required this.totalItems,
    required this.animation,
    required this.cardHeight,
    required this.iconSize,
    required this.titleFontSize,
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
                      width: cardHeight * 0.6,
                      height: cardHeight * 0.6,
                      margin: const EdgeInsets.all(16),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: titleFontSize * 0.88,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
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