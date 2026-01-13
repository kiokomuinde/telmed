import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telmed/widgets/common_widget.dart';

/// ---------------------------------------------------------------------------
/// TELMED FLAGSHIP LANDING PAGE - V6.2 (INFINITE CAROUSEL & AUTO-SWIPE)
/// ---------------------------------------------------------------------------

class TelmedHomePage extends StatefulWidget {
  const TelmedHomePage({super.key});

  @override
  State<TelmedHomePage> createState() => _TelmedHomePageState();
}

class _TelmedHomePageState extends State<TelmedHomePage> with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _heroTextController;
  late Animation<double> _heroOpacity;
  late Animation<Offset> _heroSlide;

  double _navOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (mounted) {
          setState(() {
            _navOpacity = (_scrollController.offset / 400).clamp(0, 1);
          });
        }
      });

    _heroTextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _heroOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heroTextController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );

    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _heroTextController, curve: const Interval(0.0, 0.8, curve: Curves.easeOutQuart)),
    );

    _heroTextController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _heroTextController.dispose();
    super.dispose();
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
          _HeroSection(heroOpacity: _heroOpacity, heroSlide: _heroSlide),
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

// --- HERO SECTION ---
class _HeroSection extends StatelessWidget {
  final Animation<double> heroOpacity;
  final Animation<Offset> heroSlide;

  const _HeroSection({required this.heroOpacity, required this.heroSlide});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return Container(
      width: double.infinity,
      height: isMobile ? null : size.height * 0.95,
      padding: isMobile ? const EdgeInsets.only(top: 100, bottom: 80) : null,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D7D46), Color(0xFF1B4D2C)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _HeroAestheticPainter())),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 100),
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
                          const _HeroBadge(text: "✨ DOCTOR ON CALL 24/7"),
                          const SizedBox(height: 30),
                          Text(
                            "The Doctor is\nJust a Phone\nCall Away.",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isMobile ? 48 : 72,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -2,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            "Speak directly to a licensed doctor for only KSH 54 per call. No waiting rooms, no travel—just professional care.",
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 20,
                              color: Colors.white.withOpacity(0.8),
                              height: 1.6,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 50),
                          if (isMobile) ...[
                             const ActionBtn(
                                label: "Call Telmed (KSH 54)",
                                iconData: Icons.phone_forwarded_rounded,
                                color: Color(0xFFF9A825),
                                primary: true,
                              ),
                              const SizedBox(height: 20),
                              const ActionBtn(
                                label: "WhatsApp Chat",
                                iconUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/WhatsApp.svg/1200px-WhatsApp.svg.png",
                                color: Colors.white,
                                primary: false,
                              ),
                          ] else 
                          const Row(
                            children: [
                              ActionBtn(
                                label: "Call Telmed (KSH 54)",
                                iconData: Icons.phone_forwarded_rounded,
                                color: Color(0xFFF9A825),
                                primary: true,
                              ),
                              SizedBox(width: 25),
                              ActionBtn(
                                label: "WhatsApp Chat",
                                iconUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/WhatsApp.svg/1200px-WhatsApp.svg.png",
                                color: Colors.white,
                                primary: false,
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
                    child: Center(child: _HeroVisualComposition()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- TESTIMONIALS (INFINITE 360° LOOP + AUTO SWIPE) ---
class _TestimonialWall extends StatefulWidget {
  const _TestimonialWall();

  @override
  State<_TestimonialWall> createState() => _TestimonialWallState();
}

class _TestimonialWallState extends State<_TestimonialWall> {
  // 9 Testimonial Data Points
  final List<Map<String, String>> _testimonials = [
    {"name": "Mercy W.", "text": "I called at 2 AM for my son's fever. The KSH 54 call saved us!"},
    {"name": "David O.", "text": "Paid my 54 bob, got connected in 30 seconds. Best healthcare app."},
    {"name": "Sarah K.", "text": "Prescription arrived 1 minute after the call ended."},
    {"name": "John M.", "text": "I was skeptical about the price, but the doctor was very professional."},
    {"name": "Grace L.", "text": "Great for parents. Didn't have to drag my sick kid to a waiting room."},
    {"name": "Samuel T.", "text": "The homecare nurse arrived within an hour of the doctor's referral."},
    {"name": "Esther N.", "text": "Living far from town, this is a lifesaver. Consulted right from my farm."},
    {"name": "Brian K.", "text": "Very private and secure. I felt comfortable discussing my issues."},
    {"name": "Loise A.", "text": "The follow-up call the next day showed they really care."},
  ];

  late PageController _pageController;
  Timer? _timer;
  int _virtualIndex = 1000; // Large starting number for infinite loop

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _virtualIndex, viewportFraction: 1.0);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(duration: const Duration(milliseconds: 800), curve: Curves.easeInOut);
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
    final isMobile = MediaQuery.of(context).size.width < 900;
    final int realIndex = _virtualIndex % _testimonials.length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 120),
      child: Column(
        children: [
          const _SectionTitle(
            label: "TESTIMONIALS", 
            title: "Loved by Millions", 
            subtitle: "Swipe through stories from our global community."
          ),
          const SizedBox(height: 60),
          
          SizedBox(
            height: 350,
            child: Row(
              children: [
                if (!isMobile)
                  Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: _NavBtn(icon: Icons.arrow_back_ios, onTap: () {
                      _pageController.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.ease);
                    }),
                  ),
                
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _virtualIndex = index),
                    itemBuilder: (context, index) {
                      final t = _testimonials[index % _testimonials.length];
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 100),
                        child: _ReviewCard(t['name']!, t['text']!),
                      );
                    },
                  ),
                ),

                if (!isMobile)
                  Padding(
                    padding: const EdgeInsets.only(right: 40),
                    child: _NavBtn(icon: Icons.arrow_forward_ios, onTap: () {
                      _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.ease);
                    }),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          
          // Dots Indicator based on real index
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_testimonials.length, (index) {
              final isActive = index == realIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: isActive ? 24 : 8,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF2D7D46) : Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
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
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF2D7D46).withOpacity(0.2)),
        ),
        child: Icon(icon, color: const Color(0xFF2D7D46), size: 20),
      ),
    );
  }
}

