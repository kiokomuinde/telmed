import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:telmed/services/auth_service.dart';

// IMPORT COMMON WIDGETS
// Ensure this path matches where your common_widget.dart is located.
import '../widgets/common_widget.dart'; 

class PharmacyHomePage extends StatefulWidget {
  const PharmacyHomePage({super.key});

  @override
  State<PharmacyHomePage> createState() => _PharmacyHomePageState();
}

class _PharmacyHomePageState extends State<PharmacyHomePage> {
  final AuthService _authService = AuthService();
  
  // Scroll logic for the floating web NavBar
  late ScrollController _scrollController;
  double _navOpacity = 0.0;

  bool _isAcceptingOrders = true; // Toggle for store status

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
    // Fetch pharmacy name
    final User? user = _authService.currentUser;
    final String pharmacyName = user?.displayName ?? 'Pharmacy Portal';

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
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 20),
                      child: _buildHeader(pharmacyName, isMobile),
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
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: isMobile ? 16 : 24, 
                              right: isMobile ? 16 : 24, 
                              top: 40, 
                              bottom: 80
                            ),
                            child: isDesktop 
                                ? _buildDesktopGrid() 
                                : _buildMobileTabletLayout(isTablet, isMobile),
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

  Widget _buildDesktopGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsRow(isDesktop: true, isTablet: false, isMobile: false),
        const SizedBox(height: 40),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT COLUMN: Pending Prescriptions & Fulfillment
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Action Required: Pending e-Rx"),
                  const SizedBox(height: 16),
                  _buildPendingOrders(),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // RIGHT COLUMN: Quick Tools & Inventory Alerts
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Quick Tools"),
                  const SizedBox(height: 16),
                  _buildQuickTools(),
                  const SizedBox(height: 40),
                  _buildSectionTitle("Inventory Alerts"),
                  const SizedBox(height: 16),
                  _buildInventoryAlerts(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileTabletLayout(bool isTablet, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsRow(isDesktop: false, isTablet: isTablet, isMobile: isMobile),
        const SizedBox(height: 35),
        _buildSectionTitle("Quick Tools"),
        const SizedBox(height: 16),
        _buildQuickTools(isMobile: isMobile),
        const SizedBox(height: 35),
        _buildSectionTitle("Action Required: Pending e-Rx"),
        const SizedBox(height: 16),
        _buildPendingOrders(isMobile: isMobile),
        const SizedBox(height: 35),
        _buildSectionTitle("Inventory Alerts"),
        const SizedBox(height: 16),
        _buildInventoryAlerts(),
      ],
    );
  }

  // ==========================================
  // COMPONENT BUILDERS
  // ==========================================

  Widget _buildHeader(String pharmacyName, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pharmacyName,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white, 
                  fontSize: isMobile ? 24 : 32, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: -0.5
                ),
                softWrap: true,
              ),
              const SizedBox(height: 8),
              // Custom Online/Offline Status Toggle
              GestureDetector(
                onTap: () => setState(() => _isAcceptingOrders = !_isAcceptingOrders),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isAcceptingOrders ? const Color(0xFF16A34A).withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _isAcceptingOrders ? const Color(0xFF86EFAC).withOpacity(0.5) : Colors.redAccent.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, 
                          color: _isAcceptingOrders ? const Color(0xFF86EFAC) : Colors.redAccent
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isAcceptingOrders ? "Accepting Orders" : "Store Closed",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          color: _isAcceptingOrders ? const Color(0xFF86EFAC) : Colors.redAccent
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
                  tooltip: "Alerts",
                ),
              ),
            if (!isMobile) const SizedBox(width: 16),
            PopupMenuButton<String>(
              color: Colors.white,
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tooltip: "Pharmacy Menu",
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9A825), // Gold accent
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront, color: Colors.white, size: 24),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.business, color: Color(0xFF0F172A), size: 20),
                      const SizedBox(width: 12),
                      Text("Store Profile", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
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
    final List<Widget> cards = [
      _buildStatCard("New Orders", "12", Icons.shopping_bag_outlined, const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
      _buildStatCard("Ready for Pickup", "5", Icons.check_circle_outline, const Color(0xFF10B981), const Color(0xFFECFDF5)),
      _buildStatCard("Low Stock", "8", Icons.warning_amber_rounded, const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
      _buildStatCard("Today's Revenue", "KSh 42k", Icons.payments_outlined, const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
    ];

    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: cards[0]), const SizedBox(width: 16),
          Expanded(child: cards[1]), const SizedBox(width: 16),
          Expanded(child: cards[2]), const SizedBox(width: 16),
          Expanded(child: cards[3]),
        ],
      );
    } else if (isTablet) {
      return Column(
        children: [
          Row(children: [Expanded(child: cards[0]), const SizedBox(width: 16), Expanded(child: cards[1])]),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: cards[2]), const SizedBox(width: 16), Expanded(child: cards[3])]),
        ],
      );
    } else {
      // Mobile Layout: Column of single cards to ensure text doesn't squeeze
      return Column(
        children: [
          cards[0], const SizedBox(height: 16),
          cards[1], const SizedBox(height: 16),
          cards[2], const SizedBox(height: 16),
          cards[3],
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
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
        ],
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
              Text("View All", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, size: 16),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildPendingOrders({bool isMobile = false}) {
    return Column(
      children: [
        _buildOrderCard(
          patientName: "Michael Scott",
          doctorName: "Dr. Sarah Jenkins",
          timePassed: "10 mins ago",
          medications: ["Amoxicillin 500mg (1x Daily)", "Ibuprofen 200mg (As needed)"],
          isUrgent: true,
          isMobile: isMobile,
        ),
        const SizedBox(height: 16),
        _buildOrderCard(
          patientName: "Angela Martin",
          doctorName: "Dr. Marcus Thorne",
          timePassed: "45 mins ago",
          medications: ["Lisinopril 10mg (1x Daily)"],
          isUrgent: false,
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _buildOrderCard({required String patientName, required String doctorName, required String timePassed, required List<String> medications, required bool isUrgent, required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isUrgent ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0), width: isUrgent ? 2 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFF1F5F9),
                child: Text(patientName[0], style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patientName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A)), softWrap: true),
                    const SizedBox(height: 2),
                    Text("Rx via $doctorName", style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B)), softWrap: true),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
                      child: Text("URGENT", style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444))),
                    ),
                  Text(timePassed, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                ],
              )
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFF1F5F9)),
          ),
          ...medications.map((med) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.medication, size: 16, color: Color(0xFF2D7D46)),
                const SizedBox(width: 8),
                Expanded(child: Text(med, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF334155)), softWrap: true)),
              ],
            ),
          )),
          const SizedBox(height: 20),
          // Responsive Buttons: Stack on very small screens, Row on larger
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D7D46),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Fulfill Order", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("View Details", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("View Details", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D7D46),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Fulfill Order", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildQuickTools({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildActionItem(Icons.qr_code_scanner, "Verify e-Rx", const Color(0xFF2D7D46))),
              const SizedBox(width: 12),
              Expanded(child: _buildActionItem(Icons.inventory_2_outlined, "Add Stock", const Color(0xFF3B82F6))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildActionItem(Icons.local_shipping_outlined, "Dispatch", const Color(0xFFF59E0B))),
              const SizedBox(width: 12),
              Expanded(child: _buildActionItem(Icons.analytics_outlined, "Reports", const Color(0xFF8B5CF6))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryAlerts() {
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
          _buildAlertItem("Paracetamol 500mg", "Only 12 strips left", true),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Color(0xFFF1F5F9))),
          _buildAlertItem("Cough Syrup (100ml)", "Only 5 bottles left", true),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Color(0xFFF1F5F9))),
          _buildAlertItem("Vitamin C Zinc", "Expiring in 30 days", false),
        ],
      ),
    );
  }

  Widget _buildAlertItem(String item, String reason, bool isStock) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isStock ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isStock ? Icons.trending_down : Icons.event_busy, 
            color: isStock ? const Color(0xFFEF4444) : const Color(0xFFF59E0B), 
            size: 20
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A)), softWrap: true),
              const SizedBox(height: 2),
              Text(reason, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B)), softWrap: true),
            ],
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
          child: Text("Order", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF2D7D46), fontWeight: FontWeight.bold, fontSize: 13)),
        )
      ],
    );
  }
}