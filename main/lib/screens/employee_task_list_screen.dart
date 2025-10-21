import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EmployeeTaskListScreen extends StatefulWidget {
  final String username;
  const EmployeeTaskListScreen({super.key, required this.username});

  @override
  State<EmployeeTaskListScreen> createState() => _EmployeeTaskListScreenState();
}

class _EmployeeTaskListScreenState extends State<EmployeeTaskListScreen>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _tasks = [];
  final _taskController = TextEditingController();
  final _hoursController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString('tasks_${widget.username}');
    if (tasksJson != null) {
      final List<dynamic> decoded = jsonDecode(tasksJson);
      for (var task in decoded) {
        _tasks.add(Map<String, dynamic>.from(task));
      }
      setState(() {});
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasks_${widget.username}', jsonEncode(_tasks));
  }

  void _addTask() {
    final taskName = _taskController.text.trim();
    final hours = _hoursController.text.trim();
    if (taskName.isEmpty || hours.isEmpty) return;

    final newTask = {'task': taskName, 'hours': hours};

    setState(() {
      _tasks.insert(0, newTask);
      _listKey.currentState?.insertItem(0);
    });

    _saveTasks();
    _taskController.clear();
    _hoursController.clear();
  }

  void _deleteTask(int index) {
    final removedTask = _tasks[index];
    setState(() {
      _tasks.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildTaskCard(removedTask, animation),
        duration: const Duration(milliseconds: 300),
      );
    });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: AppBar(
            title: Text(
              "${widget.username} - Tasks",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // 🧩 Task Input Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _taskController,
                        decoration: InputDecoration(
                          labelText: 'Task name',
                          prefixIcon: const Icon(Icons.work_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _hoursController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Hours',
                          prefixIcon: const Icon(Icons.access_time_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _addTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                        elevation: 4,
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 🧩 Task List Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _tasks.isEmpty
                    ? const Center(
                        key: ValueKey('empty'),
                        child: Text(
                          'No tasks logged yet.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : AnimatedList(
                        key: _listKey,
                        initialItemCount: _tasks.length,
                        itemBuilder: (context, index, animation) {
                          final task = _tasks[index];
                          return _buildTaskCard(task, animation, index);
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, Animation<double> animation,
      [int? index]) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.task, color: Colors.white),
          ),
          title: Text(
            task['task'],
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          subtitle: Text('Hours: ${task['hours']}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: index != null ? () => _deleteTask(index) : null,
          ),
        ),
      ),
    );
  }
}
