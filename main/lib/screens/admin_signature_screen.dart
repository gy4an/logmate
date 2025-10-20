import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';

class AdminSignatureScreen extends StatefulWidget {
  const AdminSignatureScreen({super.key});

  @override
  State<AdminSignatureScreen> createState() => _AdminSignatureScreenState();
}

class _AdminSignatureScreenState extends State<AdminSignatureScreen> {
  final SignatureController _adminSignatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.blue,
  );

  List<String> _students = [];
  String? _selectedStudent;
  List<Map<String, dynamic>> _studentTasks = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final studentNames = keys
        .where((key) => key.startsWith('tasks_'))
        .map((key) => key.replaceFirst('tasks_', ''))
        .toList();

    setState(() {
      _students = studentNames;
    });
  }

  Future<void> _loadStudentTasks(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('tasks_$username');
    if (data == null) return;

    final List<dynamic> decoded = jsonDecode(data);
    setState(() {
      _selectedStudent = username;
      _studentTasks = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  Future<void> _approveAndSignTasks() async {
    if (_selectedStudent == null) return;

    if (_adminSignatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add your signature first')),
      );
      return;
    }

    final Uint8List? adminSig = await _adminSignatureController.toPngBytes();
    if (adminSig == null) return;

    final adminSigEncoded = base64Encode(adminSig);

    // Update approval status and save
    for (var task in _studentTasks) {
      task['approved'] = true;
      task['adminSignature'] = adminSigEncoded;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasks_$_selectedStudent', jsonEncode(_studentTasks));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tasks approved and signed for $_selectedStudent')),
    );

    setState(() {
      _adminSignatureController.clear();
      _selectedStudent = null;
      _studentTasks = [];
    });
  }

  // 🧱 UI: Student List
  Widget _buildStudentList() {
    return ListView.builder(
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        return ListTile(
          leading: const Icon(Icons.person, color: Colors.blue),
          title: Text(student),
          subtitle: const Text("Tap to view logged tasks"),
          onTap: () => _loadStudentTasks(student),
        );
      },
    );
  }

  // 🧱 UI: Student Task List + Signature
  Widget _buildTaskDetails() {
    if (_selectedStudent == null) {
      return const Center(
        child: Text(
          "Select a student to review their tasks",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tasks of $_selectedStudent",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: _studentTasks.length,
            itemBuilder: (context, index) {
              final task = _studentTasks[index];
              return Card(
                child: ListTile(
                  title: Text(task['task']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hours: ${task['hours']}"),
                      Text(
                        task['approved']
                            ? "Status: Approved ✅"
                            : "Status: Pending ⏳",
                        style: TextStyle(
                          color: task['approved'] ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Admin Signature:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Signature(
            controller: _adminSignatureController,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text("Approve & Sign"),
              onPressed: _approveAndSignTasks,
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () => _adminSignatureController.clear(),
              child: const Text("Clear"),
            ),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Task Approval & Signature"),
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
      body: Row(
        children: [
          // Left: Student List
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.blue.shade50,
              child: _buildStudentList(),
            ),
          ),
          // Right: Task + Signature
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildTaskDetails(),
            ),
          ),
        ],
      ),
    );
  }
}
