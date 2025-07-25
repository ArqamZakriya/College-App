// ignore_for_file: library_private_types_in_public_api
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class ClassDetails {
  String startTime;
  String endTime;
  String subject;
  String facultyName;
  String type;

  ClassDetails({
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.facultyName,
    required this.type,
  });

  factory ClassDetails.fromJson(Map<String, dynamic> json) => ClassDetails(
        startTime: json['startTime'] as String? ?? '',
        endTime: json['endTime'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        facultyName: json['facultyName'] as String? ?? '',
        type: json['type'] as String? ?? 'Class',
      );
}

class UserTimetablePage extends StatefulWidget {
  final String selectedCollege;
  final String branch;
  final String semester;
  final String section;

  const UserTimetablePage({
    super.key,
    required this.selectedCollege,
    required this.branch,
    required this.semester,
    required this.section,
  });

  @override
  _UserTimetablePageState createState() => _UserTimetablePageState();
}

class _UserTimetablePageState extends State<UserTimetablePage>
    with SingleTickerProviderStateMixin {
  List<ClassDetails> classDetails = [];
  String selectedDay = '';
  bool isLoading = false;
  late AnimationController _controller;
  final ScrollController _scrollController = ScrollController();

  static const List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // Color scheme
  static final Color primaryColor = Colors.indigo.shade600;
  static final Color secondaryColor = Colors.indigo.shade100;
  // ignore: unused_field
  static final Color accentColor = Colors.amber.shade600;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    selectedDay = DateFormat('EEEE').format(DateTime.now());
    loadTimetable(selectedDay);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get documentId =>
      '${widget.selectedCollege}_${widget.branch}_${widget.semester}_${widget.section}';

  Future<void> loadTimetable(String day) async {
    setState(() => isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('timetables')
          .doc(documentId)
          .get();

      setState(() {
        if (doc.exists) {
          final data = doc.data()?[day] as List<dynamic>?;
          classDetails = data
                  ?.map((json) =>
                      ClassDetails.fromJson(json as Map<String, dynamic>))
                  .toList() ??
              [];
          
          // Sort classes by start time
          classDetails.sort((a, b) {
            if (a.startTime.isEmpty) return 1;
            if (b.startTime.isEmpty) return -1;
            return a.startTime.compareTo(b.startTime);
          });
        } else {
          classDetails = [];
        }
      });
    } catch (e) {
      _showSnackBar('Error loading timetable: ${e.toString()}', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isSmallScreen = screenWidth < 600;
    final padding = screenWidth * 0.04; // Responsive padding

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              secondaryColor.withOpacity(0.3),
              Colors.white,
            ],
            stops: const [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _buildSliverAppBar(screenHeight),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildDaySelector(isSmallScreen, padding),
                        _buildCurrentDateDisplay(isSmallScreen, padding),
                        _buildTimetableContent(isSmallScreen, padding),
                        SizedBox(height: screenHeight * 0.2),
                      ],
                    ),
                  ),
                ],
              ),
              if (isLoading)
                Container(
                  color: Colors.black26,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Scroll to top
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.arrow_upward),
      ),
    );
  }

  Widget _buildCurrentDateDisplay(bool isSmallScreen, double padding) {
    final now = DateTime.now();
    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy');
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.4),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: padding * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: isSmallScreen ? 18 : 20,
              color: primaryColor,
            ),
            SizedBox(width: 10),
            Text(
              dateFormatter.format(now),
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(double screenHeight) => SliverAppBar(
        expandedHeight: screenHeight * 0.15,
        pinned: true,
        stretch: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: FlexibleSpaceBar(
          background: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
          ),
          title: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = MediaQuery.of(context).size.width < 600;
              return Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: isSmallScreen ? 20 : 24,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.selectedCollege,
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 16 : 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.business,
                            color: Colors.white70,
                            size: isSmallScreen ? 14 : 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            widget.branch,
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.bookmark,
                            color: Colors.white70,
                            size: isSmallScreen ? 14 : 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Sem ${widget.semester}',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.groups,
                            color: Colors.white70,
                            size: isSmallScreen ? 14 : 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Sec ${widget.section}',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          titlePadding: EdgeInsets.zero,
          expandedTitleScale: 1.4,
        ),
      );

  Widget _buildDaySelector(bool isSmallScreen, double padding) => Container(
        margin: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: isSmallScreen ? 60 : 70,
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: 10),
              child: Row(
                children: daysOfWeek.map((day) {
                  final isSelected = day == selectedDay;
                  final currentDay = DateFormat('EEEE').format(DateTime.now()) == day;
                  
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDay = day;
                          loadTimetable(day);
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor
                              : currentDay
                                  ? secondaryColor
                                  : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                day.substring(0, 3),
                                style: GoogleFonts.poppins(
                                  color: isSelected
                                      ? Colors.white
                                      : currentDay
                                          ? primaryColor
                                          : Colors.black54,
                                  fontWeight: isSelected || currentDay
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: isSmallScreen ? 12 : 14,
                                ),
                              ),
                              if (currentDay && !isSelected)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );

  Widget _buildTimetableContent(bool isSmallScreen, double padding) => Container(
        margin: EdgeInsets.all(padding),
        child: Column(
          children: classDetails.isEmpty
              ? [_buildNoClassesMessage(isSmallScreen)]
              : [
                  _buildTimelineHeader(isSmallScreen),
                  for (var i = 0; i < classDetails.length; i++)
                    _buildClassCard(classDetails[i], i, isSmallScreen, padding),
                ],
        ),
      );

  Widget _buildTimelineHeader(bool isSmallScreen) => Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Icon(
              Icons.schedule,
              color: primaryColor,
              size: isSmallScreen ? 18 : 20,
            ),
            SizedBox(width: 8),
            Text(
              'Today\'s Schedule',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.grey.shade300,
              ),
            ),
          ],
        ),
      );

  Widget _buildNoClassesMessage(bool isSmallScreen) => Container(
        margin: EdgeInsets.only(top: 32),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: secondaryColor.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy,
                size: isSmallScreen ? 48 : 64,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'No Classes Scheduled',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              // ignore: unnecessary_brace_in_string_interps
              'There are no classes scheduled for ${selectedDay}.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Reset to today
                final today = DateFormat('EEEE').format(DateTime.now());
                setState(() {
                  selectedDay = today;
                  loadTimetable(today);
                });
              },
              icon: Icon(Icons.refresh),
              label: Text('Show Today'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildClassCard(
    ClassDetails detail,
    int index,
    bool isSmallScreen,
    double padding,
  ) {
    final isBreak = detail.type == 'Break';
    final cardColor = isBreak ? Colors.orange.shade50 : Colors.white;
    final accentColor = isBreak ? Colors.orange.shade700 : primaryColor;
    final lightAccentColor = isBreak ? Colors.orange.shade100 : secondaryColor;
    
    // Calculate class duration if both times are available
    String duration = '';
    if (detail.startTime.isNotEmpty && detail.endTime.isNotEmpty) {
      try {
        final format = DateFormat('hh:mm a');
        final start = format.parse(detail.startTime);
        final end = format.parse(detail.endTime);
        final diff = end.difference(start);
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        
        if (hours > 0) {
          duration = '$hours hr';
          if (minutes > 0) duration += ' $minutes min';
        } else {
          duration = '$minutes min';
        }
      } catch (e) {
        // If parsing fails, don't show duration
        duration = '';
      }
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(15),
        color: cardColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            // Toggle expansion
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: lightAccentColor,
                width: 1.5,
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                colorScheme: ColorScheme.light(
                  primary: accentColor,
                ),
              ),
              child: ExpansionTile(
                tilePadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                leading: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: isSmallScreen ? 40 : 48,
                      height: isSmallScreen ? 40 : 48,
                      decoration: BoxDecoration(
                        color: lightAccentColor.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                      child: Icon(
                        isBreak ? Icons.coffee : Icons.school,
                        size: isSmallScreen ? 18 : 20,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isBreak ? 'Break' : 'Class',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 10 : 12,
                              fontWeight: FontWeight.w500,
                              color: accentColor,
                            ),
                          ),
                        ),
                        if (duration.isNotEmpty) ...[
                          SizedBox(width: 6),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: isSmallScreen ? 10 : 12,
                                  color: Colors.grey.shade700,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  duration,
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 10 : 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      detail.subject.isEmpty
                          ? (isBreak ? 'Break Time' : 'Class Time')
                          : detail.subject,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ),
                  ],
                ),
                subtitle: detail.startTime.isNotEmpty || detail.endTime.isNotEmpty
                    ? Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: isSmallScreen ? 12 : 14,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${detail.startTime} - ${detail.endTime}',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade700,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ],
                      )
                    : null,
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      color: lightAccentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildTimeDisplay(detail, isSmallScreen, isBreak),
                        if (!isBreak && detail.facultyName.isNotEmpty) ...[
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          _buildInfoRow(
                            'Faculty',
                            detail.facultyName,
                            isSmallScreen,
                            isBreak,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDisplay(ClassDetails detail, bool isSmallScreen, bool isBreak) {
    final accentColor = isBreak ? Colors.orange.shade700 : primaryColor;
    final lightAccentColor = isBreak ? Colors.orange.shade100 : secondaryColor;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTimeInfo('Start', detail.startTime, isSmallScreen, accentColor, lightAccentColor),
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16),
          child: Icon(
            Icons.arrow_forward,
            color: accentColor,
            size: isSmallScreen ? 20 : 24,
          ),
        ),
        _buildTimeInfo('End', detail.endTime, isSmallScreen, accentColor, lightAccentColor),
      ],
    );
  }

  Widget _buildTimeInfo(String label, String time, bool isSmallScreen, Color accentColor, Color lightAccentColor) => Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 12 : 16,
            horizontal: isSmallScreen ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: lightAccentColor),
            boxShadow: [
              BoxShadow(
                color: lightAccentColor.withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    label == 'Start' ? Icons.play_circle_outline : Icons.stop_circle_outlined,
                    size: isSmallScreen ? 14 : 16,
                    color: accentColor,
                  ),
                  SizedBox(width: 4),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: accentColor,
                      fontSize: isSmallScreen ? 12 : 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                time.isEmpty ? 'Not Set' : time,
                style: GoogleFonts.poppins(
                  color: time.isEmpty ? Colors.grey : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildInfoRow(
    String label,
    String value,
    bool isSmallScreen,
    bool isBreak,
  ) {
    final accentColor = isBreak ? Colors.orange.shade700 : primaryColor;
    final lightAccentColor = isBreak ? Colors.orange.shade100 : secondaryColor;
    
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 12 : 16,
        horizontal: isSmallScreen ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightAccentColor),
        boxShadow: [
          BoxShadow(
            color: lightAccentColor.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lightAccentColor.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: isSmallScreen ? 18 : 20,
              color: accentColor,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: accentColor,
                    fontSize: isSmallScreen ? 12 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value.isEmpty ? 'Not Assigned' : value,
                  style: GoogleFonts.poppins(
                    color: value.isEmpty ? Colors.grey : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}