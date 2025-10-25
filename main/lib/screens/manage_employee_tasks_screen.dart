import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';

class ManageEmployeeTasksScreen extends StatefulWidget {
  const ManageEmployeeTasksScreen({super.key});

  @override
  State<ManageEmployeeTasksScreen> createState() =>
      _ManageEmployeeTasksScreenState();
}

class _ManageEmployeeTasksScreenState extends State<ManageEmployeeTasksScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _filteredAccounts = [];
  TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _searchController.addListener(_filterAccounts);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accountsJson = prefs.getString('accounts');

    await Future.delayed(const Duration(milliseconds: 300));

    if (accountsJson != null) {
      final List<dynamic> decoded = jsonDecode(accountsJson);
      setState(() {
        _accounts =
            decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        _filteredAccounts = List.from(_accounts);
      });
      _animationController.forward();
    }
  }

  void _filterAccounts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAccounts = _accounts
          .where((acc) =>
              (acc['username'] as String).toLowerCase().contains(query))
          .toList();
    });
  }

  void _openUserDetails(Map<String, dynamic> account) async {
    final updated = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => UserDetailsScreen(account: account),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    if (updated == true) {
      _loadAccounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Manage Employee Tasks',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(seconds: 6),
            curve: Curves.easeInOut,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A2E63), Color(0xFF1565C0), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Container(color: Colors.white.withOpacity(0.05)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Search employee...",
                        hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.white),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredAccounts.isEmpty
                      ? const Center(
                          child: Text(
                            'No accounts found.',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredAccounts.length,
                          itemBuilder: (context, index) {
                            final account = _filteredAccounts[index];
                            final isAdmin = account['role'] == 'admin';

                            return GestureDetector(
                              onTap: () => _openUserDetails(account),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.2),
                                      Colors.white.withOpacity(0.05),
                                    ],
                                  ),
                                  border: Border.all(
                                    width: 1.2,
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isAdmin
                                        ? Colors.redAccent
                                        : Colors.blueAccent,
                                    child: Icon(
                                      isAdmin
                                          ? Icons.admin_panel_settings_rounded
                                          : Icons.person_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    account['username'],
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'Role: ${account['role']}',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                  trailing: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Colors.white70,
                                      size: 18),
                                ),
                              ),
                            );
                          },
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

class UserDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> account;
  const UserDetailsScreen({super.key, required this.account});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  late TextEditingController usernameController;
  late TextEditingController passwordController;
  String selectedRole = "";
  List<Map<String, dynamic>> tasks = [];

  final List<String> roles = ['admin', 'user'];

  @override
  void initState() {
    super.initState();
    usernameController =
        TextEditingController(text: widget.account['username']);
    passwordController =
        TextEditingController(text: widget.account['password']);
    selectedRole = widget.account['role'];
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson =
        prefs.getString('tasks_${widget.account['username']}');

    if (tasksJson != null) {
      final List decoded = jsonDecode(tasksJson);
      tasks = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    setState(() {});
  }

  Future<void> _saveChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accountsJson = prefs.getString('accounts');

    if (accountsJson != null) {
      final List decoded = jsonDecode(accountsJson);
      final List<Map<String, dynamic>> accounts =
          decoded.map((e) => Map<String, dynamic>.from(e)).toList();

      final index = accounts.indexWhere(
          (acc) => acc['username'] == widget.account['username']);

      if (index != -1) {
        accounts[index]['username'] = usernameController.text.trim();
        accounts[index]['password'] = passwordController.text.trim();
        accounts[index]['role'] = selectedRole;

        await prefs.setString('accounts', jsonEncode(accounts));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Account updated successfully."),
              duration: Duration(seconds: 2)),
        );
      }
    }
  }

  Future<void> _addTask() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Assign Task"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter new task"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final newTask = {
                  'task': controller.text.trim(),
                  'hours': null,
                  'approved': false,
                  'signature': null,
                  'adminSignature': null,
                  'startTime': DateTime.now().toIso8601String(),
                  'completedTime': null,
                };

                tasks.insert(0, newTask);

                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(
                  'tasks_${widget.account['username']}',
                  jsonEncode(tasks),
                );

                setState(() {});
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _removeTask(int index) async {
    tasks.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'tasks_${widget.account['username']}', jsonEncode(tasks));
    setState(() {});
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return "—";
    final date = DateTime.tryParse(isoString);
    if (date == null) return "—";
    return "${date.month}/${date.day}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  String _calculateHours(String? start, String? end) {
    if (start == null || end == null) return "";
    final startTime = DateTime.tryParse(start);
    final endTime = DateTime.tryParse(end);
    if (startTime == null || endTime == null) return "";
    final diff = endTime.difference(startTime);
    final hours = diff.inMinutes / 60.0;
    return "${hours.toStringAsFixed(2)} hrs";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("${widget.account['username']}'s Profile"),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A2E63), Color(0xFF1565C0), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Editable Account Info Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Account Details",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: usernameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Username",
                          labelStyle: TextStyle(color: Colors.white70),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Password",
                          labelStyle: TextStyle(color: Colors.white70),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        dropdownColor: const Color(0xFF0A2E63),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Role",
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        items: roles
                            .map((role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedRole = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _saveChanges,
                        icon: const Icon(Icons.save),
                        label: const Text("Save Changes"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

// Assigned Tasks Header + Add Button Row
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      "Assigned Tasks",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontSize: 16,
      ),
    ),
    IconButton(
      onPressed: _addTask,
      icon: const Icon(Icons.add_circle_rounded, color: Colors.white),
      tooltip: "Assign New Task",
    ),
  ],
),
const SizedBox(height: 10),

if (tasks.isEmpty)
  const Text(
    "No tasks assigned.",
    style: TextStyle(color: Colors.white70),
  )
else
  ...tasks.asMap().entries.map(
        (entry) => _buildTaskTile(entry.key, entry.value),
      ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(int index, Map<String, dynamic> task) {
    final String? startTime = task['startTime'];
    final String? completedTime = task['completedTime'];
    final String totalHours = _calculateHours(startTime, completedTime);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05)
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: ListTile(
            title: Text(
              task['task'] ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Assigned: ${_formatDateTime(startTime)}",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (completedTime != null)
                  Text(
                    "Completed: ${_formatDateTime(completedTime)}",
                    style:
                        const TextStyle(color: Colors.greenAccent, fontSize: 13),
                  ),
                if (totalHours.isNotEmpty)
                  Text(
                    "Total Hours: $totalHours",
                    style:
                        const TextStyle(color: Colors.amberAccent, fontSize: 13),
                  ),
              ],
            ),
            trailing: IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: Colors.white70),
              onPressed: () => _removeTask(index),
            ),
          ),
        ),
      ),
    );
  }
}
