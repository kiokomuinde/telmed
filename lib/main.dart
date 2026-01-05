import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telmed/pages/home_page.dart'; // Ensure the path matches your project name

void main() {
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