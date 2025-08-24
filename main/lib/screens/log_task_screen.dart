import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';

class LogTaskScreen extends StatefulWidget {
  const LogTaskScreen({super.key});

  @override
  State<LogTaskScreen> createState() => _LogTaskScreenState();
}

class _LogTaskScreenState extends State<LogTaskScreen> {
  final _taskController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Signature controllers
  final SignatureController _userSignatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
  );
  final SignatureController _supervisorSignatureController =
      SignatureController(penStrokeWidth: 2, penColor: Colors.blue);

  List<Map<String, dynamic>> _logs = [];

  void _addLog() {
    final task = _taskController.text.trim();

    if (task.isEmpty ||
        _userSignatureController.isEmpty ||
        _supervisorSignatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete all fields and signatures"),
        ),
      );
      return;
    }

    setState(() {
      _logs.add({
        'date': DateFormat.yMMMd().format(_selectedDate),
        'time': _selectedTime.format(context),
        'task': task,
        'userSignature': _userSignatureController.toPngBytes(),
        'supervisorSignature': _supervisorSignatureController.toPngBytes(),
      });

      _taskController.clear();
      _userSignatureController.clear();
      _supervisorSignatureController.clear();
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  void dispose() {
    _taskController.dispose();
    _userSignatureController.dispose();
    _supervisorSignatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Tasks & Hours')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date Picker
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

            // Time Picker
            Row(
              children: [
                Text('Time: ${_selectedTime.format(context)}'),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _pickTime,
                  child: const Text('Pick Time'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Task description
            TextField(
              controller: _taskController,
              decoration: const InputDecoration(
                labelText: 'Task Name / Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // User signature
            const Text('Employee Signature'),
            Container(
              height: 100,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: Signature(
                controller: _userSignatureController,
                backgroundColor: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => _userSignatureController.clear(),
              child: const Text("Clear Signature"),
            ),

            const SizedBox(height: 10),

            // Supervisor signature
            const Text('Supervisor Approval Signature'),
            Container(
              height: 100,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: Signature(
                controller: _supervisorSignatureController,
                backgroundColor: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => _supervisorSignatureController.clear(),
              child: const Text("Clear Signature"),
            ),

            const SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed: _addLog,
              icon: const Icon(Icons.add),
              label: const Text('Add Entry'),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              'Task Logs:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  return ListTile(
                    title: Text(
                      '${log['date']} ${log['time']} — ${log['task']}',
                    ),
                    subtitle: const Text("Signatures captured"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
