import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:main/screens/admin_feedback_list_screen.dart';
import 'package:main/screens/admin_signature_screen.dart';
import 'package:main/screens/admin_analytics_screen.dart';
import 'package:main/screens/manage_employee_tasks_screen.dart';
import 'package:main/screens/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _studentCount = 0;
  int _taskCount = 0;
  int _pendingCount = 0;
  double _totalActualHours = 0.0; // ✅ NEW — Track total actual hours

  @override
  void initState() {
    super.initState();
    _loadSummaryData();
  }

    Future<void> _loadSummaryData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    int students = 0;
    int totalTasks = 0;
    int pendingTasks = 0;
    int completedTasks = 0;
    double totalActualHours = 0.0;

    for (String key in keys) {
      if (key.startsWith("tasks_")) {
        students++;
        final String? jsonData = prefs.getString(key);
        if (jsonData == null || jsonData.isEmpty) continue;

        List<dynamic> tasksList;
        try {
          tasksList = jsonDecode(jsonData) as List<dynamic>;
        } catch (e) {
          // if malformed, skip this student's tasks
          continue;
        }

        totalTasks += tasksList.length;

        for (var raw in tasksList) {
          if (raw is! Map) continue;
          final Map<String, dynamic> t = Map<String, dynamic>.from(raw);

          // read status/approved/actualHours (robustly)
          final String status = (t['status']?.toString() ?? '').trim();
          final bool approved = (t['approved'] == true);
          final double actual = double.tryParse(
                (t['actualHours'] ?? t['hours'] ?? '0').toString(),
              ) ??
              0.0;

          totalActualHours += actual;

          // Completed if status explicitly 'Completed'
          if (status.toLowerCase() == 'completed') {
            completedTasks++;
            continue;
          }

          // If task already approved (but not marked Completed) treat as completed for pending calculation
          if (approved) {
            completedTasks++;
            continue;
          }

          // Otherwise it's pending (ongoing, pending approval, not started, etc.)
          pendingTasks++;
        }
      }
    }

    setState(() {
      _studentCount = students;
      _taskCount = totalTasks;
      _pendingCount = pendingTasks;
      _totalActualHours = totalActualHours;
    });
  }


  Future<bool> _showLogoutDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget summaryCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        height: 90,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.25),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      )),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget dashboardCard({
    required IconData icon,
    required String title,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      splashColor: colors.last.withOpacity(0.3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.25),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(3, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF0A2E63);

    return WillPopScope(
      onWillPop: () async {
        final shouldLogout = await _showLogoutDialog(context);
        if (shouldLogout) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text("Admin Dashboard",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadSummaryData, // 🔄 Manual refresh button
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () async {
                final shouldLogout = await _showLogoutDialog(context);
                if (shouldLogout) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                }
              },
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A2E63), Color(0xFF1565C0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Welcome, Admin 👋",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )),
                  const SizedBox(height: 6),
                  Text(
                    "Here’s today’s summary and management tools.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ✅ Dynamic Summary Section
                  Row(
                    children: [
                      summaryCard("Students", "$_studentCount", Colors.teal, Icons.people),
                      summaryCard("Tasks", "$_taskCount", Colors.amber, Icons.task_alt),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      summaryCard("Pending", "$_pendingCount", Colors.redAccent, Icons.pending_actions),
                      summaryCard("Actual Hours", "${_totalActualHours.toStringAsFixed(1)}h", Colors.lightBlueAccent, Icons.access_time),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // ✅ Dashboard Cards
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        dashboardCard(
                          icon: Icons.edit_document,
                          title: "Sign Documents",
                          colors: [Colors.indigo.shade400, Colors.indigo.shade700],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AdminSignatureScreen()),
                            );
                          },
                        ),
                        dashboardCard(
                          icon: Icons.analytics_outlined,
                          title: "Analytics & Reports",
                          colors: [Colors.teal.shade400, Colors.teal.shade700],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AdminAnalyticsScreen()),
                            );
                          },
                        ),
                        dashboardCard(
                          icon: Icons.manage_accounts_outlined,
                          title: "Manage Employee Tasks",
                          colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ManageEmployeeTasksScreen()),
                            );
                          },
                        ),
                        dashboardCard(
                          icon: Icons.feedback_outlined,
                          title: "Feedback",
                          colors: [Colors.orange.shade400, Colors.orange.shade700],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AdminFeedbackScreen()),
                            );
                          },
                        ),
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
}
