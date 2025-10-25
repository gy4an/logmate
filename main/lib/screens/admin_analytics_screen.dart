import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  List<String> _students = [];
  String? _selectedStudent;
  List<Map<String, dynamic>> _studentTasks = [];

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadStudents();

    // Animation setup
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final names = keys
        .where((key) => key.startsWith('tasks_'))
        .map((key) => key.replaceFirst('tasks_', ''))
        .toList();
    setState(() => _students = names);
  }

  Future<void> _loadStudentData(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('tasks_$username');
    if (data == null) return;

    final List<dynamic> decoded = jsonDecode(data);
    final tasks = decoded.map((e) => Map<String, dynamic>.from(e)).toList();

    // Compute actual hours for each task
    for (var task in tasks) {
      if (task['startTime'] != null && task['endTime'] != null) {
        final start = DateTime.parse(task['startTime']);
        final end = DateTime.parse(task['endTime']);
        final diff = end.difference(start).inMinutes / 60.0;
        task['actualHours'] = diff;
      } else {
        task['actualHours'] = 0.0;
      }
    }

    setState(() {
      _selectedStudent = username;
      _studentTasks = tasks;
    });

    _controller.forward(from: 0);
  }

  double getTotalHours() {
    return _studentTasks.fold(0.0, (sum, task) {
      final hours = task['actualHours'] ?? 0.0;
      return sum + (hours is num ? hours.toDouble() : 0.0);
    });
  }

  int getApprovedCount() =>
      _studentTasks.where((task) => task['approved'] == true).length;

  int getPendingCount() =>
      _studentTasks.where((task) => task['approved'] == false).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Admin Analytics & Reports",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A2E63), Color(0xFF1E88E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A2E63), Color(0xFF1E88E5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _selectedStudent == null
              ? _buildStudentList()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildStudentAnalytics(),
                  ),
                ),
        ),
      ),
    );
  }

  // 📋 Student List
  Widget _buildStudentList() {
    return Padding(
      padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
      child: _students.isEmpty
          ? const Center(
              child: Text("No students found",
                  style: TextStyle(color: Colors.white70, fontSize: 18)),
            )
          : ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final name = _students[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.25), width: 1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.white24,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              color: Colors.white70, size: 16),
                          onTap: () => _loadStudentData(name),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // 📊 Student Analytics
  Widget _buildStudentAnalytics() {
    final totalTasks = _studentTasks.length;
    final totalHours = getTotalHours();
    final approved = getApprovedCount();
    final pending = getPendingCount();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () => setState(() => _selectedStudent = null),
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            label: const Text("Back to Students"),
          ),

          const SizedBox(height: 10),
          Text(
            _selectedStudent ?? '',
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text("Total Logged Tasks: $totalTasks",
              style: const TextStyle(color: Colors.white70)),

          const SizedBox(height: 20),

          // Info Cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoCard("Total Hours", totalHours.toStringAsFixed(2),
                  Icons.access_time, Colors.blueAccent),
              _buildInfoCard("Approved", "$approved", Icons.check_circle,
                  Colors.greenAccent),
              _buildInfoCard("Pending", "$pending", Icons.pending_actions,
                  Colors.orangeAccent),
            ],
          ),

          const SizedBox(height: 30),
          const Text("Task Details",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              itemCount: _studentTasks.length,
              itemBuilder: (context, index) {
                final task = _studentTasks[index];
                final approved = task['approved'] == true;
                final hours = task['actualHours'] ?? 0.0;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: approved
                        ? Colors.white.withOpacity(0.15)
                        : Colors.white.withOpacity(0.08),
                    border: Border.all(
                        color: approved
                            ? Colors.greenAccent.withOpacity(0.4)
                            : Colors.white.withOpacity(0.2)),
                  ),
                  child: ListTile(
                    title: Text(task['task'] ?? 'Untitled Task',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    subtitle: Text(
                      "Actual Hours: ${hours.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Icon(
                      approved ? Icons.check_circle : Icons.hourglass_empty,
                      color:
                          approved ? Colors.greenAccent : Colors.orangeAccent,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🪄 Info Card Widget
  Widget _buildInfoCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    fontSize: 13)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
