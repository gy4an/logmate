import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserAnalyticsScreen extends StatefulWidget {
  final String username;
  const UserAnalyticsScreen({super.key, required this.username});

  @override
  State<UserAnalyticsScreen> createState() => _UserAnalyticsScreenState();
}

class _UserAnalyticsScreenState extends State<UserAnalyticsScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _taskLogs = [];
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
    _loadTaskLogs();
  }

  Future<void> _loadTaskLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('tasks_${widget.username}');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      setState(() {
        _taskLogs = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  double _parseHours(dynamic hours) {
    if (hours is double) return hours;
    if (hours is int) return hours.toDouble();
    if (hours is String) return double.tryParse(hours) ?? 0;
    return 0;
  }

  double get _totalHours => _taskLogs.fold(0, (sum, item) => sum + _parseHours(item['hours']));

  int get _totalTasks => _taskLogs.length;

  double get _averageHours => _totalTasks > 0 ? _totalHours / _totalTasks : 0;

  DateTime _parseDate(String? dateStr) {
    if (dateStr == null) return DateTime.now();
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Analytics & Reports"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A2E63), Color(0xFF5AB2FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Summary cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _summaryCard("Total Tasks", _totalTasks.toString(), Icons.list, Colors.orange),
                    _summaryCard("Total Hours", _totalHours.toStringAsFixed(1), Icons.access_time, Colors.green),
                    _summaryCard("Avg Hours", _averageHours.toStringAsFixed(1), Icons.bar_chart, Colors.purple),
                  ],
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Task Breakdown",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _taskLogs.isEmpty
                      ? const Center(
                          child: Text(
                            "No task logs yet.",
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _taskLogs.length,
                          itemBuilder: (context, index) {
                            final log = _taskLogs[index];
                            final hours = _parseHours(log['hours']);
                            final date = _parseDate(log['date']);
                            return FadeTransition(
                              opacity: _animationController,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  color: Colors.white.withOpacity(0.15),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blueAccent.withOpacity(0.8),
                                      child: const Icon(Icons.task_alt, color: Colors.white),
                                    ),
                                    title: Text(
                                      log['task'] ?? '',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      "Date: ${DateFormat('MMM d, yyyy').format(date)}",
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    trailing: Text(
                                      "${hours.toStringAsFixed(1)} hrs",
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6, offset: const Offset(2, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 13, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
