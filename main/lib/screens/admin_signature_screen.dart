import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';
import 'dart:typed_data';

class AdminSignatureScreen extends StatefulWidget {
  const AdminSignatureScreen({super.key});

  @override
  State<AdminSignatureScreen> createState() => _AdminSignatureScreenState();
}

class _AdminSignatureScreenState extends State<AdminSignatureScreen> {
  List<String> _students = [];

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

  void _openStudentTasks(String username) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentTaskApprovalScreen(username: username),
      ),
    );
  }

  void _openAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnalyticsReportScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin - Students"),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _openAnalytics,
            tooltip: "View Reports",
          ),
        ],
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
      body: _students.isEmpty
          ? const Center(child: Text("No students found"))
          : ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.blue),
                    title: Text(student, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Tap to view and sign tasks"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _openStudentTasks(student),
                  ),
                );
              },
            ),
    );
  }
}

// 🧩 Student Task Approval Screen (Same as before)
class StudentTaskApprovalScreen extends StatefulWidget {
  final String username;
  const StudentTaskApprovalScreen({super.key, required this.username});

  @override
  State<StudentTaskApprovalScreen> createState() =>
      _StudentTaskApprovalScreenState();
}

class _StudentTaskApprovalScreenState
    extends State<StudentTaskApprovalScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
  );

  List<Map<String, dynamic>> _tasks = [];
  int? _selectedTaskIndex;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('tasks_${widget.username}');
    if (data == null) return;

    final List<dynamic> decoded = jsonDecode(data);
    setState(() {
      _tasks = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  Future<void> _approveSelectedTask() async {
    if (_selectedTaskIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a task first')),
      );
      return;
    }

    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add your signature')),
      );
      return;
    }

    final Uint8List? adminSig = await _signatureController.toPngBytes();
    if (adminSig == null) return;

    final adminSigEncoded = base64Encode(adminSig);

    setState(() {
      _tasks[_selectedTaskIndex!] = {
        ..._tasks[_selectedTaskIndex!],
        'approved': true,
        'adminSignature': adminSigEncoded,
      };
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasks_${widget.username}', jsonEncode(_tasks));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Task approved for ${widget.username}!')),
    );

    _signatureController.clear();
    setState(() {
      _selectedTaskIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tasks of ${widget.username}"),
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
      body: Column(
        children: [
          Expanded(
            child: _tasks.isEmpty
                ? const Center(child: Text("No tasks found"))
                : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      final isSelected = _selectedTaskIndex == index;

                      return Card(
                        color: isSelected
                            ? Colors.blue.shade100
                            : task['approved']
                                ? Colors.green.shade50
                                : Colors.white,
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(task['task']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hours: ${task['hours']}'),
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
                          onTap: () {
                            if (!task['approved']) {
                              setState(() {
                                _selectedTaskIndex = index;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
          const Divider(),
          if (_selectedTaskIndex != null)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
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
                      controller: _signatureController,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text("Approve Selected Task"),
                        onPressed: _approveSelectedTask,
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => _signatureController.clear(),
                        child: const Text("Clear"),
                      ),
                    ],
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// 🧾 Analytics Report Screen
class AnalyticsReportScreen extends StatefulWidget {
  const AnalyticsReportScreen({super.key});

  @override
  State<AnalyticsReportScreen> createState() => _AnalyticsReportScreenState();
}

class _AnalyticsReportScreenState extends State<AnalyticsReportScreen> {
  List<Map<String, dynamic>> _report = [];

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final studentKeys = keys.where((key) => key.startsWith('tasks_')).toList();

    final List<Map<String, dynamic>> tempReport = [];

    for (final key in studentKeys) {
      final studentName = key.replaceFirst('tasks_', '');
      final data = prefs.getString(key);
      if (data == null) continue;

      final List<dynamic> decoded = jsonDecode(data);
      final tasks = decoded.map((e) => Map<String, dynamic>.from(e)).toList();

      final totalTasks = tasks.length;
      final approvedTasks = tasks.where((t) => t['approved'] == true).length;
      final totalHours = tasks.fold<double>(
        0,
        (sum, t) => sum + double.tryParse(t['hours'].toString())!,
      );

      final approvalRate = totalTasks == 0
          ? 0
          : ((approvedTasks / totalTasks) * 100).toStringAsFixed(1);

      tempReport.add({
        'student': studentName,
        'tasks': totalTasks,
        'approved': approvedTasks,
        'hours': totalHours,
        'rate': approvalRate,
      });
    }

    setState(() {
      _report = tempReport;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics Report"),
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
      body: _report.isEmpty
          ? const Center(child: Text("No data to display"))
          : ListView.builder(
              itemCount: _report.length,
              itemBuilder: (context, index) {
                final student = _report[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(student['student']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total Tasks: ${student['tasks']}"),
                        Text("Approved: ${student['approved']}"),
                        Text("Total Hours: ${student['hours']}"),
                        Text("Approval Rate: ${student['rate']}%"),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
