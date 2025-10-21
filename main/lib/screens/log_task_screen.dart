// lib/screens/log_task_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';

class LogTaskScreen extends StatefulWidget {
  final String username;
  const LogTaskScreen({super.key, required this.username});

  @override
  State<LogTaskScreen> createState() => _LogTaskScreenState();
}

class _LogTaskScreenState extends State<LogTaskScreen> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
  );

  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
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
      _tasks.insert(0, newTask); // newest first
      _taskController.clear();
      _hoursController.clear();
      _signatureController.clear();
    });

    await _saveTasksToPrefs();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task saved')),
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
    _taskController.dispose();
    _hoursController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Colors & style aligned with your dashboards
    const topGradientA = Color(0xFF0A2E63);
    const topGradientB = Color(0xFF1565C0);
    const cardAccent = Color(0xFF1E88E5);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // floating on gradient
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Log Task & Hours',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
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
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              children: [
                // Welcome / info row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withOpacity(0.12),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Log tasks and capture your signature',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white70),
                      tooltip: 'Clear all tasks',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Clear all tasks?'),
                            content: const Text('This will delete all your local tasks.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (confirm == true) _clearAllTasks();
                      },
                    )
                  ],
                ),

                const SizedBox(height: 16),

                // Form card
                Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Task field
                        TextField(
                          controller: _taskController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.assignment_outlined),
                            hintText: 'Task description',
                            filled: true,
                            fillColor: const Color(0xFFF5F7FB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Hours field
                        TextField(
                          controller: _hoursController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.access_time),
                            hintText: 'Hours worked (e.g. 3.5)',
                            filled: true,
                            fillColor: const Color(0xFFF5F7FB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Signature box
                        const Text('Your signature', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Signature(
                            controller: _signatureController,
                            backgroundColor: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear'),
                              onPressed: () => _signatureController.clear(),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.save_alt),
                              label: const Text('Save Task'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cardAccent,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _addTask,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Section title
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Your Logged Tasks',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Task list (cards)
                Expanded(
                  child: _tasks.isEmpty
                      ? Center(
                          child: Text(
                            'No tasks yet — add your first task above.',
                            style: TextStyle(color: Colors.white.withOpacity(0.8)),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: _tasks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final t = _tasks[i];
                            final sig = t['signature'] as String?;
                            return Card(
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: cardAccent.withOpacity(0.12),
                                  child: Icon(Icons.task_alt, color: cardAccent),
                                ),
                                title: Text(t['task'] ?? ''),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    Text('Hours: ${t['hours'] ?? ''}'),
                                    const SizedBox(height: 4),
                                    Text(
                                      t['approved'] == true ? 'Status: Approved' : 'Status: Pending',
                                      style: TextStyle(
                                        color: t['approved'] == true ? Colors.green : Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: sig != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.memory(
                                          base64Decode(sig),
                                          width: 72,
                                          height: 48,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(Icons.edit_document),
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
}
