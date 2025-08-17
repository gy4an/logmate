import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LogTaskScreen extends StatefulWidget {
  const LogTaskScreen({super.key});

  @override
  State<LogTaskScreen> createState() => _LogTaskScreenState();
}

class _LogTaskScreenState extends State<LogTaskScreen> {
  final _taskController = TextEditingController();
  final _hoursController = TextEditingController();

  List<Map<String, String>> _logs = [];

  DateTime _selectedDate = DateTime.now();

  void _addLog() {
    final task = _taskController.text.trim();
    final hours = _hoursController.text.trim();

    if (task.isEmpty || hours.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter task and hours")),
      );
      return;
    }

    setState(() {
      _logs.add({
        'date': DateFormat.yMMMd().format(_selectedDate),
        'task': task,
        'hours': hours,
      });
      _taskController.clear();
      _hoursController.clear();
      _selectedDate = DateTime.now();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Tasks & Hours')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text('Date: ${DateFormat.yMMMd().format(_selectedDate)}'),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _pickDate,
                  child: const Text('Pick Date'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _taskController,
              decoration: const InputDecoration(
                labelText: 'Task Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _hoursController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Hours Worked',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _addLog,
              icon: const Icon(Icons.add),
              label: const Text('Add Entry'),
            ),
            const SizedBox(height: 20),
            const Text('Task Logs:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  return ListTile(
                    title: Text('${log['date']} — ${log['task']}'),
                    subtitle: Text('${log['hours']} hours'),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
