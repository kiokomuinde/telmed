import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:telmed/services/auth_service.dart';

// IMPORT COMMON WIDGETS
// Ensure this path matches where your common_widget.dart is located.
import '../widgets/common_widget.dart'; 

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  final AuthService _authService = AuthService();
  
  // Scroll logic for the floating web NavBar
  late ScrollController _scrollController;
  double _navOpacity = 0.0;

  bool _isOnline = true; // Toggle for accepting calls

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
    // Fetch doctor's name
    final User? user = _authService.currentUser;
    final String lastName = user?.displayName?.split(' ').last ?? 'Doctor';

    // Screen Size Breakpoints
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width >= 1024;
    final bool isTablet = width >= 650 && width < 1024;
    final bool isMobile = width < 650;

    return Scaffold(
      backgroundColor: const Color(0xFF1B4D2C), 
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
                      child: _buildHeader(lastName, isMobile),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Main Dashboard Body (Light Background Sheet)
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC), 
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
                                ? _buildDesktopGrid(isDesktop) 
                                : _buildMobileTabletLayout(isDesktop, isTablet, isMobile),
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

  Widget _buildDesktopGrid(bool isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT COLUMN: Main Dashboard (Stats, Next Patient, Tools)
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsRow(isDesktop: isDesktop, isTablet: false, isMobile: false),
              const SizedBox(height: 40),
              Text(
                "Next Appointment",
                style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              _buildNextPatientHero(isMobile: false),
              const SizedBox(height: 40),
              Text(
                "Quick Tools",
                style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              _buildQuickActions(isDesktop: isDesktop),
            ],
          ),
        ),
        const SizedBox(width: 32),
        // RIGHT COLUMN: Sidebar (Schedule Timeline)
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text("Today's Schedule", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)))),
                  TextButton(
                    onPressed: () {},
                    child: Text("View Calendar", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF2D7D46), fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 16),
              _buildScheduleTimeline(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTabletLayout(bool isDesktop, bool isTablet, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsRow(isDesktop: isDesktop, isTablet: isTablet, isMobile: isMobile),
        const SizedBox(height: 35),
        Text(
          "Next Appointment",
          style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 16),
        _buildNextPatientHero(isMobile: isMobile),
        const SizedBox(height: 35),
        Text(
          "Quick Tools",
          style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 16),
        _buildQuickActions(isDesktop: isDesktop),
        const SizedBox(height: 35),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text("Today's Schedule", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)))),
            TextButton(
              onPressed: () {},
              child: Text("View All", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF2D7D46), fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 16),
        _buildScheduleTimeline(),
      ],
    );
  }

  // ==========================================
  // COMPONENT BUILDERS
  // ==========================================

  Widget _buildHeader(String lastName, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Dr. $lastName",
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                softWrap: true,
              ),
              const SizedBox(height: 8),
              // Custom Online/Offline Status Toggle 
              GestureDetector(
                onTap: () => setState(() => _isOnline = !_isOnline),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isOnline ? const Color(0xFF16A34A).withOpacity(0.2) : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _isOnline ? const Color(0xFF86EFAC).withOpacity(0.5) : Colors.white30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, 
                          color: _isOnline ? const Color(0xFF86EFAC) : Colors.white54
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isOnline ? "Online & Accepting" : "Offline",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          color: _isOnline ? const Color(0xFF86EFAC) : Colors.white70
                        ),
                      )
                    ],
                  ),
                ),
              )
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
                  icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
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
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=33'), 
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

  Widget _buildStatsRow({required bool isDesktop, required bool isTablet, required bool isMobile}) {
    List<Widget> cards = [
      _buildStatCard("Appointments", "8", Icons.people_outline, const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
      _buildStatCard("Pending Rx", "3", Icons.medication_outlined, const Color(0xFFF9A825), const Color(0xFFFEFCE8)),
      _buildStatCard("Messages", "5", Icons.mail_outline, const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
    ];

    if (isDesktop || isTablet) {
      return Row(
        children: [
          Expanded(child: cards[0]), const SizedBox(width: 16),
          Expanded(child: cards[1]), const SizedBox(width: 16),
          Expanded(child: cards[2]),
        ],
      );
    } else {
      // Mobile Layout: Column of single cards
      return Column(
        children: [
          cards[0], const SizedBox(height: 16),
          cards[1], const SizedBox(height: 16),
          cards[2],
        ],
      );
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor, Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 20),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildNextPatientHero({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D7D46), Color(0xFF1B4D2C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF2D7D46).withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text("Starts in 5 mins", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
              ),
              const Icon(Icons.more_horiz, color: Colors.white),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                ),
                child: CircleAvatar(radius: isMobile ? 30 : 35, backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=47')),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Michael Scott", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: isMobile ? 22 : 26, fontWeight: FontWeight.bold), softWrap: true),
                    const SizedBox(height: 4),
                    Text("Male, 45 yrs • General Checkup", style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.85), fontSize: 15), softWrap: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Responsive CTA Layout
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF9A825), // Gold CTA
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.video_camera_front, size: 22),
                      const SizedBox(width: 10),
                      Text("Start Consultation", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    icon: const Icon(Icons.folder_shared, color: Colors.white, size: 20),
                    label: Text("View History", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {},
                  ),
                )
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9A825), // Gold CTA
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.video_camera_front, size: 22),
                        const SizedBox(width: 10),
                        Text("Start Consultation", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                  child: IconButton(
                    padding: const EdgeInsets.all(16),
                    icon: const Icon(Icons.folder_shared, color: Colors.white, size: 28),
                    tooltip: "View Patient History",
                    onPressed: () {},
                  ),
                )
              ],
            )
        ],
      ),
    );
  }

  Widget _buildQuickActions({required bool isDesktop}) {
    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: _buildActionItem(Icons.edit_note, "Write Rx", const Color(0xFF2D7D46))),
          const SizedBox(width: 16),
          Expanded(child: _buildActionItem(Icons.science_outlined, "View Labs", const Color(0xFF3B82F6))),
          const SizedBox(width: 16),
          Expanded(child: _buildActionItem(Icons.history, "History", const Color(0xFF8B5CF6))),
          const SizedBox(width: 16),
          Expanded(child: _buildActionItem(Icons.person_add_alt, "Refer", const Color(0xFFF59E0B))),
        ],
      );
    } else {
      // Grid style layout for Tablet and Mobile
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildActionItem(Icons.edit_note, "Write Rx", const Color(0xFF2D7D46))),
              const SizedBox(width: 16),
              Expanded(child: _buildActionItem(Icons.science_outlined, "View Labs", const Color(0xFF3B82F6))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildActionItem(Icons.history, "History", const Color(0xFF8B5CF6))),
              const SizedBox(width: 16),
              Expanded(child: _buildActionItem(Icons.person_add_alt, "Refer", const Color(0xFFF59E0B))),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildActionItem(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTimeline() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          _buildScheduleItem("10:00 AM", "Jane Doe", "Fever & Cough", status: "Completed"),
          _buildDivider(),
          _buildScheduleItem("10:30 AM", "Michael Scott", "General Checkup", status: "Next", isNext: true),
          _buildDivider(),
          _buildScheduleItem("11:15 AM", "Angela Martin", "Prescription Refill", status: "Waiting"),
          _buildDivider(),
          _buildScheduleItem("12:00 PM", "Lunch Break", "", isBreak: true),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String time, String name, String reason, {String? status, bool isNext = false, bool isBreak = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 75,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(time, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: isBreak ? const Color(0xFF94A3B8) : const Color(0xFF0F172A), fontSize: 13)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: isBreak
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.restaurant_menu, size: 18, color: Color(0xFF64748B)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(name, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 15), softWrap: true)),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A)), softWrap: true)),
                        if (status != null)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isNext ? const Color(0xFFFEE2E2) : (status == "Completed" ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              status,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isNext ? const Color(0xFFEF4444) : (status == "Completed" ? const Color(0xFF16A34A) : const Color(0xFF64748B)),
                              ),
                            ),
                          )
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(reason, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF64748B)), softWrap: true),
                  ],
                ),
        )
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Divider(color: Color(0xFFF1F5F9), thickness: 2),
    );
  }
}