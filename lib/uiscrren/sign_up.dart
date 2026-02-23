import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'HomePage.dart';
import 'sign_in.dart';
import 'LocationPermissionScreen.dart'; // Make sure this file exists

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _errorMessage = "";
  bool _isLoading = false;

  bool validateEmail(String email) {
    return email.contains('@gmail.com');
  }

  bool validatePassword(String password) {
    return password.length >= 6 && password.contains(RegExp(r'[0-9]'));
  }

  bool validateMobile(String mobile) {
    return RegExp(r'^[0-9]{10}$').hasMatch(mobile);
  }

  void signUp() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String username = nameController.text.trim();
    String mobile = mobileController.text.trim();

    FocusScope.of(context).unfocus();

    if (email.isEmpty || password.isEmpty || username.isEmpty || mobile.isEmpty) {
      setState(() {
        _errorMessage = "Please enter all details!";
      });
      return;
    }

    setState(() => _isLoading = true);

    if (!validateEmail(email)) {
      setState(() {
        _errorMessage = "Email must contain '@gmail.com'!";
        _isLoading = false;
      });
      return;
    }

    if (!validatePassword(password)) {
      setState(() {
        _errorMessage = "Password must contain at least 6 characters and a number!";
        _isLoading = false;
      });
      return;
    }

    if (!validateMobile(mobile)) {
      setState(() {
        _errorMessage = "Mobile number must be exactly 10 digits!";
        _isLoading = false;
      });
      return;
    }

    try {
      // 1. Create user
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Set display name including mobile
      await userCredential.user!.updateDisplayName("$username|$mobile");
      await userCredential.user!.reload();

      User? updatedUser = FirebaseAuth.instance.currentUser;
      print("✅ Display name set to: ${updatedUser?.displayName}");

      // 3. Save login flag locally
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      // 4. Check if location is already fetched
      bool locationFetched = prefs.getBool('locationFetchedOnce') ?? false;

      setState(() => _isLoading = false);

      // 5. Navigate accordingly
      if (!locationFetched) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LocationPermissionScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        if (e.code == 'email-already-in-use') {
          _errorMessage = "This email is already registered. Please sign in.";
        } else {
          _errorMessage = "Sign Up Failed: ${e.message}";
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "An unexpected error occurred. Please try again.";
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
                "Sign Up",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: "Mobile Number",
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              SizedBox(height: 15),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              Padding(padding: EdgeInsets.only(top: 30)),
              _isLoading
                  ? CircularProgressIndicator(color: Colors.green)
                  : ElevatedButton(
                onPressed: signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text("Sign Up", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SignInScreen()),
                  );
                },
                child: Text(
                  "Already have an account? Login",
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
