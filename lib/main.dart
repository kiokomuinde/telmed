import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart'; // Add this import
import 'package:telmed/pages/home_page.dart';
import 'firebase_options.dart'; // Add this import

void main() async {
  // Ensure widgets are ready for async operations
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase for Web
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TelmedApp());
}

class TelmedApp extends StatelessWidget {
  const TelmedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telmed | Your Doctor Online',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Modern Healthcare Palette
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D7D46), // Primary Green
          primary: const Color(0xFF2D7D46),
          secondary: const Color(0xFFF9A825), // CTA Gold
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      home: const TelmedHomePage(),
    );
  }
}