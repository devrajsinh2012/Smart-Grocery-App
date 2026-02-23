import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Profilescreen extends StatefulWidget {
  const Profilescreen({super.key});

  @override
  State<Profilescreen> createState() => _ProfilescreenState();

  void onProfileUpdated() {}
}

class _ProfilescreenState extends State<Profilescreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  String _email = "Loading...";
  bool _isSaving = false;
  String _errorMessage = "";

  User? currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  // Fetch user details from Firebase Auth
  void _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _email = user.email ?? "No email found";

        // Extract only the name part from displayName
        if (user.displayName != null) {
          final parts = user.displayName!.split('|');
          if (parts.length == 2) {
            _nameController.text = parts[0];
          } else {
            _nameController.text = user.displayName!;
          }
        }
      });
    }
  }

  // Update name in Firebase Auth
  Future<void> _updateName() async {
    setState(() {
      _isSaving = true;
      _errorMessage = "";
    });

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        String existingMobile = '';
        if (user.displayName != null && user.displayName!.contains('|')) {
          existingMobile = user.displayName!.split('|').last;
        }

        // Save updated name + existing mobile number
        await user.updateDisplayName('${_nameController.text}|$existingMobile');
        await user.reload(); // Reload user data

        setState(() {
          _errorMessage = "Profile updated successfully!";
        });

        widget.onProfileUpdated();
        Navigator.pop(context, true);
      } catch (e) {
        setState(() {
          _errorMessage = "Error updating profile: $e";
        });
      }
    }

    setState(() {
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = currentUser?.email ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.green,
        elevation: 0,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Name", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter your name",
              ),
            ),
            const SizedBox(height: 20),
            const Text("Email", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              controller: TextEditingController(text: email),
              enabled: false,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(
                  color: _errorMessage.contains("success") ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 30),
            _isSaving
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : ElevatedButton(
              onPressed: _updateName,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.green.shade100,
    );
  }
}
