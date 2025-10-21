import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmployeeTaskListScreen extends StatefulWidget {
  final String username;
  const EmployeeTaskListScreen({super.key, required this.username});

  @override
  State<EmployeeTaskListScreen> createState() => _EmployeeTaskListScreenState();
}

class _EmployeeTaskListScreenState extends State<EmployeeTaskListScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _tasks = [];
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('tasks_${widget.username}');
    if (data == null) return;

    final List<dynamic> decoded = jsonDecode(data);
    setState(() {
      _tasks = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      _animationController.forward();
    });
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
        title: Text(
          "${widget.username}'s Tasks",
          style: const TextStyle(color: Colors.white),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
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
        child: _tasks.isEmpty
            ? const Center(
                child: Text(
                  "No tasks available.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
            : ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 80),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  final isApproved = task['approved'] == true;

                  final animation = Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(index * 0.1, 1.0, curve: Curves.easeOutBack),
                  ));

                  return SlideTransition(
                    position: animation,
                    child: FadeTransition(
                      opacity: _animationController,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.15),
                              Colors.white.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            width: 1.2,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              leading: CircleAvatar(
                                radius: 26,
                                backgroundColor:
                                    isApproved ? Colors.green : Colors.orange,
                                child: Icon(
                                  isApproved ? Icons.check : Icons.pending,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                task['task'] ?? 'Unnamed Task',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Hours: ${task['hours']}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        isApproved
                                            ? Icons.verified_rounded
                                            : Icons.hourglass_bottom_rounded,
                                        size: 16,
                                        color: isApproved
                                            ? Colors.greenAccent
                                            : Colors.amberAccent,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isApproved
                                            ? "Approved ✅"
                                            : "Pending ⏳",
                                        style: TextStyle(
                                          color: isApproved
                                              ? Colors.greenAccent
                                              : Colors.amberAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: isApproved && task['adminSignature'] != null
                                  ? const Icon(
                                      Icons.verified_user_rounded,
                                      color: Colors.lightGreenAccent,
                                      size: 22,
                                    )
                                  : const Icon(
                                      Icons.task_alt_rounded,
                                      color: Colors.white70,
                                      size: 22,
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
