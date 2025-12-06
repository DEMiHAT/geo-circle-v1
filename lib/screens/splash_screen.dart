import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    startCheck();
  }

  Future<void> startCheck() async {
    await Future.delayed(const Duration(seconds: 2)); // splash duration

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Not logged in → login screen
      Navigator.pushReplacementNamed(context, "/login");
      return;
    }

    // logged in → fetch role
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (!doc.exists || !doc.data()!.containsKey("role")) {
      Navigator.pushReplacementNamed(context, "/login");
      return;
    }

    final role = doc["role"];

    if (role == "faculty") {
      Navigator.pushReplacementNamed(context, "/facultyHome");
    } else if (role == "student") {
      Navigator.pushReplacementNamed(context, "/studentHome");
    } else if (role == "admin") {
      Navigator.pushReplacementNamed(context, "/adminHome");
    } else {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, size: 90, color: Colors.blueAccent),
            const SizedBox(height: 15),
            const Text("GeoCircle",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text("Smart Geofence Attendance",
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
