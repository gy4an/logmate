import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserAnalyticsScreen extends StatefulWidget {
  const UserAnalyticsScreen({super.key});

  @override
  State<UserAnalyticsScreen> createState() => _UserAnalyticsScreenState();
}

class _UserAnalyticsScreenState extends State<UserAnalyticsScreen> {
  // Dummy data: replace with Firestore data later
  final List<Map<String, dynamic>> _taskLogs = [
    {
      'date': DateTime(2025, 10, 1),
      'task': 'Database Setup',
      'hours': 4.5,
    },
    {
      'date': DateTime(2025, 10, 2),
      'task': 'UI Design',
      'hours': 3.0,
    },
    {
      'date': DateTime(2025, 10, 3),
      'task': 'Backend Integration',
      'hours': 5.0,
    },
    {
      'date': DateTime(2025, 10, 5),
      'task': 'Testing & Debugging',
      'hours': 2.5,
    },
  ];

  double get _totalHours =>
      _taskLogs.fold(0, (sum, item) => sum + (item['hours'] as double));

  int get _totalTasks => _taskLogs.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics & Reports"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Summary
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryTile("Total Tasks", _totalTasks.toString(), Icons.list),
                    _summaryTile(
                      "Total Hours",
                      _totalHours.toStringAsFixed(1),
                      Icons.access_time,
                    ),
                    _summaryTile(
                      "Average per Task",
                      (_totalHours / _totalTasks).toStringAsFixed(1),
                      Icons.bar_chart,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Task Breakdown",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // List of task logs
            Expanded(
              child: ListView.builder(
                itemCount: _taskLogs.length,
                itemBuilder: (context, index) {
                  final log = _taskLogs[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.task_alt, color: Colors.blueAccent),
                      title: Text(log['task']),
                      subtitle: Text(
                        "Date: ${DateFormat('MMM d, yyyy').format(log['date'])}",
                      ),
                      trailing: Text(
                        "${log['hours']} hrs",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryTile(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueAccent),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}
