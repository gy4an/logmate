import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  List<String> _students = [];
  String? _selectedStudent;
  List<Map<String, dynamic>> _studentTasks = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final names = keys
        .where((key) => key.startsWith('tasks_'))
        .map((key) => key.replaceFirst('tasks_', ''))
        .toList();
    setState(() {
      _students = names;
    });
  }

  Future<void> _loadStudentData(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('tasks_$username');
    if (data == null) return;
    final List<dynamic> decoded = jsonDecode(data);
    setState(() {
      _selectedStudent = username;
      _studentTasks = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  double getTotalHours() {
    return _studentTasks.fold(
        0, (sum, item) => sum + double.tryParse(item['hours'] ?? '0')!);
  }

  int getApprovedCount() =>
      _studentTasks.where((task) => task['approved'] == true).length;

  int getPendingCount() =>
      _studentTasks.where((task) => task['approved'] == false).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Admin Analytics & Reports",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _selectedStudent == null
          ? _buildStudentList()
          : _buildStudentAnalytics(),
    );
  }

  // 🧩 1. Student List View
  Widget _buildStudentList() {
    return ListView.builder(
      itemCount: _students.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final name = _students[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.person, color: Colors.blue),
            ),
            title: Text(
              name,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _loadStudentData(name),
          ),
        );
      },
    );
  }

  // 🧩 2. Student Analytics View
  Widget _buildStudentAnalytics() {
    final totalTasks = _studentTasks.length;
    final totalHours = getTotalHours();
    final approved = getApprovedCount();
    final pending = getPendingCount();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          TextButton.icon(
            onPressed: () => setState(() => _selectedStudent = null),
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            label: const Text("Back to Students"),
          ),
          const SizedBox(height: 10),

          Text(
            _selectedStudent ?? '',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            "Total Logged Tasks: $totalTasks",
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),

          // Summary minimalist cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoCard("Total Hours", totalHours.toStringAsFixed(1),
                  Icons.access_time, Colors.blue.shade400),
              _buildInfoCard("Approved", "$approved", Icons.check_circle,
                  Colors.green.shade400),
              _buildInfoCard("Pending", "$pending", Icons.pending_actions,
                  Colors.orange.shade400),
            ],
          ),

          const SizedBox(height: 20),

          const Text(
            "Task Details",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _studentTasks.length,
              itemBuilder: (context, index) {
                final task = _studentTasks[index];
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(task['task']),
                    subtitle: Text("Hours: ${task['hours']}"),
                    trailing: Icon(
                      task['approved']
                          ? Icons.check_circle
                          : Icons.hourglass_empty,
                      color:
                          task['approved'] ? Colors.green : Colors.orangeAccent,
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

  Widget _buildInfoCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
