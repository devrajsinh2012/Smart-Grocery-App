import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AdminSignup.dart';
import 'sign_up.dart';
import 'HomePage.dart';
import 'resetpassword.dart';

void SignInScrren(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isLoggedIn', true); // Save login state

  // Navigate to HomeScreen
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => HomePage()),
  );
}

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _errorMessage = "";
  bool _isLoading = false; // Loading indicator

  void signIn() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    // Hide the keyboard
    FocusScope.of(context).unfocus();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please enter email and password!");
      return;
    }

    setState(() => _isLoading = true); // Show loading

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // If successful, save login state and navigate to HomeScreen
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false; // Hide loading
        _errorMessage = "Login failed! Please try again.";

        if (e.code == 'user-not-found') {
          setState(() => _errorMessage = "Wrong email! No user found.");
          return;
        }

        if (e.code == 'invalid-credential') {
          setState(() => _errorMessage = "Wrong email or password.");
          return;
        }

        if (e.code == 'invalid-email') {
          setState(() => _errorMessage = "Invalid email format!");
          return;
        }

        if (e.code == 'user-disabled') {
          setState(() => _errorMessage = "This account has been disabled!");
          return;
        }

        if (e.code == 'too-many-requests') {
          setState(() => _errorMessage = "Too many attempts! Try again later.");
          return;
        }

        setState(() => _errorMessage = "Login failed: ${e.message}");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade100,
      body: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          width: 350,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 1),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Login",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              Padding(padding: EdgeInsets.only(top: 10)),

              // Display error message
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),

              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Resetpassword()),
                    );
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 15),

              // Login Button with loading
              _isLoading
                  ? CircularProgressIndicator(color: Colors.green)
                  : ElevatedButton(
                onPressed: signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text("Login", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),

              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpScreen()),
                  );
                },
                child: Text(
                  "Don't have an account? Sign Up",
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),

              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminSignup()),
                  );
                },
                child: Text(
                  "Sign up as Admin",
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
