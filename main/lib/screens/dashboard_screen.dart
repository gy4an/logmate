import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  final String role;

  const DashboardScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard (${role.toUpperCase()})'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Log Tasks & Hours'),
            onTap: () {
              // You can route to another screen later
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon: Log Tasks')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Submit Feedback'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon: Feedback')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Sign Document'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon: Signature')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics & Reports'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon: Analytics')),
              );
            },
          ),
          if (role == 'admin')
            ListTile(
              leading: const Icon(Icons.supervised_user_circle),
              title: const Text('Supervisor Dashboard'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon: Supervisor View')),
                );
              },
            ),
        ],
      ),
    );
  }
}
