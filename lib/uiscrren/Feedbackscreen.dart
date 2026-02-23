import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Feedbackscreen extends StatefulWidget {
  const Feedbackscreen({super.key});

  @override
  State<Feedbackscreen> createState() => _FeedbackscreenState();
}

class _FeedbackscreenState extends State<Feedbackscreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String name = '';

  User? currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  // Fetch the username from Firebase Auth
  void _fetchUsername() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        if (user.displayName != null) {
          final parts = user.displayName!.split('|');
          if (parts.length == 2) {
            name = parts[0];
          } else {
            name = user.displayName!;
          }
        }
      });
    }
  }

  // Function to submit feedback
  void _submitFeedback() async {
    String feedbackText = _feedbackController.text.trim();

    if (feedbackText.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('feedbacks').add({
          'username': name,
          'feedback': feedbackText,
          'timestamp': FieldValue.serverTimestamp(), // Store timestamp for ordering
        });
        _feedbackController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting feedback: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter feedback')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade100,
      appBar: AppBar(
        title: Text("Feedback Screen"),
        backgroundColor: Colors.green, // Removed green background
        elevation: 0,
        titleTextStyle: TextStyle(color: Colors.white,fontSize: 20),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('feedbacks')
                  .orderBy('timestamp') // Order by latest first
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: Text('No feedback available.'));
                }

                var feedbacks = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: feedbacks.length,
                  itemBuilder: (context, index) {
                    var feedback = feedbacks[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.feedback, color: Colors.black), // Feedback icon
                            SizedBox(width: 10), // Space between icon and text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    feedback['username'],
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    feedback['feedback'],
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _feedbackController,
              maxLines: null, // Allows the text box to grow as the user types
              decoration: InputDecoration(
                labelText: 'Enter your feedback...',
                border: OutlineInputBorder(),
                hintText: 'Write something...',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: SizedBox(
              child: ElevatedButton(
                onPressed: _submitFeedback,
                child: Text("Submit Feedback", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Removed green
                  elevation: 3,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  minimumSize: Size(150, 40)// Increase button height
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
