import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  String statusMessage = "Scan the class QR to verify your location.";
  bool hasScanned = false;
  bool insideFence = false;
  String? lastSessionId;
  Position? lastPosition;

  // ─────────────────────────────
  // Scan QR
  // ─────────────────────────────
  Future<void> scanQR() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScanner(onScan: handleScan),
      ),
    );
  }

  // ─────────────────────────────
  // Process QR result
  // ─────────────────────────────
  Future<void> handleScan(String qrToken) async {
    // NOTE: we DO NOT pop here, QRScanner will pop itself
    try {
      // 1) Decode base64 → JSON
      final decodedBytes = base64Url.decode(qrToken);
      final jsonString = utf8.decode(decodedBytes);
      final Map<String, dynamic> token = jsonDecode(jsonString);

      final String sessionId = token["sid"];
      final int timestamp = token["ts"];

      // 2) Validate expiry (25 sec window)
      final int now = DateTime.now().millisecondsSinceEpoch;
      const int maxAgeMs = 25000;

      if (now - timestamp > maxAgeMs) {
        setState(() {
          hasScanned = false;
          insideFence = false;
          lastSessionId = null;
          statusMessage = "❌ QR expired. Please scan a fresh QR from faculty.";
        });
        return;
      }

      // 3) Fetch session from Firestore
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("sessions")
          .doc(sessionId)
          .get();

      if (!doc.exists) {
        setState(() {
          hasScanned = false;
          insideFence = false;
          lastSessionId = null;
          statusMessage = "❌ Invalid session. QR does not match any active class.";
        });
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      double fenceLat = data["geofenceLat"];
      double fenceLng = data["geofenceLng"];
      double radius = data["geofenceRadius"];

      // 4) Get student's current location
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      lastPosition = pos;

      double distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        fenceLat,
        fenceLng,
      );

      bool inside = distance <= radius;

      // 5) Update state – but DO NOT mark attendance yet
      setState(() {
        hasScanned = true;
        insideFence = inside;
        lastSessionId = sessionId;

        if (insideFence) {
          statusMessage =
          "✅ You are INSIDE the allowed area.\nTap 'Mark Attendance' to confirm.";
        } else {
          statusMessage =
          "🚫 You are OUTSIDE the allowed geofence.\nAttendance cannot be marked.";
        }
      });
    } catch (e) {
      setState(() {
        hasScanned = false;
        insideFence = false;
        lastSessionId = null;
        statusMessage = "❌ Error while processing QR: $e";
      });
    }
  }

  // ─────────────────────────────
  // Mark attendance (only shown if insideFence = true)
  // ─────────────────────────────
  Future<void> markAttendance() async {
    if (!hasScanned || !insideFence || lastSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot mark attendance. Scan a valid QR inside geofence first."),
        ),
      );
      return;
    }

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection("attendance").add({
        "sessionId": lastSessionId,
        "studentId": uid,
        "timestamp": Timestamp.now(),
        "studentLat": lastPosition?.latitude,
        "studentLng": lastPosition?.longitude,
        "insideGeofence": true,
      });

      setState(() {
        statusMessage = "🎉 Attendance successfully marked.";
      });
    } catch (e) {
      setState(() {
        statusMessage = "❌ Failed to mark attendance: $e";
      });
    }
  }

  // ─────────────────────────────
  // Logout
  // ─────────────────────────────
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Step 1: Scan the class QR",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: scanQR,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "Scan QR",
                style: TextStyle(fontSize: 18),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Status:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              statusMessage,
              style: const TextStyle(fontSize: 16),
            ),

            const Spacer(),

            // Only show Mark Attendance if a valid scan occurred and user is inside geofence
            if (hasScanned && insideFence)
              ElevatedButton.icon(
                onPressed: markAttendance,
                icon: const Icon(Icons.check_circle),
                label: const Text(
                  "Mark Attendance",
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────
// QR Scanner with scan-once logic
// ─────────────────────────────

class QRScanner extends StatefulWidget {
  final Function(String) onScan;

  const QRScanner({super.key, required this.onScan});

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR Code")),
      body: MobileScanner(
        onDetect: (capture) {
          if (_scanned) return;

          final barcode = capture.barcodes.first;
          final value = barcode.rawValue;

          if (value != null) {
            _scanned = true;
            widget.onScan(value);

            // close scanner slightly after processing
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) Navigator.pop(context);
            });
          }
        },
      ),
    );
  }
}
