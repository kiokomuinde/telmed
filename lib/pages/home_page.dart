import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/common_widget.dart';
import '../services/mpesa_service.dart';
import '../widgets/call_overlay.dart'; 

/// ----------------------------------------------------------------------
/// MAIN HOME PAGE WIDGET
/// ----------------------------------------------------------------------
class TelmedHomePage extends StatefulWidget {
  const TelmedHomePage({super.key});

  @override
  State<TelmedHomePage> createState() => _TelmedHomePageState();
}

class _TelmedHomePageState extends State<TelmedHomePage>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _heroTextController;
  late Animation<double> _heroOpacity;
  late Animation<Offset> _heroSlide;

  double _navOpacity = 0.0;

  final MpesaService _mpesaService = MpesaService();
  final TextEditingController _phoneController = TextEditingController();

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

    _heroTextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _heroOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _heroTextController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _heroTextController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutQuart),
      ),
    );

    _heroTextController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _heroTextController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// ----------------------------------------------------------------------
  /// M-PESA & CALL OVERLAY LOGIC
  /// ----------------------------------------------------------------------
  Future<void> _handleCallNowClick() async {
    _phoneController.clear(); // Clear any previous input

    final String? phoneNumber = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Text(
            "Book Consultation",
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D7D46),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter your Safaricom M-Pesa number to process the KSH 54 consultation fee.",
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 20.0),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 9, // Restricts user to exactly 9 digits
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  hintText: "712345678",
                  prefixText: "+254 ", // Hardcoded UI prefix
                  prefixStyle: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                  prefixIcon: const Icon(
                    Icons.phone_android,
                    color: Color(0xFF2D7D46),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(
                      color: Color(0xFF2D7D46),
                      width: 2.0,
                    ),
                  ),
                  counterText: "", // Hides the '0/9' character counter
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D7D46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onPressed: () {
                Navigator.pop(context, _phoneController.text.trim());
              },
              child: const Text(
                "Pay & Connect",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (phoneNumber == null || phoneNumber.isEmpty) {
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFF9A825),
            ),
          );
        },
      );
    }

    final String? checkoutRequestId = await _mpesaService.initiatePayment(
      phoneNumber: phoneNumber,
      amount: 54, 
    );

    if (checkoutRequestId == null) {
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              "Failed to initiate M-Pesa connection. Please try again.",
            ),
          ),
        );
      }
      return;
    }

    _mpesaService
        .listenToPaymentStatus(checkoutRequestId)
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>?;
        final String? status = data?['status'];

        if (status == 'completed') {
          if (mounted) {
            Navigator.pop(context); 
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFF2D7D46),
                content: Text(
                  "Payment Verified! Initializing secure medical line...",
                ),
              ),
            );
            
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CallOverlay()),
            );
          }
        } else if (status == 'failed') {
          if (mounted) {
            Navigator.pop(context); 
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.redAccent,
                content: Text(
                  "Transaction failed or was cancelled by the user.",
                ),
              ),
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: const TelmedDrawer(), 
      body: Stack(
        children: [
          _buildMainScrollArea(),
          TelmedNavBar(navOpacity: _navOpacity), 
        ],
      ),
    );
  }

  Widget _buildMainScrollArea() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          _HeroSection(
            heroOpacity: _heroOpacity,
            heroSlide: _heroSlide,
            onCallTap: _handleCallNowClick,
          ),
          const _TrustPulseBar(),
          const _TelemedicineShowcase(),
          const _HomecareImmersiveSection(),
          const _HybridCarePhilosophy(),
          const _ModernStepProcess(),
          const _ElitePricingModule(),
          const _TestimonialWall(),
          const _FaqSection(),
          const TelmedFooter(), 
        ],
      ),
    );
  }
}

/// ----------------------------------------------------------------------
/// SECTION 1: HERO
/// ----------------------------------------------------------------------
class _HeroSection extends StatelessWidget {
  final Animation<double> heroOpacity;
  final Animation<Offset> heroSlide;
  final VoidCallback onCallTap;

