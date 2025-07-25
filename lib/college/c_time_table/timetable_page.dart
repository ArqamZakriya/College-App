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

  ClassDetails copyWith({
    String? startTime,
    String? endTime,
    String? subject,
    String? facultyName,
    String? type,
  }) =>
      ClassDetails(
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        subject: subject ?? this.subject,
        facultyName: facultyName ?? this.facultyName,
        type: type ?? this.type,
      );

  Map<String, String> toJson() => {
        'startTime': startTime,
        'endTime': endTime,
        'subject': subject,
        'facultyName': facultyName,
        'type': type,
      };

  factory ClassDetails.fromJson(Map<String, dynamic> json) => ClassDetails(
        startTime: json['startTime'] as String? ?? '',
        endTime: json['endTime'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        facultyName: json['facultyName'] as String? ?? '',
        type: json['type'] as String? ?? 'Class',
      );
}

class TimetablePage extends StatefulWidget {
  final String selectedCollege;
  final String branch;
  final String semester;
  final String section;

  const TimetablePage({
    super.key,
    required this.selectedCollege,
    required this.branch,
    required this.semester,
    required this.section,
  });

  @override
  _TimetablePageState createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage>
    with SingleTickerProviderStateMixin {
  List<ClassDetails> classDetails = [];
  String selectedDay = '';
  bool isLoading = false;
  late AnimationController _controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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

  Future<void> uploadTimetable() async {
    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('timetables')
          .doc(documentId)
          .set({
        selectedDay: classDetails.map((detail) => detail.toJson()).toList(),
      }, SetOptions(merge: true));

      _showSnackBar('Timetable updated successfully!');
    } catch (e) {
      _showSnackBar('Error updating timetable: ${e.toString()}', isError: true);
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
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void addNewClassDetail(String type) {
    setState(() {
      classDetails.add(ClassDetails(
        startTime: '',
        endTime: '',
        subject: type == 'Break' ? 'Break' : '',
        facultyName: '',
        type: type,
      ));
      _controller.forward(from: 0);
      
      // Scroll to the bottom after adding new class
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    });
  }

  Future<void> selectTime(ClassDetails detail, bool isStartTime) async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                side: BorderSide(color: Colors.blue),
              ),
              dayPeriodShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                side: BorderSide(color: Colors.blue),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        if (isStartTime) {
          detail.startTime = selectedTime.format(context);
        } else {
          detail.endTime = selectedTime.format(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isSmallScreen = screenWidth < 600;
    final padding = screenWidth * 0.04; // Responsive padding

    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade100,
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
                        _buildActionButtons(isSmallScreen, padding),
                        _buildTimetableContent(isSmallScreen, padding),
                        SizedBox(height: screenHeight * 0.12),
                      ],
                    ),
                  ),
                ],
              ),
              if (isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              Positioned(
                bottom: padding,
                left: padding,
                right: padding,
                child: _buildSaveButton(isSmallScreen),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(double screenHeight) => SliverAppBar(
        expandedHeight: screenHeight * 0.15,
        pinned: true,
        stretch: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: FlexibleSpaceBar(
          background: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade700, Colors.blue.shade500],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
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
                  mainAxisSize: MainAxisSize.min,  // Add this
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.selectedCollege,
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 16 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,  // Reduce line height
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),  // Reduced spacing
                    Text(
                      '${widget.branch} - ${widget.semester} - section (${widget.section})',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: Colors.white70,
                        height: 2.5,  // Reduce line height
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
          titlePadding: EdgeInsets.zero,  // Remove default padding
          expandedTitleScale: 1.4,  // Reduce title scaling
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
              height: isSmallScreen ? 50 : 60,
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: daysOfWeek.length,
                itemBuilder: (context, index) {
                  final day = daysOfWeek[index];
                  final isSelected = day == selectedDay;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDay = day;
                        loadTimetable(day);
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: padding * 0.5,
                        vertical: isSmallScreen ? 8 : 10,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 20,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.shade500
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          day.substring(0, 3),
                          style: GoogleFonts.poppins(
                            color: isSelected ? Colors.white : Colors.black54,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );

  Widget _buildActionButtons(bool isSmallScreen, double padding) => Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Row(
          children: [
            Expanded(
              child: _ActionButton(
                onPressed: () => addNewClassDetail('Class'),
                icon: Icons.school_outlined,
                label: 'Add Class',
                color: Colors.blue.shade500,
                isSmallScreen: isSmallScreen,
              ),
            ),
            SizedBox(width: padding),
            Expanded(
              child: _ActionButton(
                onPressed: () => addNewClassDetail('Break'),
                icon: Icons.coffee_outlined,
                label: 'Add Break',
                color: Colors.orange.shade400,
                isSmallScreen: isSmallScreen,
              ),
            ),
          ],
        ),
      );

  Widget _buildTimetableContent(bool isSmallScreen, double padding) => Container(
        margin: EdgeInsets.all(padding),
        child: Column(
          children: [
            for (var i = 0; i < classDetails.length; i++)
              _buildClassCard(classDetails[i], i, isSmallScreen, padding),
          ],
        ),
      );

  Widget _buildClassCard(
    ClassDetails detail,
    int index,
    bool isSmallScreen,
    double padding,
  ) =>
      Container(
        margin: EdgeInsets.only(bottom: padding),
        child: Material(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: detail.type == 'Break'
                    ? [Colors.orange.shade50, Colors.white]
                    : [Colors.blue.shade50, Colors.white],
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: ExpansionTile(
                tilePadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                leading: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: detail.type == 'Break'
                        ? Colors.orange.shade100
                        : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    detail.type == 'Break'
                    ? Icons.coffee
                    : Icons.school,
                    size: isSmallScreen ? 18 : 20,
                    color: detail.type == 'Break'
                        ? Colors.orange.shade700
                        : Colors.blue.shade700,
                  ),
                ),
                title: Text(
                  detail.subject.isEmpty
                      ? (detail.type == 'Break' ? 'Break' : 'New Class')
                      : detail.subject,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
                subtitle: detail.startTime.isNotEmpty || detail.endTime.isNotEmpty
                    ? Text(
                        '${detail.startTime} - ${detail.endTime}',
                        style: GoogleFonts.poppins(
                          color: Colors.black54,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      )
                    : null,
                children: [
                  Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Column(
                      children: [
                        _buildTimeSelector(detail, isSmallScreen),
                        if (detail.type != 'Break') ...[
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          _buildTextField(
                            label: 'Subject',
                            value: detail.subject,
                            onChanged: (value) =>
                                setState(() => detail.subject = value),
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          _buildTextField(
                            label: 'Faculty',
                            value: detail.facultyName,
                            onChanged: (value) =>
                                setState(() => detail.facultyName = value),
                            isSmallScreen: isSmallScreen,
                          ),
                        ],
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        _DeleteButton(
                          onPressed: () =>
                              setState(() => classDetails.remove(detail)),
                          isSmallScreen: isSmallScreen,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildTimeSelector(ClassDetails detail, bool isSmallScreen) => Row(
        children: [
          Expanded(
            child: _TimeButton(
              time: detail.startTime,
              label: 'Start Time',
              onTap: () => selectTime(detail, true),
              isSmallScreen: isSmallScreen,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16),
            child: Icon(
              Icons.arrow_forward,
              color: Colors.blue.shade300,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          Expanded(
            child: _TimeButton(
              time: detail.endTime,
              label: 'End Time',
              onTap: () => selectTime(detail, false),
              isSmallScreen: isSmallScreen,
            ),
          ),
        ],
      );

  Widget _buildTextField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    required bool isSmallScreen,
  }) =>
      TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: Colors.blue.shade700,
            fontSize: isSmallScreen ? 12 : 14,
          ),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 8 : 12,
          ),
        ),
        style: GoogleFonts.poppins(
          fontSize: isSmallScreen ? 13 : 14,
        ),
        onChanged: onChanged,
      );

  Widget _buildSaveButton(bool isSmallScreen) => Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : uploadTimetable,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade500,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 12 : 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.save_outlined,
                size: isSmallScreen ? 20 : 24,
                color: Colors.white.withOpacity(0.9),
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Text(
                'Save Timetable',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final bool isSmallScreen;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 10 : 12,
            horizontal: isSmallScreen ? 12 : 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isSmallScreen ? 18 : 20),
            SizedBox(width: isSmallScreen ? 6 : 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ],
        ),
      );
}

class _TimeButton extends StatelessWidget {
  final String time;
  final String label;
  final VoidCallback onTap;
  final bool isSmallScreen;

  const _TimeButton({
    required this.time,
    required this.label,
    required this.onTap,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 10 : 12,
            horizontal: isSmallScreen ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: time.isEmpty ? Colors.blue.shade200 : Colors.blue.shade400,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time,
                size: isSmallScreen ? 16 : 18,
                color: time.isEmpty ? Colors.blue.shade300 : Colors.blue.shade600,
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Text(
                time.isEmpty ? label : time,
                style: GoogleFonts.poppins(
                  color: time.isEmpty ? Colors.black54 : Colors.black87,
                  fontWeight: time.isEmpty ? FontWeight.normal : FontWeight.w500,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isSmallScreen;

  const _DeleteButton({
    required this.onPressed,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: onPressed,
        icon: Icon(
          Icons.delete_outline,
          color: Colors.red,
          size: isSmallScreen ? 18 : 20,
        ),
        label: Text(
          'Delete',
          style: GoogleFonts.poppins(
            color: Colors.red,
            fontWeight: FontWeight.w500,
            fontSize: isSmallScreen ? 12 : 14,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 10 : 12,
            horizontal: isSmallScreen ? 20 : 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.red),
          ),
        ),
      );
}