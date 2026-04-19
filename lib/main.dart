import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:telmed/pages/home_page.dart';
import 'package:telmed/pages/auth_page.dart'; 
import 'package:telmed/pages/patient_home_page.dart';
import 'package:telmed/pages/doctor_home_page.dart';     
import 'package:telmed/pages/pharmacy_home_page.dart';   
import 'package:telmed/pages/telmed_ai_chat_page.dart'; // NEW: Imported AI Chat Page
import 'firebase_options.dart'; 

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
      // --- DEFINED ROUTES HERE ---
      routes: {
        '/auth': (context) => const AuthPage(), 
        '/home': (context) => const PatientHomePage(), 
        '/doctor_home': (context) => const DoctorHomePage(),     
        '/pharmacy_home': (context) => const PharmacyHomePage(), 
        '/ai_chat': (context) => const TelmedAiChatPage(),      // NEW: AI Chat Route
      },
    );
  }
}