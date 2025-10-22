import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🗒️ Admin Feedback Screen
class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen>
    with SingleTickerProviderStateMixin {
  List<String> _students = [];
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final students = keys
        .where((k) => k.startsWith('tasks_'))
        .map((k) => k.replaceFirst('tasks_', ''))
        .toList();

    setState(() {
      _students = students;
    });
    _controller.forward();
  }

  void _openStudentFeedback(String username) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            StudentFeedbackDetailScreen(username: username),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Admin Feedback", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A2E63), Color(0xFF1E88E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _students.isEmpty
            ? const Center(
                child: Text(
                  "No students available",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
            : FadeTransition(
                opacity: _controller,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 100, 16, 20),
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    final delay = index * 0.1;
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final value = Curves.easeOut.transform(
                          (_controller.value - delay).clamp(0.0, 1.0),
                        );
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - value) * 40),
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade700,
                                  child: const Icon(Icons.person,
                                      color: Colors.white),
                                ),
                                title: Text(
                                  student,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                subtitle: const Text(
                                  "Tap to view and add feedback",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    color: Colors.white70),
                                onTap: () => _openStudentFeedback(student),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

/// 📋 Student Feedback Detail Screen
class StudentFeedbackDetailScreen extends StatefulWidget {
  final String username;
  const StudentFeedbackDetailScreen({super.key, required this.username});

  @override
  State<StudentFeedbackDetailScreen> createState() =>
      _StudentFeedbackDetailScreenState();
}

class _StudentFeedbackDetailScreenState
    extends State<StudentFeedbackDetailScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _tasks = [];
  final Map<int, TextEditingController> _feedbackControllers = {};
  final Map<int, TextEditingController> _replyControllers = {};
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('tasks_${widget.username}');
    if (data == null) return;

    final List<dynamic> decoded = jsonDecode(data);
    setState(() {
      _tasks = decoded.map((e) {
        final map = Map<String, dynamic>.from(e);
        if (!map.containsKey('feedback')) map['feedback'] = '';
        if (!map.containsKey('user_reply')) map['user_reply'] = '';
        if (!map.containsKey('date')) map['date'] = DateTime.now().toIso8601String();
        return map;
      }).toList();

      for (int i = 0; i < _tasks.length; i++) {
        _feedbackControllers[i] =
            TextEditingController(text: _tasks[i]['feedback']);
        _replyControllers[i] =
            TextEditingController(text: _tasks[i]['user_reply']);
      }
    });
  }

  Future<void> _saveFeedback(int index) async {
    final prefs = await SharedPreferences.getInstance();
    _tasks[index]['feedback'] = _feedbackControllers[index]?.text ?? '';
    await prefs.setString('tasks_${widget.username}', jsonEncode(_tasks));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Feedback saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _saveReply(int index) async {
    final prefs = await SharedPreferences.getInstance();
    _tasks[index]['user_reply'] = _replyControllers[index]?.text ?? '';
    await prefs.setString('tasks_${widget.username}', jsonEncode(_tasks));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ User reply saved!'),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  @override
  void dispose() {
    for (var c in _feedbackControllers.values) c.dispose();
    for (var c in _replyControllers.values) c.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("${widget.username}'s Tasks"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF004AAD), Color(0xFF5AB2FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _tasks.isEmpty
            ? const Center(
                child: Text(
                  "No tasks found.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 20),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  final feedbackController = _feedbackControllers[index]!;
                  final replyController = _replyControllers[index]!;
                  final delay = 0.1 * index;

                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final value = Curves.easeOut.transform(
                        (_animationController.value - delay).clamp(0.0, 1.0),
                      );
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 40),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task['task'],
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  // Admin Feedback
                                  TextField(
                                    controller: feedbackController,
                                    style:
                                        const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: "Admin Feedback",
                                      labelStyle: const TextStyle(
                                          color: Colors.white70),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.05),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _saveFeedback(index),
                                      icon: const Icon(Icons.save_alt_rounded),
                                      label: const Text("Save Feedback"),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green),
                                    ),
                                  ),
                                  const Divider(color: Colors.white30),
                                  // User Reply
                                  TextField(
                                    controller: replyController,
                                    style:
                                        const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: "User Reply",
                                      labelStyle: const TextStyle(
                                          color: Colors.white70),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.05),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _saveReply(index),
                                      icon: const Icon(Icons.send),
                                      label: const Text("Save Reply"),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.lightBlueAccent),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}


