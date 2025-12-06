import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  Future<void> login() async {
    try {
      UserCredential usercred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
          email: _email.text.trim(), password: _password.text.trim());

      // Fetch role
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(usercred.user!.uid)
          .get();

      String role = userDoc['role'];

      if (role == "faculty") {
        Navigator.pushReplacementNamed(context, "/faculty");
      } else {
        Navigator.pushReplacementNamed(context, "/student");
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: _password, decoration: const InputDecoration(labelText: "Password"), obscureText: true),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: login,
              child: const Text("Login"),
            ),

            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, "/signup");
              },
              child: const Text("Create account"),
            )
          ],
        ),
      ),
    );
  }
}
