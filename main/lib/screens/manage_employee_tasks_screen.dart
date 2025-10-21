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

    await Future.delayed(const Duration(milliseconds: 300)); // smoother intro

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
          // 🌈 Animated Gradient Background
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

          // 🌫️ Frosted Glass Overlay
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
            ),
          ),

          // 💻 Main Content
          SafeArea(
            child: Column(
              children: [
                // 🔍 Search Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Colors.white.withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search employee...",
                        hintStyle:
                            const TextStyle(color: Colors.white70, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Colors.white),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 15),
                      ),
                    ),
                  ),
                ),

                // 🧍 Employee List

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

                              final animation = Tween<Offset>(
                                begin: const Offset(0, 0.25),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _animationController,
                                curve: Interval(index * 0.08, 1.0, curve: Curves.easeOutCubic),
                              ));

                              final fadeAnim = CurvedAnimation(
                                parent: _animationController,
                                curve: Interval(index * 0.08, 1.0, curve: Curves.easeIn),
                              );

                              return SlideTransition(
                                position: animation,
                                child: FadeTransition(
                                  opacity: fadeAnim,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (isAdmin) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                          content: Text("Admins don’t have task logs."),
                                        ));
                                      } else {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            transitionDuration: const Duration(milliseconds: 600),
                                            pageBuilder: (_, __, ___) =>
                                                EmployeeTaskListScreen(
                                                    username: account['username']),
                                            transitionsBuilder: (_, animation, __, child) {
                                              return SlideTransition(
                                                position: Tween<Offset>(
                                                  begin: const Offset(0, 0.2),
                                                  end: Offset.zero,
                                                ).animate(CurvedAnimation(
                                                    parent: animation,
                                                    curve: Curves.easeOutCubic)),
                                                child: FadeTransition(
                                                  opacity: animation,
                                                  child: child,
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      }
                                    },
                                    child: AnimatedScale(
                                      scale: 1.0,
                                      duration: const Duration(milliseconds: 200),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(vertical: 8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(18),
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.2),
                                              Colors.white.withOpacity(0.05),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          border: Border.all(
                                            width: 1.2,
                                            color: Colors.white.withOpacity(0.2),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.25),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(18),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                            child: InkWell(
                                              splashColor: Colors.white.withOpacity(0.15),
                                              highlightColor: Colors.white.withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(18),
                                              child: ListTile(
                                                leading: Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: (isAdmin
                                                                ? Colors.redAccent
                                                                : Colors.blueAccent)
                                                            .withOpacity(0.5),
                                                        blurRadius: 10,
                                                        spreadRadius: 1,
                                                      ),
                                                    ],
                                                  ),
                                                  child: CircleAvatar(
                                                    radius: 24,
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
                                                ),
                                                title: Text(
                                                  account['username'],
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  'Role: ${account['role']}',
                                                  style: const TextStyle(
                                                      color: Colors.white70, fontSize: 13),
                                                ),
                                                trailing: const Icon(
                                                  Icons.arrow_forward_ios_rounded,
                                                  color: Colors.white70,
                                                  size: 18,
                                                ),
                                              ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
