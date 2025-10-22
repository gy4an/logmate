import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:main/screens/login_screen.dart' show LoginScreen;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:main/screens/log_task_screen.dart';
import 'package:main/screens/user_feedback_screen.dart';
import 'package:main/screens/user_analytics_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  final String username;

  const UserDashboardScreen({super.key, required this.username});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  double totalHours = 0;
  int totalTasks = 0;
  int pendingTasks = 0;
  int completedTasks = 0;

  @override
  void initState() {
    super.initState();
    _loadTaskSummary();
  }

  Future<void> _loadTaskSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('tasks_${widget.username}');

    if (storedData == null) {
      setState(() {
        totalTasks = 0;
        completedTasks = 0;
        pendingTasks = 0;
        totalHours = 0;
      });
      return;
    }

    final List<dynamic> decodedList = jsonDecode(storedData);
    final tasks = decodedList.map((t) => Map<String, dynamic>.from(t as Map)).toList();

    setState(() {
      totalTasks = tasks.length;
      completedTasks = tasks.where((t) => t['status'] == 'Completed').length;
      pendingTasks = tasks.where((t) => t['status'] == 'Pending').length;
      totalHours = tasks.fold(0.0, (sum, t) {
        final hoursValue = double.tryParse(t['hours']?.toString() ?? '0') ?? 0.0;
        return sum + hoursValue;
      });
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

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradientColors,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.4),
            offset: const Offset(2, 4),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w400)),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withOpacity(0.4),
              offset: const Offset(2, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 36),
              const SizedBox(height: 10),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0d47a1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "User Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Reload Summary",
            onPressed: _loadTaskSummary,
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.white),
            tooltip: "Logout",
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
            colors: [Color(0xff0d47a1), Color(0xff1976d2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome, ${widget.username} 👋",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text("Here’s your progress summary:",
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 14),

                // ✅ Summary Cards
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildSummaryCard(
                      icon: Icons.access_time,
                      label: "Total Hours",
                      value: totalHours.toStringAsFixed(1),
                      gradientColors: [Colors.teal, Colors.teal.shade700],
                    ),
                    _buildSummaryCard(
                      icon: Icons.list_alt,
                      label: "Tasks",
                      value: "$totalTasks",
                      gradientColors: [Colors.deepPurple, Colors.deepPurple.shade700],
                    ),
                    _buildSummaryCard(
                      icon: Icons.pending_actions,
                      label: "Pending",
                      value: "$pendingTasks",
                      gradientColors: [Colors.orange, Colors.deepOrange.shade700],
                    ),
                    _buildSummaryCard(
                      icon: Icons.check_circle,
                      label: "Completed",
                      value: "$completedTasks",
                      gradientColors: [Colors.green, Colors.green.shade700],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ✅ Action Buttons
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1,
                  children: [
                    _buildActionCard(
                      icon: Icons.assignment,
                      title: "Log Tasks",
                      gradientColors: [Colors.indigo, Colors.indigo.shade700],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LogTaskScreen(username: widget.username),
                          ),
                        );
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.feedback,
                      title: "Feedback",
                      gradientColors: [Colors.orange, Colors.deepOrange],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UserFeedbackScreen(username: widget.username),
                          ),
                        );
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.bar_chart,
                      title: "Reports",
                      gradientColors: [Colors.teal, Colors.teal.shade800],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UserAnalyticsScreen(username: widget.username),
                          ),
                        );
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.settings,
                      title: "Settings",
                      gradientColors: [Colors.purple, Colors.deepPurple.shade800],
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
