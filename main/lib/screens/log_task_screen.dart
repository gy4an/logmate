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

  Future<void> _saveTask() async {
    if (_taskController.text.isEmpty || _hoursController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add your signature')),
      );
      return;
    }

    final Uint8List? signatureBytes = await _signatureController.toPngBytes();
    if (signatureBytes == null) return;

    final newTask = {
      'task': _taskController.text,
      'hours': _hoursController.text,
      'signature': base64Encode(signatureBytes),
      'approved': false,
      'adminSignature': null,
    };

    setState(() {
      _tasks.add(newTask);
      _taskController.clear();
      _hoursController.clear();
      _signatureController.clear();
    });

    final prefs = await SharedPreferences.getInstance();
    final key = 'tasks_${widget.username}';
    await prefs.setString(key, jsonEncode(_tasks));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task saved successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Task & Hours'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A2E63), Color(0xFF1E88E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Task Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _taskController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter task description',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Hours Worked:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _hoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter hours worked',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Signature:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _signatureController.clear(),
                    child: const Text('Clear Signature'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _saveTask,
                    child: const Text('Save Task'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const Text(
                'Your Logged Tasks:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ..._tasks.map((task) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(task['task']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hours: ${task['hours']}'),
                          const SizedBox(height: 4),
                          Text(
                            task['approved']
                                ? 'Status: Approved ✅'
                                : 'Status: Pending ⏳',
                            style: TextStyle(
                              color: task['approved']
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
