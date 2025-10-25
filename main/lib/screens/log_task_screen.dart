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

    if (task.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter a task name')));
      return;
    }

    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please sign before saving')));
      return;
    }

    final Uint8List? sigBytes = await _signatureController.toPngBytes();
    final sigBase64 = sigBytes != null ? base64Encode(sigBytes) : null;

    final now = DateTime.now();
    final newTask = {
      'task': task,
      'studentSignature': sigBase64,
      'completed': false,
      'completionSignature': null,
      'approved': false,
      'startTime': now.toIso8601String(),
      'endTime': null,
      'totalHours': null,
      'timestamp': now.toIso8601String(),
    };

    setState(() {
      _tasks.insert(0, newTask);
      _taskController.clear();
      _signatureController.clear();
    });

    await _saveTasksToPrefs();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Task started successfully')));
  }

  Future<void> _showCompletionPopup(int index) async {
    final SignatureController sigController = SignatureController(
      penStrokeWidth: 2,
      penColor: Colors.black,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AlertDialog(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withOpacity(0.25))),
              title: const Center(
                child: Text("Complete Task",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "End Time: ${TimeOfDay.now().format(context)}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    const Text("Signature:",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 8),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Signature(
                        controller: sigController,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text('Cancel',
                      style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm'),
                  onPressed: () async {
                    if (sigController.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please sign to complete.')),
                      );
                      return;
                    }

                    final sigBytes = await sigController.toPngBytes();
                    final sigBase64 =
                        sigBytes != null ? base64Encode(sigBytes) : null;
                    final now = DateTime.now();
                    final start = DateTime.parse(_tasks[index]['startTime']);
                    final diff = now.difference(start);
                    final hours = diff.inMinutes / 60.0;

                    setState(() {
                      _tasks[index]['completed'] = true;
                      _tasks[index]['completionSignature'] = sigBase64;
                      _tasks[index]['endTime'] = now.toIso8601String();
                      _tasks[index]['totalHours'] = hours;
                    });

                    await _saveTasksToPrefs();
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task marked as completed')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _taskController.dispose();
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
                const SizedBox(height: 10),
                Expanded(
                  child: _tasks.isEmpty
                      ? Center(
                          child: Text('No tasks yet — tap + to add one!',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 15)))
                      : ListView.builder(
                          itemCount: _tasks.length,
                          itemBuilder: (context, i) {
                            final t = _tasks[i];
                            final startTime = t['startTime'] != null
                                ? TimeOfDay.fromDateTime(
                                        DateTime.parse(t['startTime']))
                                    .format(context)
                                : '--';
                            final endTime = t['endTime'] != null
                                ? TimeOfDay.fromDateTime(
                                        DateTime.parse(t['endTime']))
                                    .format(context)
                                : '--';
                            final total = t['totalHours'] != null
                                ? "${t['totalHours'].toStringAsFixed(2)} hrs"
                                : "--";

                            return Card(
                              color: Colors.white.withOpacity(0.12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text(
                                  t['task'] ?? '',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Start: $startTime",
                                        style: const TextStyle(
                                            color: Colors.white70)),
                                    Text("End: $endTime",
                                        style: const TextStyle(
                                            color: Colors.white70)),
                                    if (t['completed'] == true)
                                      Text("Total Worked: $total",
                                          style: const TextStyle(
                                              color: Colors.white70)),
                                    Text(
                                      t['completed'] == true
                                          ? "Status: Completed"
                                          : "Status: In Progress",
                                      style: TextStyle(
                                        color: t['completed'] == true
                                            ? Colors.greenAccent
                                            : Colors.orangeAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: !(t['completed'] ?? false)
                                    ? ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.greenAccent),
                                        onPressed: () =>
                                            _showCompletionPopup(i),
                                        child: const Text('Complete'),
                                      )
                                    : const Icon(Icons.check_circle,
                                        color: Colors.greenAccent),
                              ),
                            );
                          },
                        ),
                )
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
      builder: (_, controller) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: ListView(
              controller: controller,
              children: [
                const Center(
                    child: Icon(Icons.drag_handle,
                        color: Colors.white70, size: 32)),
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
                const SizedBox(height: 12),
                const Text('Signature',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
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
                        onPressed: () => _signatureController.clear(),
                        icon: const Icon(Icons.clear, color: Colors.white),
                        label: const Text('Clear',
                            style: TextStyle(color: Colors.white))),
                    ElevatedButton.icon(
                      onPressed: () {
                        _addTask();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Task'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
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