// --- FAQ SECTION (9 QUESTIONS) ---
class _FaqSection extends StatelessWidget {
  const _FaqSection();

  static const List<Map<String, String>> _faqData = [
    {"q": "When exactly do I pay the KSH 54 fee?", "a": "The KSH 54 fee is paid upfront before the phone call begins. Once you tap 'Call Telmed', you will be prompted to complete the payment via M-Pesa."},
    {"q": "How long does a consultation last?", "a": "We do not set strict time limits. The KSH 54 fee covers the complete session required for the doctor to provide a diagnosis and treatment plan."},
    {"q": "What medical conditions can Telmed doctors treat?", "a": "Common issues like malaria symptoms, UTIs, respiratory infections, stomach issues, and skin rashes can be diagnosed over the call."},
    {"q": "Is the fee refundable?", "a": "If our doctor determines within the first two minutes that your condition requires an ER visit, we credit that KSH 54 back to your account."},
    {"q": "Can I call for my child?", "a": "Absolutely. Many parents use the service for pediatric advice on fevers, coughs, or rashes to avoid unnecessary hospital trips."},
    {"q": "Are the doctors fully qualified?", "a": "Yes. Every doctor is a licensed medical professional registered with the KMPDC. We prioritize quality care above all."},
    {"q": "How do I get my prescription?", "a": "Immediately following the session, the doctor generates a digital prescription sent via SMS, WhatsApp, and the Telmed App."},
    {"q": "Does the fee include lab tests?", "a": "No, the KSH 54 fee covers the professional medical advice only. Lab tests and home nursing are billed separately."},
    {"q": "What if I need to talk to the same doctor again?", "a": "Follow-up calls within 24 hours regarding the same condition are prioritized to ensure continuity of your treatment plan."},
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final midPoint = (_faqData.length / 2).ceil();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 120, horizontal: isMobile ? 20 : 100),
      child: Column(
        children: [
          const _SectionTitle(
            label: "HAVE QUESTIONS?",
            title: "Everything You Need to Know",
            subtitle: "Answers to the 9 most common questions our patients ask.",
          ),
          const SizedBox(height: 80),
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile)
                 Column(children: _faqData.map((d) => _FaqTile(d['q']!, d['a']!)).toList())
              else ...[
                Expanded(child: Column(children: _faqData.sublist(0, midPoint).map((d) => _FaqTile(d['q']!, d['a']!)).toList())),
                const SizedBox(width: 40),
                Expanded(child: Column(children: _faqData.sublist(midPoint).map((d) => _FaqTile(d['q']!, d['a']!)).toList())),
              ]
            ],
          ),
        ],
      ),
    );
  }
}

