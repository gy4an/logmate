import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FeedbackDetailScreen extends StatefulWidget {
  final String username;
  const FeedbackDetailScreen({super.key, required this.username});

  @override
  State<FeedbackDetailScreen> createState() => _FeedbackDetailScreenState();
}

class _FeedbackDetailScreenState extends State<FeedbackDetailScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  List<String> feedbackList = [];

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(widget.username);
    if (data != null) {
      setState(() {
        feedbackList = List<String>.from(jsonDecode(data));
      });
    }
  }

  Future<void> _saveFeedback() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      feedbackList.add(text);
      _feedbackController.clear();
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(widget.username, jsonEncode(feedbackList));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback added successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1621),
      appBar: AppBar(
        title: Text('Feedback: ${widget.username}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: feedbackList.isEmpty
                ? const Center(
                    child: Text(
                      'No feedback yet.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: feedbackList.length,
                    itemBuilder: (context, index) {
                      final feedback = feedbackList[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Card(
                          elevation: 8,
                          color: Colors.white.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                              child: ListTile(
                                title: Text(
                                  feedback,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _feedbackController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Enter feedback...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.orangeAccent),
                    onPressed: _saveFeedback,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
