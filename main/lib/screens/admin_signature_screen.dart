import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';

/// 🌐 Admin Signature Main Screen
class AdminSignatureScreen extends StatefulWidget {
  const AdminSignatureScreen({super.key});

  @override
  State<AdminSignatureScreen> createState() => _AdminSignatureScreenState();
}

class _AdminSignatureScreenState extends State<AdminSignatureScreen>
    with SingleTickerProviderStateMixin {
  List<String> _students = [];
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
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

    _controller.forward();
  }

  void _openStudentTasks(String username) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => StudentTaskApprovalScreen(username: username),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        title: const Text("Admin - Students", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            onPressed: _openAnalytics,
            tooltip: "View Reports",
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A2E63), Color(0xFF1E88E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _students.isEmpty
            ? const Center(
                child: Text(
                  "No students found",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(top: 100, bottom: 20),
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  final student = _students[index];
                  final delay = index * 0.05;

                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final animationValue = Curves.easeOutBack.transform(
                      (_controller.value - delay).clamp(0.0, 1.0),
                      ).clamp(0.0, 1.0); // <-- clamp AFTER curve
                      return Opacity(
                        opacity: animationValue,
                        child: Transform.translate(
                          offset: Offset(0, (1 - animationValue) * 30),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade700,
                                child: const Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(student,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                              subtitle: const Text("Tap to view and sign tasks",
                                  style: TextStyle(color: Colors.white70)),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, color: Colors.white70),
                              onTap: () => _openStudentTasks(student),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// 📝 Student Task Approval Screen
class StudentTaskApprovalScreen extends StatefulWidget {
  final String username;
  const StudentTaskApprovalScreen({super.key, required this.username});

  @override
  State<StudentTaskApprovalScreen> createState() =>
      _StudentTaskApprovalScreenState();
}

class _StudentTaskApprovalScreenState extends State<StudentTaskApprovalScreen>
    with SingleTickerProviderStateMixin {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
  );

  List<Map<String, dynamic>> _tasks = [];
  int? _selectedTaskIndex;

  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _loadTasks();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _signatureController.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a task first')));
      return;
    }

    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please add signature')));
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
      SnackBar(
        content: Text('✅ Task approved for ${widget.username}!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade600,
      ),
    );

    _signatureController.clear();
    setState(() => _selectedTaskIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "Tasks of ${widget.username}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Stack(
        children: [
          /// 🌈 Animated gradient background
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(const Color(0xFF004AAD),
                          const Color(0xFF5AB2FF), _bgController.value)!,
                      Color.lerp(const Color(0xFF0062E6),
                          const Color(0xFF00C6FF), 1 - _bgController.value)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),

          /// 🪞 Main content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      final isSelected = _selectedTaskIndex == index;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.95)
                              : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? Colors.blueAccent : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: task['approved']
                                ? Colors.green
                                : Colors.blueAccent,
                            child: Icon(
                              task['approved']
                                  ? Icons.check_rounded
                                  : Icons.assignment_rounded,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(task['task'],
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              'Hours: ${task['hours']}  •  ${task['approved'] ? 'Approved' : 'Pending'}',
                              style: TextStyle(
                                color: task['approved']
                                    ? Colors.green.shade700
                                    : Colors.orange.shade800,
                              )),
                          onTap: () {
                            if (!task['approved']) {
                              setState(() => _selectedTaskIndex = index);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),

                /// ✍️ Signature Panel
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) {
                    final offsetAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                        .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
                    return SlideTransition(
                        position: offsetAnim, child: FadeTransition(opacity: anim, child: child));
                  },
                  child: _selectedTaskIndex == null
                      ? const SizedBox.shrink()
                      : Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, -3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text("Admin Signature",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 8),
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade400),
                                  color: Colors.white,
                                ),
                                child: Signature(controller: _signatureController, backgroundColor: Colors.white),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                                    ),
                                    icon: const Icon(Icons.check_circle_outline),
                                    label: const Text("Approve Task"),
                                    onPressed: _approveSelectedTask,
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.clear),
                                    label: const Text("Clear"),
                                    onPressed: () => _signatureController.clear(),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 📊 Analytics Report Screen
class AnalyticsReportScreen extends StatefulWidget {
  const AnalyticsReportScreen({super.key});

  @override
  State<AnalyticsReportScreen> createState() => _AnalyticsReportScreenState();
}

class _AnalyticsReportScreenState extends State<AnalyticsReportScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _report = [];
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
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
      final totalHours = tasks.fold<double>(0,
          (sum, t) => sum + (double.tryParse(t['hours']?.toString() ?? '0') ?? 0));

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

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text("Analytics Report", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A2E63), Color(0xFF1E88E5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _controller,
          child: _report.isEmpty
              ? const Center(
                  child: Text(
                    "No data to display",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 100, 16, 20),
                  itemCount: _report.length,
                  itemBuilder: (context, index) {
                    final student = _report[index];
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final value = Curves.easeOut.transform(
                          (_controller.value - (index * 0.1)).clamp(0.0, 1.0),
                        );
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - value) * 40),
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade700,
                                  child: const Icon(Icons.person, color: Colors.white),
                                ),
                                title: Text(
                                  student['student'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _infoRow(Icons.task, "Total Tasks",
                                          student['tasks'].toString()),
                                      _infoRow(Icons.check_circle, "Approved",
                                          student['approved'].toString()),
                                      _infoRow(Icons.access_time, "Total Hours",
                                          student['hours'].toString()),
                                      _infoRow(Icons.percent, "Approval Rate",
                                          "${student['rate']}%"),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 6),
          Text(
            "$label: ",
            style: const TextStyle(color: Colors.white70),
          ),
          Text(value,
              style:
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