// --- HOMECARE SECTION ---
class _HomecareImmersiveSection extends StatelessWidget {
  const _HomecareImmersiveSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 120, horizontal: isMobile ? 20 : 100),
      color: const Color(0xFFFAFAFA),
      child: isMobile 
      ? Column(
          children: [
            _buildImage(),
            const SizedBox(height: 60),
            _buildContent(isMobile),
          ],
        )
      : Row(
          children: [
            Expanded(child: _buildImage()),
            const SizedBox(width: 80),
            Expanded(child: _buildContent(isMobile)),
          ],
      ),
    );
  }

  Widget _buildImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Image.network(
            'https://images.unsplash.com/photo-1576091160550-2173dba999ef?q=80&w=2070&auto=format&fit=crop',
            height: 450, 
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const Positioned(
          top: 30,
          right: 30,
          child: _GlassStatusChip("Mobile Lab Active", Icons.biotech_rounded),
        ),
      ],
    );
  }

  Widget _buildContent(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel("PREMIUM HOMECARE"),
        const SizedBox(height: 20),
        Text(
          "We Bring The Entire\nHospital To You.",
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 36 : 48,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 30),
        const _HomecareBullet(
          title: "In-Home Lab Testing",
          desc: "If the doctor recommends a test during your call, we send a technician to you.",
        ),
        const _HomecareBullet(
          title: "Professional Nursing",
          desc: "Wound care, IV treatments, and regular checkups from the comfort of your bed.",
        ),
        const SizedBox(height: 40),
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

// --- SUPPORTING UI MODULES ---

class _ReviewCard extends StatelessWidget {
  final String name, text;
  const _ReviewCard(this.name, this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40), 
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA), 
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.black.withOpacity(0.05))
      ), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, 
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star, color: Color(0xFFF9A825), size: 30), 
          const SizedBox(height: 30), 
          Text(
            '"$text"', 
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontStyle: FontStyle.italic, color: Colors.black87)
          ), 
          const SizedBox(height: 30), 
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D7D46), fontSize: 16))
        ]
      )
    );
  }
}

