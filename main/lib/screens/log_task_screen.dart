import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';

class LogTaskScreen extends StatefulWidget {
  final String username;
  const LogTaskScreen({super.key, required this.username});

  @override
  State<LogTaskScreen> createState() => _LogTaskScreenState();
}

class _LogTaskScreenState extends State<LogTaskScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
  );

  List<Map<String, dynamic>> _tasks = [];
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'tasks_${widget.username}';
    final data = prefs.getString(key);
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      setState(() {
        _tasks = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
      _animationController.forward();
    }
  }

  Future<void> _saveTasksToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'tasks_${widget.username}';
    await prefs.setString(key, jsonEncode(_tasks));
  }

  Future<void> _addTask() async {
    final task = _taskController.text.trim();
    final hours = _hoursController.text.trim();

    if (task.isEmpty || hours.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign before saving')),
      );
      return;
    }

    final Uint8List? sigBytes = await _signatureController.toPngBytes();
    final sigBase64 = sigBytes != null ? base64Encode(sigBytes) : null;

    final newTask = {
      'task': task,
      'hours': hours,
      'signature': sigBase64,
      'approved': false,
      'timestamp': DateTime.now().toIso8601String(),
    };

    setState(() {
      _tasks.insert(0, newTask);
      _taskController.clear();
      _hoursController.clear();
      _signatureController.clear();
    });

    await _saveTasksToPrefs();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task saved successfully')),
    );
  }

  Future<void> _clearAllTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'tasks_${widget.username}';
    await prefs.remove(key);
    setState(() => _tasks.clear());
  }

  @override
  void dispose() {
    _animationController.dispose();
    _taskController.dispose();
    _hoursController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const topGradientA = Color(0xFF0A2E63);
    const topGradientB = Color(0xFF1565C0);
    const cardAccent = Color(0xFF1E88E5);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Task Logs"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white70),
            tooltip: "Clear all tasks",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear all tasks?'),
                  content: const Text('This will delete all your logged tasks.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true) _clearAllTasks();
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [topGradientA, topGradientB],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Welcome, ${widget.username}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Your Logged Tasks',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _tasks.isEmpty
                      ? Center(
                          child: Text(
                            'No tasks yet — tap + to add one!',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 15),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _tasks.length,
                          itemBuilder: (context, i) {
                            final t = _tasks[i];
                            final sig = t['signature'] as String?;
                            return FadeTransition(
                              opacity: CurvedAnimation(
                                  parent: _animationController,
                                  curve:
                                      Interval(0, 1, curve: Curves.easeInOut)),
                              child: Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 6.0),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                color: Colors.white.withOpacity(0.12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        cardAccent.withOpacity(0.3),
                                    child: const Icon(Icons.task_alt,
                                        color: Colors.white),
                                  ),
                                  title: Text(
                                    t['task'] ?? '',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        "Hours: ${t['hours'] ?? '0'}",
                                        style: const TextStyle(
                                            color: Colors.white70),
                                      ),
                                      Text(
                                        t['approved'] == true
                                            ? "Status: Approved"
                                            : "Status: Pending",
                                        style: TextStyle(
                                          color: t['approved'] == true
                                              ? Colors.greenAccent
                                              : Colors.orangeAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: sig != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Image.memory(
                                            base64Decode(sig),
                                            width: 60,
                                            height: 40,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(Icons.edit_document,
                                          color: Colors.white70),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: cardAccent,
        child: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => _buildFrostedAddTaskSheet(context),
          );
        },
      ),
    );
  }

  Widget _buildFrostedAddTaskSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: ListView(
              controller: controller,
              children: [
                const Center(
                  child: Icon(Icons.drag_handle, color: Colors.white70, size: 32),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _taskController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.assignment_outlined,
                        color: Colors.white),
                    hintText: 'Task description',
                    hintStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _hoursController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon:
                        const Icon(Icons.access_time, color: Colors.white),
                    hintText: 'Hours worked (e.g. 3.5)',
                    hintStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text('Your signature',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white70),
                  ),
                  child: Signature(
                    controller: _signatureController,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      label: const Text('Clear',
                          style: TextStyle(color: Colors.white)),
                      onPressed: () => _signatureController.clear(),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save_alt),
                      label: const Text('Save Task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        _addTask();
                        Navigator.pop(context);
                      },
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
