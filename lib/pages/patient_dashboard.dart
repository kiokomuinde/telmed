import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:telmed/services/auth_service.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Fetch the user's display name from Firebase Auth
    final User? user = _authService.currentUser;
    final String firstName = user?.displayName?.split(' ').first ?? 'Patient';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Clean, clinical background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850), // Cap width for desktop viewing
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(firstName),
                  const SizedBox(height: 30),
                  _buildHeroSection(context),
                  const SizedBox(height: 35),
                  _buildSectionTitle("Upcoming Appointment"),
                  const SizedBox(height: 16),
                  _buildUpcomingAppointmentCard(context),
                  const SizedBox(height: 35),
                  _buildSectionTitle("Active Prescriptions"),
                  const SizedBox(height: 16),
                  _buildActivePrescriptions(),
                  const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ==========================================
  // WIDGET BUILDERS
  // ==========================================

  Widget _buildHeader(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Good Morning,",
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF0F172A),
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Color(0xFF0F172A)),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () async {
                // Logout logic for testing purposes
                await _authService.signOut();
                if (mounted) Navigator.pushReplacementNamed(context, '/auth');
              },
              child: const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFF2D7D46),
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Column(
      children: [
        // Primary CTA
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2D7D46), Color(0xFF1B4D2C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D7D46).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Available 24/7",
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Need medical advice?",
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Connect with a certified doctor in minutes via secure video call.",
                style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // TODO: Route to Doctor Selection / Booking
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9A825), // Gold CTA
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.video_call, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Consult a Doctor Now",
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Secondary Actions
        Row(
          children: [
            Expanded(
              child: _buildSecondaryActionCard(
                icon: Icons.local_pharmacy,
                title: "Find Pharmacy",
                color: const Color(0xFF3B82F6), // Accent Blue
                onTap: () {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSecondaryActionCard(
                icon: Icons.description,
                title: "Medical Records",
                color: const Color(0xFF8B5CF6), // Accent Purple
                onTap: () {},
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSecondaryActionCard({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            "See All",
            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF2D7D46), fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }

  Widget _buildUpcomingAppointmentCard(BuildContext context) {
    // Note: In production, wrap this in a StreamBuilder listening to Firestore
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=32'), // Placeholder doctor image
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dr. Sarah Jenkins", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A))),
                    Text("General Physician", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 14)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
              )
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFF1F5F9), thickness: 2),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text("Today, 10:30 AM", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A), fontSize: 14)),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Connect to your Signaling WebRTC file and push to the Call screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D7D46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text("Join Call", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActivePrescriptions() {
    // Note: In production, map this from your prescription_service.dart stream
    return Column(
      children: [
        _buildPrescriptionItem(
          medication: "Amoxicillin 500mg",
          doctor: "Dr. Sarah Jenkins",
          status: "Active",
          isUrgent: false,
        ),
        const SizedBox(height: 12),
        _buildPrescriptionItem(
          medication: "Lisinopril 10mg",
          doctor: "Dr. Marcus Thorne",
          status: "Pending Pharmacy",
          isUrgent: true,
        ),
      ],
    );
  }

  Widget _buildPrescriptionItem({required String medication, required String doctor, required String status, required bool isUrgent}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.medication, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medication, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text("Prescribed by $doctor", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isUrgent ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isUrgent ? const Color(0xFFEA580C) : const Color(0xFF16A34A),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Send to Pharmacy",
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF2D7D46), fontSize: 12, fontWeight: FontWeight.bold),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2D7D46),
          unselectedItemColor: const Color(0xFF94A3B8),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Bookings"),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Records"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
          ],
        ),
      ),
    );
  }
}