class _TrustPulseBar extends StatelessWidget {
  const _TrustPulseBar();
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Container(
      transform: Matrix4.translationValues(0, -50, 0),
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 100),
      padding: EdgeInsets.symmetric(vertical: 50, horizontal: isMobile ? 20 : 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 80, offset: const Offset(0, 20))],
      ),
      child: isMobile 
        ? const Column(
            children: [
              _StatBlock("2M+", "Call Consultations"),
              SizedBox(height: 30),
              _StatBlock("KSH 54", "Per Call Session"),
              SizedBox(height: 30),
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

class _TelemedicineShowcase extends StatelessWidget {
  const _TelemedicineShowcase();
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1100;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 100, horizontal: isMobile ? 20 : 100),
      child: Column(
        children: [
          const _SectionTitle(
            label: "VOICE CARE",
            title: "Expert Advice via Phone",
            subtitle: "Tap 'Pigia Telmed' to start your consultation session instantly for just KSH 54.",
          ),
          const SizedBox(height: 80),
          Wrap(
            spacing: 30,
            runSpacing: 30,
            alignment: WrapAlignment.center,
            children: const [
              _FeatureCard(icon: Icons.phone_in_talk_outlined, title: "Voice Call", desc: "Speak directly to a doctor for KSH 54.", color: Color(0xFFF0F7F2)),
              _FeatureCard(icon: Icons.chat_bubble_outline, title: "WhatsApp Lab", desc: "Share results and photos with the team.", color: Color(0xFFFFF9EE)),
              _FeatureCard(icon: Icons.history_edu_outlined, title: "Digital File", desc: "Your call history is saved securely.", color: Color(0xFFEFF6FF)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HybridCarePhilosophy extends StatelessWidget {
  const _HybridCarePhilosophy();
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 40 : 100),
      decoration: const BoxDecoration(color: Color(0xFF1B4D2C)),
      child: Column(
        children: [
          const Icon(Icons.verified_user_outlined, color: Color(0xFFF9A825), size: 40),
          const SizedBox(height: 25),
          Text(
            "Call to Clinic Promise", 
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: isMobile ? 32 : 40, fontWeight: FontWeight.bold, color: Colors.white)
          ),
          const SizedBox(height: 25),
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Text(
              "If the doctor you speak to on the phone determines you need an in-person exam, your KSH 54 call fee is waived when you visit our medical center within 3 days.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: isMobile ? 16 : 20, height: 1.6, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernStepProcess extends StatelessWidget {
  const _ModernStepProcess();
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1000;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 120, horizontal: isMobile ? 20 : 100),
      child: Column(
        children: [
          const _SectionTitle(label: "HOW IT WORKS", title: "Minutes to Wellness", subtitle: "Simple steps to get the assistance you need."),
          const SizedBox(height: 80),
          if (isMobile)
             Column(
              children: const [
                 _ProcessNode(title: "Request Call", desc: "Tap call and pay KSH 54 via M-Pesa.", icon: Icons.touch_app_outlined),
                 SizedBox(height: 40),
                 _ProcessNode(title: "Consultation", desc: "Speak to the doctor about your health.", icon: Icons.record_voice_over_outlined),
                 SizedBox(height: 40),
                 _ProcessNode(title: "Treatment", desc: "Receive your prescription via SMS.", icon: Icons.task_alt_rounded),
              ],
             )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _ProcessNode(title: "Request Call", desc: "Tap call and pay KSH 54 via M-Pesa.", icon: Icons.touch_app_outlined),
                _ProcessConnector(),
                _ProcessNode(title: "Consultation", desc: "Speak to the doctor about your health.", icon: Icons.record_voice_over_outlined),
                _ProcessConnector(),
                _ProcessNode(title: "Treatment", desc: "Receive your prescription via SMS.", icon: Icons.task_alt_rounded),
              ],
            ),
        ],
      ),
    );
  }
}

class _ElitePricingModule extends StatelessWidget {
  const _ElitePricingModule();
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1000;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 100, vertical: 50),
      height: isMobile ? null : 550,
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        children: [
          Expanded(
            flex: isMobile ? 0 : 1,
            child: Container(
              padding: const EdgeInsets.all(60),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F2), 
                borderRadius: isMobile 
                  ? const BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40))
                  : const BorderRadius.only(topLeft: Radius.circular(40), bottomLeft: Radius.circular(40))
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _SectionLabel("PRICING"),
                  const SizedBox(height: 20),
                  Text("Voice Session\nfor KSH 54.", style: GoogleFonts.plusJakartaSans(fontSize: isMobile ? 36 : 44, fontWeight: FontWeight.w800, color: const Color(0xFF1B4D2C))),
                  const SizedBox(height: 30),
                  const _PricingCheck(text: "Payment via M-Pesa"),
                  const _PricingCheck(text: "Paid before the call starts"),
                  const _PricingCheck(text: "Includes Digital Prescription"),
                ],
              ),
            ),
          ),
          Expanded(
            flex: isMobile ? 0 : 1,
            child: Container(
              padding: isMobile ? const EdgeInsets.symmetric(vertical: 60) : null,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2D7D46), Color(0xFF4CAF50)]),
                borderRadius: isMobile 
                  ? const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40))
                  : const BorderRadius.only(topRight: Radius.circular(40), bottomRight: Radius.circular(40)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("CALL SESSION FEE", style: TextStyle(color: Colors.white70, letterSpacing: 2)),
                  Text("54", style: GoogleFonts.plusJakartaSans(fontSize: 120, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -5)),
                  const Text("KSH Per Consultation", style: TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF9A825), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: const Text("PIGIA TELMED NOW", style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroVisualComposition extends StatefulWidget {
  const _HeroVisualComposition();
  @override
  State<_HeroVisualComposition> createState() => _HeroVisualCompositionState();
}

class _HeroVisualCompositionState extends State<_HeroVisualComposition> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  }
  @override
  void dispose() { _floatController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * _floatController.value),
          child: Container(
            height: 500,
            width: 380,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              image: const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80'), fit: BoxFit.cover),
              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 40, offset: Offset(0, 20))],
            ),
          ),
        );
      },
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String val, label;
  const _StatBlock(this.val, this.label);
  @override
  Widget build(BuildContext context) {
    return Column(children: [Text(val, style: GoogleFonts.plusJakartaSans(fontSize: 36, fontWeight: FontWeight.w900, color: const Color(0xFF2D7D46))), Text(label, style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.bold))]);
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) { return Container(height: 40, width: 1, color: Colors.black12); }
}