  const _HeroSection({
    required this.heroOpacity,
    required this.heroSlide,
    required this.onCallTap,
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 900;

    return Container(
      width: double.infinity,
      height: isMobile ? null : size.height * 0.95,
      padding: isMobile
          ? const EdgeInsets.only(top: 100.0, bottom: 80.0)
          : null,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D7D46),
            Color(0xFF1B4D2C),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _HeroAestheticPainter(),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20.0 : 100.0,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SlideTransition(
                    position: heroSlide,
                    child: FadeTransition(
                      opacity: heroOpacity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _HeroBadge(
                            text: "✨ DOCTOR ON CALL 24/7",
                          ),
                          const SizedBox(height: 30.0),
                          Text(
                            "The Doctor is\nJust a Phone\nCall Away.",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isMobile ? 48.0 : 72.0,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -2.0,
                            ),
                          ),
                          const SizedBox(height: 30.0),
                          Text(
                            "Speak directly to a licensed doctor for only KSH 54 per call. No waiting rooms, no travel—just professional care.",
                            style: TextStyle(
                              fontSize: isMobile ? 18.0 : 20.0,
                              color: Colors.white.withOpacity(0.8),
                              height: 1.6,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 50.0),
                          const TypewriterPrompt(
                            baseColor: Colors.white,
                            accentColor: Color(0xFFF9A825),
                          ),
                          const SizedBox(height: 20.0),
                          if (isMobile) ...[
                            ActionBtn(
                              label: "Call Telmed (KSH 54)",
                              iconData: Icons.phone_forwarded_rounded,
                              color: const Color(0xFFF9A825),
                              primary: true,
                              onTap: onCallTap,
                            ),
                            const SizedBox(height: 20.0),
                            ActionBtn(
                              label: "Ask Telmed AI",
                              iconData: Icons.smart_toy_outlined,
                              color: Colors.white,
                              primary: false,
                              onTap: () {
                                Navigator.pushNamed(context, '/ai_chat');
                              },
                            ),
                          ] else
                            Row(
                              children: [
                                ActionBtn(
                                  label: "Call Telmed (KSH 54)",
                                  iconData: Icons.phone_forwarded_rounded,
                                  color: const Color(0xFFF9A825),
                                  primary: true,
                                  onTap: onCallTap,
                                ),
                                const SizedBox(width: 25.0),
                                ActionBtn(
                                  label: "Ask Telmed AI",
                                  iconData: Icons.smart_toy_outlined,
                                  color: Colors.white,
                                  primary: false,
                                  onTap: () {
                                    Navigator.pushNamed(context, '/ai_chat');
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isMobile)
                  const Expanded(
                    flex: 1,
                    child: Center(
                      child: _HeroVisualComposition(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroAestheticPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      300.0,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.9),
      200.0,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeroBadge extends StatelessWidget {
  final String text;

  const _HeroBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 12.0,
        ),
      ),
    );
  }
}

class _HeroVisualComposition extends StatelessWidget {
  const _HeroVisualComposition();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 450.0,
          height: 450.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        Container(
          width: 350.0,
          height: 350.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(200.0),
          child: Image.network(
            'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=2070&auto=format&fit=crop',
            width: 300.0,
            height: 300.0,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          bottom: 40.0,
          right: 0.0,
          child: _GlassStatusChip("Verified Doctors", Icons.check_circle),
        ),
        Positioned(
          top: 40.0,
          left: 0.0,
          child: _GlassStatusChip("Instant Access", Icons.flash_on),
        ),
      ],
    );
  }
}

/// ----------------------------------------------------------------------
/// SECTION 2: TRUST PULSE BAR (STATISTICS)
/// ----------------------------------------------------------------------
class _TrustPulseBar extends StatelessWidget {
  const _TrustPulseBar();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      transform: Matrix4.translationValues(0.0, -50.0, 0.0),
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 20.0 : 100.0,
      ),
      padding: EdgeInsets.symmetric(
        vertical: 50.0,
        horizontal: isMobile ? 20.0 : 40.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 80.0,
            offset: const Offset(0.0, 20.0),
          )
        ],
      ),
      child: isMobile
          ? const Column(
              children: [
                _StatBlock("2M+", "Call Consultations"),
                SizedBox(height: 30.0),
                _StatBlock("KSH 54", "Per Call Session"),
                SizedBox(height: 30.0),
                _StatBlock("60s", "Avg. Connection Time"),
              ],
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatBlock("2M+", "Call Consultations"),
                _StatDivider(),
                _StatBlock("KSH 54", "Per Call Session"),
                _StatDivider(),
                _StatBlock("60s", "Avg. Connection Time"),
              ],
            ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String title;
  final String subtitle;

  const _StatBlock(this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 36.0,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D7D46),
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
            fontSize: 14.0,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.0,
      width: 1.0,
      color: Colors.black.withOpacity(0.1),
    );
  }
}

