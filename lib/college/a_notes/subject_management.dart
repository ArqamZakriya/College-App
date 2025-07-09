import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:college_app/college/a_notes/select_module.dart';
import 'package:college_app/college/ad_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

class SubjectManagementPage extends StatefulWidget {
  final String selectedCollege;
  final String branch;
  final String semester;

  const SubjectManagementPage({
    super.key,
    required this.selectedCollege,
    required this.branch,
    required this.semester,
  });

  @override
  State<SubjectManagementPage> createState() => _SubjectManagementPageState();
}

class _SubjectManagementPageState extends State<SubjectManagementPage>
    with TickerProviderStateMixin {
  final TextEditingController _subjectController = TextEditingController();
  List<String> subjects = [];
  late AnimationController _cardsController;
  late AnimationController _backgroundController;
  final List<Bubble> bubbles = List.generate(15, (index) => Bubble());
  
  static const primaryIndigo = Color(0xFF3F51B5);
  static const primaryBlue = Color(0xFF1A237E);
  
  @override
  void initState() {
    super.initState();
    fetchSubjects();
    
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
    _subjectController.dispose();
    _cardsController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> fetchSubjects() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('subjects')
        .doc('${widget.selectedCollege}_${widget.branch}_${widget.semester}')
        .get();

    if (snapshot.exists) {
      final data = snapshot.data();
      setState(() {
        subjects = List<String>.from(data?['subjects'] ?? []);
      });
    }
  }

  Future<void> addSubject() async {
    if (_subjectController.text.trim().isEmpty) return;

    final newSubject = _subjectController.text.trim();
    setState(() {
      subjects.add(newSubject);
      _subjectController.clear();
    });

    await FirebaseFirestore.instance
        .collection('subjects')
        .doc('${widget.selectedCollege}_${widget.branch}_${widget.semester}')
        .set({'subjects': subjects}, SetOptions(merge: true));
  }

  Future<void> deleteSubject(String subject) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$subject"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                subjects.remove(subject);
              });
              
              await FirebaseFirestore.instance
                  .collection('subjects')
                  .doc('${widget.selectedCollege}_${widget.branch}_${widget.semester}')
                  .set({'subjects': subjects}, SetOptions(merge: true));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void navigateToModulesPage(String subject) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChapterModulePage(
          selectedCollege: widget.selectedCollege,
          branch: widget.branch,
          semester: widget.semester,
          subject: subject,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
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
                              onTap: () => Get.to(() => const AdHomePage()),
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
                            'Subject Management',
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
                  Padding(
                    padding: EdgeInsets.all(size.width * 0.04),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          hintText: 'Add new subject',
                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: subtitleFontSize,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(
                            Icons.book_outlined,
                            color: primaryIndigo,
                            size: iconSize * 0.8,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.04,
                            vertical: size.width * 0.03,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.add_circle,
                              color: primaryIndigo,
                              size: iconSize * 0.8,
                            ),
                            onPressed: addSubject,
                          ),
                        ),
                        onSubmitted: (_) => addSubject(),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: subtitleFontSize,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: subjects.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.book_outlined,
                                  size: size.width * 0.2,
                                  color: Colors.grey.withOpacity(0.5),
                                ),
                                SizedBox(height: size.width * 0.04),
                                Text(
                                  'No subjects added yet',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.withOpacity(0.7),
                                  ),
                                ),
                                SizedBox(height: size.width * 0.02),
                                Text(
                                  'Add a subject to get started',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: subtitleFontSize,
                                    color: Colors.grey.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.04,
                              vertical: size.width * 0.02,
                            ),
                            itemCount: subjects.length,
                            itemBuilder: (context, index) {
                              final subject = subjects[index];
                              final bool isEven = index % 2 == 0;
                              return CustomSubject(
                                title: subject,
                                subtitle: 'Tap to manage modules',
                                icon: Icons.school,
                                color: isEven ? primaryBlue : primaryIndigo,
                                onTap: () => navigateToModulesPage(subject),
                                onDelete: () => deleteSubject(subject),
                                index: index,
                                totalItems: subjects.length,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(size.width * 0.06),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Add New Subject',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: primaryIndigo,
                      ),
                    ),
                    SizedBox(height: size.width * 0.04),
                    TextField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        labelText: 'Subject Name',
                        labelStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: subtitleFontSize,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        prefixIcon: const Icon(Icons.book_outlined),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: primaryIndigo, width: 2),
                        ),
                      ),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: subtitleFontSize,
                      ),
                    ),
                    SizedBox(height: size.width * 0.04),
                    ElevatedButton(
                      onPressed: () {
                        addSubject();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryIndigo,
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.08,
                          vertical: size.width * 0.03,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Add Subject',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: subtitleFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        backgroundColor: primaryIndigo,
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
        elevation: 4,
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

class CustomSubject extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final int index;
  final int totalItems;
  final Animation<double> animation;
  final double cardHeight;
  final double iconSize;
  final double titleFontSize;
  final double subtitleFontSize;

  const CustomSubject({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.onDelete,
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
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: iconSize * 0.6,
                          ),
                          onPressed: onDelete,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: iconSize * 0.6,
                          ),
                        ),
                      ],
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