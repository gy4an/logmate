import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:main/screens/login_screen.dart';
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
    final key = 'tasks_${widget.username}';
    final storedData = prefs.getString(key);

    if (storedData == null || storedData.isEmpty) {
      setState(() {
        totalTasks = 0;
        completedTasks = 0;
        pendingTasks = 0;
        totalHours = 0;
      });
      return;
    }

    try {
      final decoded = jsonDecode(storedData);
      List<Map<String, dynamic>> tasks = [];

      if (decoded is List) {
        tasks = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      double computedHours = 0;
      for (var t in tasks) {
        final start = t['startTime'] != null
            ? DateTime.tryParse(t['startTime'])
            : null;
        final end = t['endTime'] != null
            ? DateTime.tryParse(t['endTime'])
            : null;

        if (start != null && end != null) {
          final duration = end.difference(start).inMinutes / 60.0;
          computedHours += duration;
        }
      }

      setState(() {
        totalTasks = tasks.length;
        completedTasks = tasks.where((t) => t['completed'] == true).length;
        pendingTasks = tasks.where((t) => t['completed'] != true).length;
        totalHours = computedHours;
      });
    } catch (e) {
      debugPrint("⚠️ Error decoding tasks: $e");
      setState(() {
        totalTasks = 0;
        completedTasks = 0;
        pendingTasks = 0;
        totalHours = 0;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUser');

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
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
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
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
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 38),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: 0.8,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Reload Summary",
            onPressed: _loadTaskSummary,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Logout",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Confirm Logout"),
                  content: const Text("Do you want to logout?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              );
              if (confirm == true) _logout();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 👋 Welcome Text
                    Text(
                      "Welcome back, ${widget.username} 👋",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(1, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Here’s your progress summary:",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ✅ Summary cards
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
                          value: totalHours.toStringAsFixed(2),
                          gradientColors: [Colors.teal, Colors.teal.shade700],
                        ),
                        _buildSummaryCard(
                          icon: Icons.list_alt,
                          label: "Tasks",
                          value: "$totalTasks",
                          gradientColors: [
                            Colors.deepPurple,
                            Colors.deepPurple.shade700,
                          ],
                        ),
                        _buildSummaryCard(
                          icon: Icons.pending_actions,
                          label: "Pending",
                          value: "$pendingTasks",
                          gradientColors: [
                            Colors.orange,
                            Colors.deepOrange.shade700,
                          ],
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

                    // ✅ Action buttons
                    Column(
                      children: [
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
                              gradientColors: [
                                Colors.indigo,
                                Colors.indigo.shade700,
                              ],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LogTaskScreen(
                                      username: widget.username,
                                    ),
                                  ),
                                ).then((_) => _loadTaskSummary());
                              },
                            ),
                            _buildActionCard(
                              icon: Icons.feedback,
                              title: "Feedback",
                              gradientColors: [
                                Colors.orange,
                                Colors.deepOrange,
                              ],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UserFeedbackScreen(
                                      username: widget.username,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // ✅ ONE LARGE REPORT BUTTON
                        SizedBox(
                          height: 120,
                          width: double.infinity,
                          child: _buildActionCard(
                            icon: Icons.bar_chart,
                            title: "Reports",
                            gradientColors: [Colors.teal, Colors.teal.shade800],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserAnalyticsScreen(
                                    username: widget.username,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
