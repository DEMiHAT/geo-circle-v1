import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String selectedRole = "student"; // default role
  bool isLoading = false;

  Future<void> signup() async {
    setState(() => isLoading = true);

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    try {
      // Create user in Firebase Authentication
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = cred.user!.uid;

      // Create user record in Firestore
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "email": email,
        "role": selectedRole,
        "createdAt": Timestamp.now(),
      });

      // After successful signup → go to Login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!")),
      );

      Navigator.pushReplacementNamed(context, "/login");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Email
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 15),

            // Password
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 15),

            // Role dropdown
            DropdownButtonFormField(
              value: selectedRole,
              items: const [
                DropdownMenuItem(value: "student", child: Text("Student")),
                DropdownMenuItem(value: "faculty", child: Text("Faculty")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedRole = value!;
                });
              },
              decoration: const InputDecoration(labelText: "Select Role"),
            ),

            const SizedBox(height: 25),

            // Signup button
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: signup,
              child: const Text("Create Account"),
            )
          ],
        ),
      ),
    );
  }
}
