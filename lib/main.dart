import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/student_home.dart';
import 'screens/faculty_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const GeoCircleApp());
}

class GeoCircleApp extends StatelessWidget {
  const GeoCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "GeoCircle Attendance",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),

      // 👇 SHOW SPLASH FIRST
      initialRoute: "/splash",

      routes: {
        "/splash": (context) => const SplashScreen(),
        "/login": (context) => const LoginScreen(),
        "/signup": (context) => const SignupScreen(),
        "/student": (context) => const StudentHomeScreen(),
        "/faculty": (context) => const FacultyHomeScreen(),
      },
    );
  }
}
