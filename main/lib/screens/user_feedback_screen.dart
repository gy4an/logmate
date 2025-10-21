import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserFeedbackScreen extends StatefulWidget {
  const UserFeedbackScreen({super.key});

  @override
  State<UserFeedbackScreen> createState() => _UserFeedbackScreenState();
}

class _UserFeedbackScreenState extends State<UserFeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();

  // Dummy feedback list — not saved anywhere permanently
  final List<Map<String, dynamic>> _feedbackList = [];

  void _submitFeedback() {
    final feedbackText = _feedbackController.text.trim();

    if (feedbackText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your feedback first.")),
      );
      return;
    }

    setState(() {
      _feedbackList.add({'feedback': feedbackText, 'date': DateTime.now()});
      _feedbackController.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("✅ Feedback submitted!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Feedback")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "We value your feedback! Please share your thoughts below.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),

            // Text field for feedback
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter your feedback here...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text("Submit Feedback"),
                onPressed: _submitFeedback,
              ),
            ),

            const SizedBox(height: 20),

            // Feedback list
            Expanded(
              child: _feedbackList.isEmpty
                  ? const Center(
                      child: Text(
                        "No feedback yet.",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _feedbackList.length,
                      itemBuilder: (context, index) {
                        final feedback = _feedbackList[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.feedback,
                              color: Colors.blueAccent,
                            ),
                            title: Text(feedback['feedback']),
                            subtitle: Text(
                              "Date: ${DateFormat('MMM d, yyyy – hh:mm a').format(feedback['date'])}",
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
}