class _ProcessConnector extends StatelessWidget {
  const _ProcessConnector();
  @override
  Widget build(BuildContext context) { return Container(width: 50, height: 2, color: Colors.black12); }
}

class _PricingCheck extends StatelessWidget {
  final String text;
  const _PricingCheck({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [const Icon(Icons.check_circle, color: Color(0xFF2D7D46), size: 18), const SizedBox(width: 10), Text(text)]));
  }
}

class _HeroBadge extends StatelessWidget {
  final String text;
  const _HeroBadge({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulseDot(),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _ctrl, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)));
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title, desc;
  final Color color;
  const _FeatureCard({required this.icon, required this.title, required this.desc, required this.color});
  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
        width: 320,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.black12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(15)), child: Icon(widget.icon, size: 30)),
            const SizedBox(height: 25),
            Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(widget.desc, style: const TextStyle(color: Colors.black45, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label, title, subtitle;
  const _SectionTitle({required this.label, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Column(
      children: [
        _SectionLabel(label),
        const SizedBox(height: 15),
        Text(title, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: isMobile ? 36 : 48, fontWeight: FontWeight.w800)),
        const SizedBox(height: 15),
        Container(constraints: const BoxConstraints(maxWidth: 600), child: Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.black45))),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) { return Text(text, style: const TextStyle(color: Color(0xFFF9A825), fontWeight: FontWeight.w900, letterSpacing: 2)); }
}

class _HomecareBullet extends StatelessWidget {
  final String title, desc;
  const _HomecareBullet({required this.title, required this.desc});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Row(children: [const Icon(Icons.check_circle, color: Color(0xFF2D7D46), size: 24), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(desc, style: const TextStyle(color: Colors.black45))]))]),
    );
  }
}

class _ProcessNode extends StatelessWidget {
  final String title, desc;
  final IconData icon;
  const _ProcessNode({required this.title, required this.desc, required this.icon});
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 220, child: Column(children: [Icon(icon, size: 40, color: const Color(0xFF2D7D46)), const SizedBox(height: 15), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black45))]));
  }
}

class _FaqTile extends StatelessWidget {
  final String q, a;
  const _FaqTile(this.q, this.a);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black.withOpacity(0.08)), borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        iconColor: const Color(0xFF2D7D46),
        title: Text(q, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
        children: [Padding(padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24), child: Text(a, style: const TextStyle(color: Colors.black54, fontSize: 15, height: 1.6)))]),
    );
  }
}

class _GlassStatusChip extends StatelessWidget {
  final String text;
  final IconData icon;
  const _GlassStatusChip(this.text, this.icon);
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(15)), child: Row(children: [Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 10), Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]));
  }
}

class _HeroAestheticPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.02);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.3), 200, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}