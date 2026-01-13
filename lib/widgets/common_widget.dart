import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:telmed/widgets/call_overlay.dart';

/// --- FLEXIBLE BRAND LOGO ---
class BrandLogo extends StatelessWidget {
  final bool isDark;
  final double height;
  final bool showName; // Added to control text visibility

  const BrandLogo({
    super.key, 
    this.isDark = true, 
    this.height = 40.0,
    this.showName = false, 
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.webp',
          height: height,
          fit: BoxFit.contain,
        ),
        if (showName) ...[
          const SizedBox(width: 12),
          Text(
            "TELMED",
            style: GoogleFonts.plusJakartaSans(
              fontSize: height * 0.6, // Scales with image height
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? const Color(0xFF2D7D46) : Colors.white,
            ),
          ),
        ],
      ],
    );
  }
}

class TelmedNavBar extends StatelessWidget {
  final double navOpacity;
  const TelmedNavBar({super.key, required this.navOpacity});

  @override
  Widget build(BuildContext context) {
    final bool isScrolled = navOpacity > 0.5;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    return Positioned(
      top: 0, left: 0, right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10 * navOpacity, sigmaY: 10 * navOpacity),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 60, 
              vertical: 20
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(navOpacity * 0.8),
              border: Border(bottom: BorderSide(color: isScrolled ? Colors.black12 : Colors.transparent)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Name is ENABLED here
                  BrandLogo(
                    isDark: isScrolled ? true : false, 
                    height: 35, 
                    showName: true
                  ), 
                  const Spacer(),
                  if (!isMobile) ...[
                    _navItem("Services", isScrolled),
                    _navItem("Homecare", isScrolled),
                    _navItem("Pricing", isScrolled),
                    const SizedBox(width: 30),
                  ],
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D7D46),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)
                    ),
                    child: const Text("Get Started", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  if (isMobile)
                    IconButton(
                      icon: Icon(Icons.menu, color: isScrolled ? Colors.black : Colors.white),
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(String label, bool isScrolled) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        label,
        style: TextStyle(
          color: isScrolled ? Colors.black87 : Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15
        ),
      ),
    );
  }
}

class TelmedFooter extends StatelessWidget {
  const TelmedFooter({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          // Name is DISABLED here as requested
          const BrandLogo(isDark: false, height: 60, showName: false), 
          const SizedBox(height: 30),
          Text(
            "Quality healthcare, just a call away.",
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
          ),
          const SizedBox(height: 50),
          const Divider(color: Colors.white10),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialIcon(Icons.facebook),
              _socialIcon(Icons.camera_alt),
              _socialIcon(Icons.alternate_email),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            "© 2026 Telmed Africa. All rights reserved.",
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _socialIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Icon(icon, color: Colors.white38, size: 20),
    );
  }
}

class TelmedDrawer extends StatelessWidget {
  const TelmedDrawer({super.key});
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF2D7D46)),
            child: Center(child: const BrandLogo(isDark: false, height: 50, showName: true)),
          ),
          ListTile(title: const Text("Services"), onTap: () {}),
          ListTile(title: const Text("Homecare"), onTap: () {}),
          ListTile(title: const Text("Pricing"), onTap: () {}),
        ],
      ),
    );
  }
}

class ActionBtn extends StatelessWidget {
  final String label;
  final String? iconUrl;
  final IconData? iconData;
  final Color color;
  final bool primary;

  const ActionBtn({
    super.key,
    required this.label,
    this.iconUrl,
    this.iconData,
    required this.color,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const CallOverlay(),
          );
        },
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 25),
          decoration: BoxDecoration(
            color: primary ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: primary ? null : Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconUrl != null) Image.network(iconUrl!, height: 22, width: 22),
              if (iconData != null) Icon(iconData, color: primary ? Colors.white : const Color(0xFFF9A825), size: 20),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}