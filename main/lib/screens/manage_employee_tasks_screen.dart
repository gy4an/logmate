import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';
import 'employee_task_list_screen.dart';

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
          .where((acc) => acc['username'].toLowerCase().contains(query))
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredAccounts.isEmpty
                      ? const Center(
                          child: Text(
                            'No accounts found.',
                            style: TextStyle(fontSize: 16, color: Colors.white70),
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
                                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                                      color: Colors.white70, size: 18),
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
  bool showPassword = false;
  List<String> tasks = [];

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
      final decoded = jsonDecode(tasksJson);
      tasks = List<String>.from(decoded.map((item) {
        if (item is String) return item;
        if (item is Map && item.containsKey('task')) return item['task'].toString();
        return item.toString();
      }));
    } else {
      tasks = [];
    }

    setState(() {});
  }

  Future<void> _saveChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accountsJson = prefs.getString('accounts');
    if (accountsJson == null) return;

    final List<dynamic> decoded = jsonDecode(accountsJson);
    final List<Map<String, dynamic>> accounts =
        decoded.map((e) => Map<String, dynamic>.from(e)).toList();

    final index = accounts
        .indexWhere((acc) => acc['username'] == widget.account['username']);
    if (index != -1) {
      accounts[index]['username'] = usernameController.text;
      accounts[index]['password'] = passwordController.text;
      accounts[index]['role'] = selectedRole;
      await prefs.setString('accounts', jsonEncode(accounts));
    }

    await prefs.setString(
        'tasks_${usernameController.text}', jsonEncode(tasks));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User details updated!')),
    );

    Navigator.pop(context, true);
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                tasks.add(controller.text);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(
                    'tasks_${widget.account['username']}', jsonEncode(tasks));
                setState(() {});
              }
              Navigator.pop(context);
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

  Future<void> _deleteUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accountsJson = prefs.getString('accounts');
    if (accountsJson == null) return;

    final List<dynamic> decoded = jsonDecode(accountsJson);
    final List<Map<String, dynamic>> accounts =
        decoded.map((e) => Map<String, dynamic>.from(e)).toList();

    accounts.removeWhere((acc) => acc['username'] == widget.account['username']);
    await prefs.setString('accounts', jsonEncode(accounts));
    await prefs.remove('tasks_${widget.account['username']}');

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("${widget.account['username']}'s Profile"),
        actions: [
          IconButton(onPressed: _saveChanges, icon: const Icon(Icons.save_rounded))
        ],
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
          Container(color: Colors.white.withOpacity(0.05)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTextField(usernameController, "Username"),
                const SizedBox(height: 10),
                _buildPasswordField(),
                const SizedBox(height: 10),
                _buildRoleDropdown(),
                const SizedBox(height: 20),
                const Text("Assigned Tasks",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16)),
                const SizedBox(height: 8),
                if (tasks.isEmpty)
                  const Text("No tasks assigned.", style: TextStyle(color: Colors.white70))
                else
                  ...tasks.asMap().entries.map(
                    (entry) => _buildTaskTile(entry.key, entry.value),
                  ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _addTask,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Task"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _deleteUser,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text("Delete User"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Colors.white70),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: TextField(
            controller: passwordController,
            obscureText: !showPassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Password",
              labelStyle: const TextStyle(color: Colors.white70),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    showPassword = !showPassword;
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedRole,
          dropdownColor: Colors.blueGrey[800],
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedRole = value;
              });
            }
          },
          items: roles.map<DropdownMenuItem<String>>((role) {
            return DropdownMenuItem<String>(
              value: role,
              child: Text(role),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTaskTile(int index, String task) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: ListTile(
            title: Text(task, style: const TextStyle(color: Colors.white)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white70),
              onPressed: () => _removeTask(index),
            ),
          ),
        ),
      ),
    );
  }
}
