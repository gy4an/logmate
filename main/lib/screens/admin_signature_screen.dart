import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class AdminSignatureScreen extends StatefulWidget {
  const AdminSignatureScreen({Key? key}) : super(key: key);

  @override
  State<AdminSignatureScreen> createState() => _AdminSignatureScreenState();
}

class _AdminSignatureScreenState extends State<AdminSignatureScreen> {
  // Mock student list — replace with Firebase or DB later
  final List<Map<String, dynamic>> _students = [
    {'id': 'S001', 'name': 'Ana Garcia', 'course': 'BSCS', 'year': 3, 'signed': false},
    {'id': 'S002', 'name': 'Ben Lopez', 'course': 'BSIT', 'year': 2, 'signed': false},
    {'id': 'S003', 'name': 'Cora Dela Cruz', 'course': 'BSIT', 'year': 4, 'signed': true},
  ];

  void _openStudent(Map<String, dynamic> student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentSignatureDetail(student: student),
      ),
    ).then((updated) {
      if (updated != null) {
        setState(() {
          final index = _students.indexWhere((s) => s['id'] == updated['id']);
          if (index != -1) _students[index] = updated;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Signature Document')),
      body: ListView.builder(
        itemCount: _students.length,
        itemBuilder: (context, i) {
          final s = _students[i];
          return ListTile(
            leading: CircleAvatar(child: Text(s['name'][0])),
            title: Text(s['name']),
            subtitle: Text('${s['course']} • Year ${s['year']}'),
            trailing: Icon(
              s['signed'] ? Icons.check_circle : Icons.edit,
              color: s['signed'] ? Colors.green : Colors.grey,
            ),
            onTap: () => _openStudent(s),
          );
        },
      ),
    );
  }
}

class StudentSignatureDetail extends StatefulWidget {
  final Map<String, dynamic> student;
  const StudentSignatureDetail({Key? key, required this.student}) : super(key: key);

  @override
  State<StudentSignatureDetail> createState() => _StudentSignatureDetailState();
}

class _StudentSignatureDetailState extends State<StudentSignatureDetail> {
  late SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(penStrokeWidth: 2, penColor: Colors.black);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveSignature() {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign before saving.')),
      );
      return;
    }
    setState(() => widget.student['signed'] = true);
    Navigator.pop(context, widget.student);
  }

  void _clearSignature() => _controller.clear();

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    return Scaffold(
      appBar: AppBar(title: Text(s['name'])),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${s['course']} • Year ${s['year']}'),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Signature Area:', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  color: Colors.white,
                ),
                child: Signature(controller: _controller, backgroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _saveSignature,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _clearSignature,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
