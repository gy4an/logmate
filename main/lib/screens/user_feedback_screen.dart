import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserFeedbackScreen extends StatefulWidget {
  final String username; // Logged-in user
  const UserFeedbackScreen({super.key, required this.username});

  @override
  State<UserFeedbackScreen> createState() => _UserFeedbackScreenState();
}

class _UserFeedbackScreenState extends State<UserFeedbackScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _tasks = [];
  final Map<int, TextEditingController> _replyControllers = {};
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _loadAdminTasks();
  }

  @override
  void dispose() {
    for (var controller in _replyControllers.values) {
      controller.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  /// Load tasks and admin feedback from SharedPreferences
  Future<void> _loadAdminTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('tasks_${widget.username}');
    if (data == null) return;

    final List<dynamic> decoded = jsonDecode(data);
    setState(() {
      _tasks = decoded.map((e) {
        final map = Map<String, dynamic>.from(e);
        if (!map.containsKey('user_reply')) {
          map['user_reply'] = '';
        }
        if (!map.containsKey('date')) {
          map['date'] = DateTime.now().toIso8601String();
        }
        return map;
      }).toList();

      for (int i = 0; i < _tasks.length; i++) {
        _replyControllers[i] =
            TextEditingController(text: _tasks[i]['user_reply']);
      }
    });
  }

  /// Save user reply back to the same SharedPreferences key
  Future<void> _saveReply(int index) async {
    final prefs = await SharedPreferences.getInstance();
    _tasks[index]['user_reply'] = _replyControllers[index]?.text ?? '';
    await prefs.setString('tasks_${widget.username}', jsonEncode(_tasks));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Reply sent!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundGradient = const LinearGradient(
      colors: [Color(0xFF0A2E63), Color(0xFF1565C0)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Your Tasks Feedback"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: _tasks.isEmpty
                ? Center(
                    child: Text(
                      "No tasks available.",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      final controller = _replyControllers[index]!;
                      final delay = 0.1 * index;

                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(delay, 1.0, curve: Curves.easeOut),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(delay, 1.0, curve: Curves.easeOutBack),
                          )),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Task: ${task['task']}",
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Admin Feedback: ${task['feedback'] ?? 'No feedback yet'}",
                                          style: const TextStyle(
                                              color: Colors.white70, fontSize: 14),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: controller,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            hintText: "Write your reply...",
                                            hintStyle:
                                                const TextStyle(color: Colors.white60),
                                            filled: true,
                                            fillColor: Colors.white.withOpacity(0.05),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                  color: Colors.white30),
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
                                            label: const Text("Send Reply"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.lightBlueAccent,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Feedback Date: ${DateFormat('MMM d, yyyy – hh:mm a').format(DateTime.parse(task['date']))}",
                                          style: const TextStyle(
                                              color: Colors.white54, fontSize: 12),
                                        ),
                                      ],
                                    ),
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
        ),
      ),
    );
  }
}