/// ----------------------------------------------------------------------
/// SECTION 3: TELEMEDICINE SHOWCASE
/// ----------------------------------------------------------------------
class _TelemedicineShowcase extends StatelessWidget {
  const _TelemedicineShowcase();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 1100;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 100.0,
        horizontal: isMobile ? 20.0 : 100.0,
      ),
      child: Column(
        children: [
          const _SectionTitle(
            label: "VOICE CARE",
            title: "Expert Advice via Phone",
            subtitle:
                "Tap 'Pigia Telmed' to start your consultation session instantly for just KSH 54.",
          ),
          const SizedBox(height: 80.0),
          Wrap(
            spacing: 30.0,
            runSpacing: 30.0,
            alignment: WrapAlignment.center,
            children: const [
              _FeatureCard(
                icon: Icons.phone_in_talk_outlined,
                title: "Voice Call",
                desc: "Speak directly to a doctor for KSH 54.",
                color: Color(0xFFF0F7F2),
              ),
              _FeatureCard(
                icon: Icons.receipt_long_outlined,
                title: "Digital Prescription",
                desc: "Receive prescriptions via SMS instantly.",
                color: Color(0xFFFFF8E5),
              ),
              _FeatureCard(
                icon: Icons.verified_user_outlined,
                title: "Secure Records",
                desc: "Your medical data is encrypted & private.",
                color: Color(0xFFF0F4FF),
              ),
              _FeatureCard(
                icon: Icons.support_agent_outlined,
                title: "24/7 Availability",
                desc: "Doctors are ready to answer anytime.",
                color: Color(0xFFFFF0F0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280.0,
      padding: const EdgeInsets.all(30.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20.0,
            offset: const Offset(0.0, 10.0),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(15.0),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30.0,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 25.0),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 15.0),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 15.0,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// ----------------------------------------------------------------------
/// SECTION 4: HOMECARE IMMERSIVE
/// ----------------------------------------------------------------------
class _HomecareImmersiveSection extends StatelessWidget {
  const _HomecareImmersiveSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: 120.0,
        horizontal: isMobile ? 20.0 : 100.0,
      ),
      color: const Color(0xFFFAFAFA),
      child: isMobile
          ? Column(
              children: [
                _buildImage(),
                const SizedBox(height: 60.0),
                _buildContent(isMobile),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildImage()),
                const SizedBox(width: 80.0),
                Expanded(child: _buildContent(isMobile)),
              ],
            ),
    );
  }

  Widget _buildImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(40.0),
          child: Image.network(
            'https://images.unsplash.com/photo-1576091160550-2173dba999ef?q=80&w=2070&auto=format&fit=crop',
            height: 450.0,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const Positioned(
          top: 30.0,
          right: 30.0,
          child: _GlassStatusChip(
            "Mobile Lab Active",
            Icons.biotech_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel("PREMIUM HOMECARE"),
        const SizedBox(height: 20.0),
        Text(
          "We Bring The Entire\nHospital To You.",
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 36.0 : 48.0,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 30.0),
        const _HomecareBullet(
          title: "In-Home Lab Testing",
          desc:
              "If the doctor recommends a test during your call, we send a technician to you.",
        ),
        const _HomecareBullet(
          title: "Professional Nursing",
          desc:
              "Wound care, IV treatments, and regular checkups from the comfort of your bed.",
        ),
        const SizedBox(height: 40.0),
        const ActionBtn(
          label: "Book a Home Visit",
          iconData: Icons.home_work_rounded,
          color: Color(0xFF2D7D46),
          primary: true,
        ),
      ],
    );
  }
}

class _HomecareBullet extends StatelessWidget {
  final String title;
  final String desc;

  const _HomecareBullet({
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color(0xFF2D7D46).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Color(0xFF2D7D46),
              size: 20.0,
            ),
          ),
          const SizedBox(width: 20.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 15.0,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ----------------------------------------------------------------------
/// SECTION 5: HYBRID CARE PHILOSOPHY
/// ----------------------------------------------------------------------
class _HybridCarePhilosophy extends StatelessWidget {
  const _HybridCarePhilosophy();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 100.0,
        horizontal: isMobile ? 20.0 : 100.0,
      ),
      child: Column(
        children: [
          const _SectionTitle(
            label: "OUR PHILOSOPHY",
            title: "Remote First. Physical When Needed.",
            subtitle:
                "We believe 80% of healthcare needs can be solved over a phone call.",
          ),
          const SizedBox(height: 60.0),
          Container(
            padding: const EdgeInsets.all(40.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30.0),
              border: Border.all(
                color: Colors.black.withOpacity(0.05),
              ),
            ),
            child: Text(
              "By eliminating waiting rooms, we save you time and money. Start with a KSH 54 call. If your condition is complex, we escalate it to physical home care or a specialist referral automatically.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22.0,
                color: Colors.black87,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ----------------------------------------------------------------------
/// SECTION 6: MODERN STEP PROCESS
/// ----------------------------------------------------------------------
class _ModernStepProcess extends StatelessWidget {
  const _ModernStepProcess();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      width: double.infinity,
      color: const Color(0xFFF0F7F2),
      padding: EdgeInsets.symmetric(
        vertical: 100.0,
        horizontal: isMobile ? 20.0 : 100.0,
      ),
      child: Column(
        children: [
          const _SectionTitle(
            label: "HOW IT WORKS",
            title: "3 Simple Steps",
            subtitle: "Getting care has never been easier.",
          ),
          const SizedBox(height: 80.0),
          isMobile
              ? Column(
                  children: [
                    _buildStep(
                      "01",
                      "Request Call",
                      "Tap the Call button and enter your issue.",
                    ),
                    const SizedBox(height: 40.0),
                    _buildStep(
                      "02",
                      "Pay KSH 54",
                      "Process secure payment via M-Pesa.",
                    ),
                    const SizedBox(height: 40.0),
                    _buildStep(
                      "03",
                      "Consult & Heal",
                      "Speak to a doctor and get your prescription.",
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStep(
                      "01",
                      "Request Call",
                      "Tap the Call button and enter your issue.",
                    ),
                    _buildStep(
                      "02",
                      "Pay KSH 54",
                      "Process secure payment via M-Pesa.",
                    ),
                    _buildStep(
                      "03",
                      "Consult & Heal",
                      "Speak to a doctor and get your prescription.",
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String title, String description) {
    return Column(
      children: [
        Text(
          number,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 60.0,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF2D7D46).withOpacity(0.2),
          ),
        ),
        const SizedBox(height: 20.0),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10.0),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 16.0,
          ),
        ),
      ],
    );
  }
}

/// ----------------------------------------------------------------------
/// SECTION 7: ELITE PRICING MODULE
/// ----------------------------------------------------------------------
class _ElitePricingModule extends StatelessWidget {
  const _ElitePricingModule();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 120.0,
        horizontal: isMobile ? 20.0 : 100.0,
      ),
      child: Column(
        children: [
          const _SectionTitle(
            label: "TRANSPARENT PRICING",
            title: "Affordable Healthcare.",
            subtitle: "No hidden fees. Quality care for everyone.",
          ),
          const SizedBox(height: 80.0),
          isMobile
              ? Column(
                  children: const [
                    _PricingCard(
                      title: "Voice Consult",
                      price: "KSH 54",
                      desc: "Per Call Session",
                      isHighlighted: true,
                    ),
                    SizedBox(height: 30.0),
                    _PricingCard(
                      title: "Home Visit",
                      price: "KSH 1500",
                      desc: "Base Nursing Fee",
                      isHighlighted: false,
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _PricingCard(
                      title: "Voice Consult",
                      price: "KSH 54",
                      desc: "Per Call Session",
                      isHighlighted: true,
                    ),
                    SizedBox(width: 40.0),
                    _PricingCard(
                      title: "Home Visit",
                      price: "KSH 1500",
                      desc: "Base Nursing Fee",
                      isHighlighted: false,
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String desc;
  final bool isHighlighted;

  const _PricingCard({
    required this.title,
    required this.price,
    required this.desc,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350.0,
      padding: const EdgeInsets.all(50.0),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFF2D7D46) : Colors.white,
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(
          color: isHighlighted
              ? Colors.transparent
              : Colors.black.withOpacity(0.1),
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: const Color(0xFF2D7D46).withOpacity(0.3),
                  blurRadius: 30.0,
                  offset: const Offset(0.0, 15.0),
                )
              ]
            : null,
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 30.0),
          Text(
            price,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 48.0,
              fontWeight: FontWeight.w900,
              color: isHighlighted ? Colors.white : const Color(0xFF2D7D46),
            ),
          ),
          const SizedBox(height: 10.0),
          Text(
            desc,
            style: TextStyle(
              fontSize: 16.0,
              color: isHighlighted
                  ? Colors.white.withOpacity(0.8)
                  : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

/// ----------------------------------------------------------------------
/// SECTION 8: TESTIMONIALS
/// ----------------------------------------------------------------------
class _TestimonialWall extends StatefulWidget {
  const _TestimonialWall();

  @override
  State<_TestimonialWall> createState() => _TestimonialWallState();
}

class _TestimonialWallState extends State<_TestimonialWall> {
  final List<Map<String, String>> _testimonials = [
    {
      "name": "Mercy W.",
      "text": "I called at 2 AM for my son's fever. The KSH 54 call saved us!"
    },
    {
      "name": "David O.",
      "text": "Paid my 54 bob, got connected in 30 seconds. Best healthcare app."
    },
    {
      "name": "Sarah K.",
      "text": "Prescription arrived 1 minute after the call ended."
    },
    {
      "name": "John M.",
      "text": "I was skeptical about the price, but the doctor was very professional."
    },
    {
      "name": "Grace L.",
      "text": "Great for parents. Didn't have to drag my sick kid to a waiting room."
    },
    {
      "name": "Samuel T.",
      "text": "The homecare nurse arrived within an hour of the doctor's referral."
    },
    {
      "name": "Esther N.",
      "text": "Living far from town, this is a lifesaver. Consulted right from my farm."
    },
    {
      "name": "Brian K.",
      "text": "Very private and secure. I felt comfortable discussing my issues."
    },
    {
      "name": "Loise A.",
      "text": "The follow-up call the next day showed they really care."
    },
  ];

  late PageController _pageController;
  Timer? _timer;
  int _virtualIndex = 1000;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _virtualIndex,
      viewportFraction: 1.0,
    );
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    final int realIndex = _virtualIndex % _testimonials.length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 120.0),
      child: Column(
        children: [
          const _SectionTitle(
            label: "TESTIMONIALS",
            title: "Loved by Millions",
            subtitle: "Swipe through stories from our global community.",
          ),
          const SizedBox(height: 60.0),
          SizedBox(
            height: 350.0,
            child: Row(
              children: [
                if (!isMobile)
                  Padding(
                    padding: const EdgeInsets.only(left: 40.0),
                    child: _NavBtn(
                      icon: Icons.arrow_back_ios,
                      onTap: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      },
                    ),
                  ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int index) {
                      setState(() {
                        _virtualIndex = index;
                      });
                    },
                    itemBuilder: (BuildContext context, int index) {
                      final Map<String, String> t =
                          _testimonials[index % _testimonials.length];
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 20.0 : 100.0,
                        ),
                        child: _ReviewCard(t['name']!, t['text']!),
                      );
                    },
                  ),
                ),
                if (!isMobile)
                  Padding(
                    padding: const EdgeInsets.only(right: 40.0),
                    child: _NavBtn(
                      icon: Icons.arrow_forward_ios,
                      onTap: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 40.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _testimonials.length,
              (int index) {
                final bool isActive = index == realIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  height: 8.0,
                  width: isActive ? 24.0 : 8.0,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF2D7D46) : Colors.black12,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50.0),
      child: Container(
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF2D7D46).withOpacity(0.2),
          ),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF2D7D46),
          size: 20.0,
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String name;
  final String text;

  const _ReviewCard(this.name, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.star,
            color: Color(0xFFF9A825),
            size: 30.0,
          ),
          const SizedBox(height: 30.0),
          Text(
            '"$text"',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20.0,
              fontStyle: FontStyle.italic,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 30.0),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D7D46),
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// ----------------------------------------------------------------------
/// SECTION 9: FAQ
/// ----------------------------------------------------------------------
class _FaqSection extends StatelessWidget {
  const _FaqSection();

  static const List<Map<String, String>> _faqData = [
    {
      "q": "When exactly do I pay the KSH 54 fee?",
      "a": "The KSH 54 fee is paid upfront before the phone call begins. Once you tap 'Call Telmed', you will be prompted to complete the payment via M-Pesa."
    },
    {
      "q": "How long does a consultation last?",
      "a": "We do not set strict time limits. The KSH 54 fee covers the complete session required for the doctor to provide a diagnosis and treatment plan."
    },
    {
      "q": "What medical conditions can Telmed doctors treat?",
      "a": "Common issues like malaria symptoms, UTIs, respiratory infections, stomach issues, and skin rashes can be diagnosed over the call."
    },
    {
      "q": "Is the fee refundable?",
      "a": "If our doctor determines within the first two minutes that your condition requires an ER visit, we credit that KSH 54 back to your account."
    },
    {
      "q": "Can I call for my child?",
      "a": "Absolutely. Many parents use the service for pediatric advice on fevers, coughs, or rashes to avoid unnecessary hospital trips."
    },
    {
      "q": "Are the doctors fully qualified?",
      "a": "Yes. Every doctor is a licensed medical professional registered with the KMPDC. We prioritize quality care above all."
    },
    {
      "q": "How do I get my prescription?",
      "a": "Immediately following the session, the doctor generates a digital prescription sent via SMS, WhatsApp, and the Telmed App."
    },
    {
      "q": "Does the fee include lab tests?",
      "a": "No, the KSH 54 fee covers the professional medical advice only. Lab tests and home nursing are billed separately."
    },
    {
      "q": "What if I need to talk to the same doctor again?",
      "a": "Follow-up calls within 24 hours regarding the same condition are prioritized to ensure continuity of your treatment plan."
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    final int midPoint = (_faqData.length / 2).ceil();

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 120.0,
        horizontal: isMobile ? 20.0 : 100.0,
      ),
      child: Column(
        children: [
          const _SectionTitle(
            label: "HAVE QUESTIONS?",
            title: "Everything You Need to Know",
            subtitle: "Answers to the 9 most common questions our patients ask.",
          ),
          const SizedBox(height: 80.0),
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile)
                Column(
                  children: _faqData
                      .map((Map<String, String> d) =>
                          _FaqTile(d['q']!, d['a']!))
                      .toList(),
                )
              else ...[
                Expanded(
                  child: Column(
                    children: _faqData
                        .sublist(0, midPoint)
                        .map((Map<String, String> d) =>
                            _FaqTile(d['q']!, d['a']!))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 40.0),
                Expanded(
                  child: Column(
                    children: _faqData
                        .sublist(midPoint)
                        .map((Map<String, String> d) =>
                            _FaqTile(d['q']!, d['a']!))
                        .toList(),
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String q;
  final String a;

  const _FaqTile(this.q, this.a);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.black.withOpacity(0.08),
        ),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 8.0,
        ),
        iconColor: const Color(0xFF2D7D46),
        title: Text(
          q,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
            color: Color(0xFF0F172A),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              bottom: 24.0,
            ),
            child: Text(
              a,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 15.0,
                height: 1.6,
              ),
            ),
          )
        ],
      ),
    );
  }
}

/// ----------------------------------------------------------------------
/// UNIVERSAL HELPER WIDGETS
/// ----------------------------------------------------------------------
class _SectionTitle extends StatelessWidget {
  final String label;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.label,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Column(
      children: [
        _SectionLabel(label),
        const SizedBox(height: 20.0),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 36.0 : 48.0,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 15.0),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18.0,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF2D7D46).withOpacity(0.1),
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF2D7D46),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 12.0,
        ),
      ),
    );
  }
}

class _GlassStatusChip extends StatelessWidget {
  final String text;
  final IconData icon;

  const _GlassStatusChip(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15.0,
        vertical: 10.0,
      ),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 18.0,
          ),
          const SizedBox(width: 10.0),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    );
  }
}