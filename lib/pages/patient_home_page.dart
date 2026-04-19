import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:telmed/services/auth_service.dart';

// IMPORT COMMON WIDGETS
// Ensure this path matches where your common_widget.dart is located.
import '../widgets/common_widget.dart'; 

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  final AuthService _authService = AuthService();
  
  // Scroll logic for the floating web NavBar
  late ScrollController _scrollController;
  double _navOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (mounted) {
          setState(() {
            _navOpacity = (_scrollController.offset / 400).clamp(0.0, 1.0);
          });
        }
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fetch the user's display name from Firebase Auth
    final User? user = _authService.currentUser;
    final String firstName = user?.displayName?.split(' ').first ?? 'Patient';

    // Screen Size Breakpoints
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width >= 1024;
    final bool isTablet = width >= 650 && width < 1024;
    final bool isMobile = width < 650;

    return Scaffold(
      backgroundColor: const Color(0xFF1B4D2C), // Dark Green to highlight transparent navbar
      endDrawer: const TelmedDrawer(), 
      body: Stack(
        children: [
          // 1. MAIN SCROLLABLE DASHBOARD CONTENT
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                const SizedBox(height: 100), // Spacer for navbar
                
                // Header rendered on the Dark Green background
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 20),
                      child: _buildHeader(firstName, isMobile),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Main Dashboard Body (Light Background Sheet)
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC), // Clean, clinical web background
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: isMobile ? 16 : 24, 
                              right: isMobile ? 16 : 24, 
                              top: 40, 
                              bottom: 80
                            ),
                            child: isDesktop 
                                ? _buildDesktopGrid(context, isMobile) 
                                : _buildMobileTabletLayout(context, isMobile),
                          ),
                        ),
                      ),
                      
                      // 2. THE FOOTER 
                      const TelmedFooter(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. THE FLOATING NAVBAR
          TelmedNavBar(navOpacity: _navOpacity),
        ],
      ),
    );
  }

  // ==========================================
  // LAYOUT BUILDERS
  // ==========================================

  Widget _buildDesktopGrid(BuildContext context, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT COLUMN: Main Actions & Content
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroSection(context, isMobile),
              const SizedBox(height: 40),
              _buildSectionTitle("Active Prescriptions"),
              const SizedBox(height: 16),
              _buildActivePrescriptions(isMobile: false),
            ],
          ),
        ),
        const SizedBox(width: 32),
        // RIGHT COLUMN: Sidebar (Appointments & Quick Stats)
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Upcoming Appointment"),
              const SizedBox(height: 16),
              _buildUpcomingAppointmentCard(context, isMobile),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTabletLayout(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroSection(context, isMobile),
        const SizedBox(height: 35),
        _buildSectionTitle("Upcoming Appointment"),
        const SizedBox(height: 16),
        _buildUpcomingAppointmentCard(context, isMobile),
        const SizedBox(height: 35),
        _buildSectionTitle("Active Prescriptions"),
        const SizedBox(height: 16),
        _buildActivePrescriptions(isMobile: isMobile),
      ],
    );
  }

  // ==========================================
  // COMPONENT BUILDERS
  // ==========================================

  Widget _buildHeader(String name, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Good Morning,",
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: isMobile ? 26 : 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                softWrap: true,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            if (!isMobile)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {},
                  tooltip: "Notifications",
                ),
              ),
            if (!isMobile) const SizedBox(width: 16),
            PopupMenuButton<String>(
              color: Colors.white,
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tooltip: "Account Menu",
              child: const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFFF9A825), // Gold avatar pops against green
                child: Icon(Icons.person, color: Colors.white, size: 28),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, color: Color(0xFF0F172A), size: 20),
                      const SizedBox(width: 12),
                      Text("My Profile", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      const Icon(Icons.settings_outlined, color: Color(0xFF0F172A), size: 20),
                      const SizedBox(width: 12),
                      Text("Settings", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 12),
                      Text("Sign Out", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'logout') {
                  await _authService.signOut();
                  if (mounted) Navigator.pushReplacementNamed(context, '/auth');
                }
              },
            ),
          ],
        )
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isMobile) {
    return Column(
      children: [
        // Primary CTA
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 24 : 32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2D7D46), Color(0xFF1B4D2C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: const Color(0xFF2D7D46).withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 15))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Available 24/7",
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Need medical advice?",
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.bold, height: 1.2),
                softWrap: true,
              ),
              const SizedBox(height: 12),
              Text(
                "Connect with a certified doctor in minutes via secure video call.",
                style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.85), fontSize: 16, height: 1.5),
                softWrap: true,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: isMobile ? double.infinity : null,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Route to Doctor Selection / Booking
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF9A825), // Gold CTA
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.video_call, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        "Consult a Doctor",
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Secondary Actions Grid
        if (isMobile)
          Column(
            children: [
              _buildSecondaryActionCard(
                icon: Icons.local_pharmacy_outlined,
                title: "Find Pharmacy",
                subtitle: "Order medications",
                color: const Color(0xFF3B82F6), // Accent Blue
                onTap: () {},
              ),
              const SizedBox(height: 16),
              _buildSecondaryActionCard(
                icon: Icons.description_outlined,
                title: "Medical Records",
                subtitle: "View history & tests",
                color: const Color(0xFF8B5CF6), // Accent Purple
                onTap: () {},
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _buildSecondaryActionCard(
                  icon: Icons.local_pharmacy_outlined,
                  title: "Find Pharmacy",
                  subtitle: "Order medications",
                  color: const Color(0xFF3B82F6), 
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildSecondaryActionCard(
                  icon: Icons.description_outlined,
                  title: "Medical Records",
                  subtitle: "View history & tests",
                  color: const Color(0xFF8B5CF6), 
                  onTap: () {},
                ),
              ),
            ],
          )
      ],
    );
  }

  Widget _buildSecondaryActionCard({
    required IconData icon, 
    required String title, 
    required String subtitle,
    required Color color, 
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A)),
                    softWrap: true,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B)),
                    softWrap: true,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            softWrap: true,
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2D7D46),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("See All", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, size: 16),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildUpcomingAppointmentCard(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 25, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: isMobile ? 24 : 30,
                backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=32'), 
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dr. Sarah Jenkins", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF0F172A)), softWrap: true),
                    const SizedBox(height: 4),
                    Text("General Physician", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 14), softWrap: true),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
              )
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Color(0xFFF1F5F9), thickness: 2),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Color(0xFF2D7D46)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text("Today, 10:30 AM", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), fontSize: 15)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Connect to your Signaling WebRTC file and push to the Call screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D7D46),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text("Join Call", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActivePrescriptions({required bool isMobile}) {
    return Column(
      children: [
        _buildPrescriptionItem(
          medication: "Amoxicillin 500mg",
          doctor: "Dr. Sarah Jenkins",
          status: "Active",
          isUrgent: false,
          isMobile: isMobile,
        ),
        const SizedBox(height: 16),
        _buildPrescriptionItem(
          medication: "Lisinopril 10mg",
          doctor: "Dr. Marcus Thorne",
          status: "Pending Pharmacy",
          isUrgent: true,
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _buildPrescriptionItem({
    required String medication, 
    required String doctor, 
    required String status, 
    required bool isUrgent,
    required bool isMobile
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: isMobile
          // Mobile layout stacks details to prevent cramping
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.medication_outlined, color: Color(0xFF64748B), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(medication, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A)), softWrap: true),
                          const SizedBox(height: 4),
                          Text("Prescribed by $doctor", style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B)), softWrap: true),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {},
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Send to Pharmacy",
                            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF2D7D46), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF2D7D46)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isUrgent ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isUrgent ? const Color(0xFFEA580C) : const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            )
          // Desktop & Tablet layout (Side-by-side)
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.medication_outlined, color: Color(0xFF64748B), size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(medication, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A)), softWrap: true),
                      const SizedBox(height: 6),
                      Text("Prescribed by $doctor", style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B)), softWrap: true),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isUrgent ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isUrgent ? const Color(0xFFEA580C) : const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {},
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Send to Pharmacy",
                            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF2D7D46), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF2D7D46)),
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
    );
  }
}