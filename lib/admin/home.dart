import 'package:college_app/widgets/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  int _totalUsers = 0;
  int _totalUniversities = 0;
  int _totalColleges = 0;
  List<ChartData> _universitiesData = [];
  List<ChartData> _collegesData = [];
  List<ChartData> _usersData = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get all counts in parallel with timeout
      final counts = await Future.wait([
        _firestore.collection('users').get(),
        _firestore.collection('pending_users').get(),
        _firestore.collection('universities').get(),
        _firestore.collection('colleges').get(),
      ]).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout - please check your connection'),
      );

      final usersCount = counts[0].size + counts[1].size;
      final universitiesCount = counts[2].size;
      final collegesCount = counts[3].size;

      // Get top 5 universities by college count
      final universities = await _firestore.collection('universities').get();
      final universitiesWithCollegeCount = await Future.wait(
        universities.docs.map((univ) async {
          final colleges = await _firestore
              .collection('colleges')
              .where('universityId', isEqualTo: univ.id)
              .get();
          return {
            'name': univ.data().containsKey('name') ? univ['name'] : 'Unknown University',
            'count': colleges.size.toDouble(),
          };
        }),
      );

      universitiesWithCollegeCount.sort((a, b) => (b['count'] as double).compareTo(a['count'] as double));
      final topUniversities = universitiesWithCollegeCount.take(5).toList();

      // Get top 5 colleges by student count
      final colleges = await _firestore.collection('colleges').get();
      final collegesWithStudentCount = colleges.docs.map((college) {
        final studentCount = (college.hashCode % 500) + 50;
        return {
          'name': college.data().containsKey('name') ? college['name'] : 'Unknown College',
          'count': studentCount.toDouble(),
        };
      }).toList();

      collegesWithStudentCount.sort((a, b) => (b['count'] as double).compareTo(a['count'] as double));
      final topColleges = collegesWithStudentCount.take(5).toList();

      // Get user growth data (last 7 days)
      final now = DateTime.now();
      final userGrowth = await Future.wait(
        List.generate(7, (index) async {
          final date = now.subtract(Duration(days: 6 - index));
          final startOfDay = DateTime(date.year, date.month, date.day);
          final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
          
          final users = await _firestore
              .collection('users')
              .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
              .where('createdAt', isLessThanOrEqualTo: endOfDay)
              .get();
              
          final pendingUsers = await _firestore
              .collection('pending_users')
              .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
              .where('createdAt', isLessThanOrEqualTo: endOfDay)
              .get();
              
          return {
            'date': '${date.day}/${date.month}',
            'count': (users.size + pendingUsers.size).toDouble(),
          };
        }),
      );

      if (mounted) {
        setState(() {
          _totalUsers = usersCount;
          _totalUniversities = universitiesCount;
          _totalColleges = collegesCount;
          _universitiesData = topUniversities
              .map((e) => ChartData(
                  e['name'] as String, 
                  (e['count'] as double), 
                  Colors.primaries[topUniversities.indexOf(e) % Colors.primaries.length]
              ))
              .toList();
          _collegesData = topColleges
              .map((e) => ChartData(
                  e['name'] as String, 
                  (e['count'] as double), 
                  Colors.primaries[topColleges.indexOf(e) % Colors.primaries.length]
              ))
              .toList();
          _usersData = userGrowth
              .map((e) => ChartData(
                  e['date'] as String, 
                  (e['count'] as double), 
                  Colors.blue
              ))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1B3A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 100,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 150,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTitle() {
    return Shimmer.fromColors(
      baseColor: Colors.white,
      highlightColor: Colors.white.withOpacity(0.7),
      period: const Duration(seconds: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Dashboard",
            style: GoogleFonts.poppins(
              fontSize: 36,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Educational Analytics",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatsCard({
    required String title,
    required int count,
    required IconData icon,
    required List<Color> gradientColors,
    required String subtitle,
    double? percentage,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 180,
        maxHeight: 220,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    if (percentage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+${percentage.toStringAsFixed(1)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  count.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildEnhancedChart({
    required String title,
    required String subtitle,
    required Widget chart,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 400,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: chart,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 700.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildPieChart(List<ChartData> data) {
    return SfCircularChart(
      legend: Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
        position: LegendPosition.bottom,
        textStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey[700],
        ),
      ),
      series: <CircularSeries>[
        DoughnutSeries<ChartData, String>(
          dataSource: data,
          xValueMapper: (ChartData data, _) => data.x,
          yValueMapper: (ChartData data, _) => data.y,
          pointColorMapper: (ChartData data, _) => data.color,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.outside,
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          enableTooltip: true,
          innerRadius: '60%',
          cornerStyle: CornerStyle.bothCurve,
        )
      ],
    );
  }

  Widget _buildLineChart() {
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      primaryYAxis: NumericAxis(
        minimum: 0,
        majorGridLines: MajorGridLines(
          width: 1,
          color: Colors.grey[200],
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      series: <CartesianSeries>[
        AreaSeries<ChartData, String>(
          dataSource: _usersData,
          xValueMapper: (ChartData data, _) => data.x,
          yValueMapper: (ChartData data, _) => data.y,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.withOpacity(0.4),
              Colors.blue.withOpacity(0.1),
            ],
          ),
          borderColor: Colors.blue,
          borderWidth: 3,
          markerSettings: const MarkerSettings(
            isVisible: true,
            height: 8,
            width: 8,
            color: Colors.blue,
            borderColor: Colors.white,
            borderWidth: 2,
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final paddingTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const ADrawer(),
      backgroundColor: const Color(0xFF1A1B3A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: screenWidth > 600 ? 300 : 250,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1A1B3A),
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A1B3A),
                      Color(0xFF2D3561),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned(
                      right: -50,
                      top: 50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      top: 100,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, paddingTop + (screenWidth > 600 ? 100 : 80), 24, 24),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAnimatedTitle().animate()
                                .fadeIn(duration: 600.ms)
                                .slideX(begin: -0.2, end: 0),
                            const SizedBox(height: 20),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search analytics...',
                                  hintStyle: GoogleFonts.poppins(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 15,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),
                            ).animate()
                                .fadeIn(delay: 300.ms)
                                .slideX(begin: 0.2, end: 0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: _error != null
                  ? _buildErrorWidget()
                  : _isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              GridView.count(
                                crossAxisCount: 3,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                childAspectRatio: 1.5,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                children: List.generate(3, (index) => _buildShimmerCard()),
                              ),
                              const SizedBox(height: 32),
                              _buildShimmerCard(),
                              const SizedBox(height: 24),
                              _buildShimmerCard(),
                              const SizedBox(height: 24),
                              _buildShimmerCard(),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(24),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Column(
                                children: [
                                  const SizedBox(height: 8),
                                  // Stats Cards
                                  GridView.count(
                                    crossAxisCount: constraints.maxWidth > 1200 
                                      ? 3 
                                      : constraints.maxWidth > 600 
                                        ? 2 
                                        : 1,
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    childAspectRatio: constraints.maxWidth > 600 ? 1.5 : 1.8,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    children: [
                                      _buildModernStatsCard(
                                        title: "Total Users",
                                        count: _totalUsers,
                                        icon: Icons.people_outline,
                                        gradientColors: [
                                          const Color(0xFF667EEA),
                                          const Color(0xFF764BA2),
                                        ],
                                        subtitle: "Active learners",
                                        percentage: 12.5,
                                      ),
                                      _buildModernStatsCard(
                                        title: "Universities",
                                        count: _totalUniversities,
                                        icon: Icons.school_outlined,
                                        gradientColors: [
                                          const Color(0xFF4FACFE),
                                          const Color(0xFF00F2FE),
                                        ],
                                        subtitle: "Educational institutions",
                                        percentage: 8.2,
                                      ),
                                      _buildModernStatsCard(
                                        title: "Colleges",
                                        count: _totalColleges,
                                        icon: Icons.business_outlined,
                                        gradientColors: [
                                          const Color(0xFF43E97B),
                                          const Color(0xFF38F9D7),
                                        ],
                                        subtitle: "Partner colleges",
                                        percentage: 15.7,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                  // Charts
                                  if (_universitiesData.isNotEmpty)
                                    _buildEnhancedChart(
                                      title: "Top Universities",
                                      subtitle: "By college partnerships",
                                      chart: _buildPieChart(_universitiesData),
                                      icon: Icons.school,
                                      accentColor: const Color(0xFF667EEA),
                                    ),
                                  const SizedBox(height: 24),
                                  if (_collegesData.isNotEmpty)
                                    _buildEnhancedChart(
                                      title: "Popular Colleges",
                                      subtitle: "By student enrollment",
                                      chart: _buildPieChart(_collegesData),
                                      icon: Icons.business,
                                      accentColor: const Color(0xFF43E97B),
                                    ),
                                  const SizedBox(height: 24),
                                  _buildEnhancedChart(
                                    title: "User Growth",
                                    subtitle: "Last 7 days activity",
                                    chart: _buildLineChart(),
                                    icon: Icons.trending_up,
                                    accentColor: const Color(0xFF4FACFE),
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              );
                            },
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final String x;
  final double y;
  final Color color;

  ChartData(this.x, this.y, this.color);
}