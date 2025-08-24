import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  final SignatureController _supervisorSignatureController =
      SignatureController();

  // Dummy logs for testing
  final List<Map<String, dynamic>> _logs = [
    {
      'id': 1,
      'student': 'Juan Dela Cruz',
      'date': 'Aug 24, 2025',
      'task': 'Prepared report',
      'hours': 3,
      'employeeSignature': '✍️ (employee signature here)',
      'approved': false,
    },
    {
      'id': 2,
      'student': 'Maria Santos',
      'date': 'Aug 24, 2025',
      'task': 'Data entry',
      'hours': 5,
      'employeeSignature': '✍️ (employee signature here)',
      'approved': false,
    },
  ];

  void _approveLog(int id) {
    setState(() {
      final index = _logs.indexWhere((log) => log['id'] == id);
      if (index != -1) {
        _logs[index]['approved'] = true;
      }
    });
    _supervisorSignatureController.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Log approved")));
  }

  @override
  void dispose() {
    _supervisorSignatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Supervisor Dashboard")),
      body: ListView.builder(
        itemCount: _logs.length,
        itemBuilder: (context, index) {
          final log = _logs[index];

          return Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Employee: ${log['student']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("Date: ${log['date']}"),
                  Text("Task: ${log['task']}"),
                  Text("Hours: ${log['hours']}"),
                  Text("Employee Signature: ${log['employeeSignature']}"),
                  const Divider(),

                  if (log['approved'] == true)
                    const Text(
                      "✅ Approved",
                      style: TextStyle(color: Colors.green),
                    )
                  else ...[
                    const Text("Supervisor Signature:"),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black26),
                      ),
                      height: 100,
                      child: Signature(
                        controller: _supervisorSignatureController,
                        backgroundColor: Colors.grey[200]!,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            _supervisorSignatureController.clear();
                          },
                          child: const Text("Clear"),
                        ),
                        ElevatedButton(
                          onPressed: () => _approveLog(log['id']),
                          child: const Text("Approve"),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
