import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';

class FacultyHomeScreen extends StatefulWidget {
  const FacultyHomeScreen({super.key});

  @override
  State<FacultyHomeScreen> createState() => _FacultyHomeScreenState();
}

class _FacultyHomeScreenState extends State<FacultyHomeScreen> {
  double geofenceRadius = 30;
  bool isLoading = false;

  Future<void> createSession() async {
    setState(() => isLoading = true);

    try {
      // 1. Get faculty location
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // 2. Create Firestore document
      DocumentReference ref =
      FirebaseFirestore.instance.collection("sessions").doc();

      await ref.set({
        "sessionId": ref.id,
        "facultyId": FirebaseAuth.instance.currentUser!.uid,
        "geofenceLat": pos.latitude,
        "geofenceLng": pos.longitude,
        "geofenceRadius": geofenceRadius,
        "createdAt": Timestamp.now(),
      });

      // 3. Navigate to QR Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FacultyQRScreen(sessionId: ref.id),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating session: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Faculty Dashboard"),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Generate Attendance QR",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Text(
              "Geofence Radius: ${geofenceRadius.toInt()} meters",
              style: const TextStyle(fontSize: 16),
            ),

            Slider(
              value: geofenceRadius,
              min: 10,
              max: 100,
              divisions: 9,
              label: geofenceRadius.toInt().toString(),
              onChanged: (value) {
                setState(() {
                  geofenceRadius = value;
                });
              },
            ),

            const SizedBox(height: 25),

            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Center(
              child: ElevatedButton(
                onPressed: createSession,
                child: const Text(
                  "Generate QR",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
//                           DYNAMIC QR SCREEN
// ----------------------------------------------------------------------

class FacultyQRScreen extends StatefulWidget {
  final String sessionId;
  const FacultyQRScreen({super.key, required this.sessionId});

  @override
  State<FacultyQRScreen> createState() => _FacultyQRScreenState();
}

class _FacultyQRScreenState extends State<FacultyQRScreen> {
  String _qrData = "";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _generateToken();

    // Auto-refresh QR every 10 seconds
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _generateToken();
    });
  }

  void _generateToken() {
    final now = DateTime.now().millisecondsSinceEpoch;

    // QR payload structure
    final payload = {
      "sid": widget.sessionId,
      "ts": now,
    };

    final jsonString = jsonEncode(payload);
    final encoded = base64UrlEncode(utf8.encode(jsonString)); // ENCODED QR

    setState(() {
      _qrData = encoded;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dynamic Attendance QR")),
      body: Center(
        child: _qrData.isEmpty
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(
              data: _qrData,
              version: QrVersions.auto,
              size: 280,
            ),
            const SizedBox(height: 20),
            const Text(
              "This QR refreshes every 10 seconds",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            )
          ],
        ),
      ),
    );
  }
}
