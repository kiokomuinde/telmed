import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

/// ---------------------------------------------------------------------------
/// TELMED COMMON WIDGETS - V6.0 (WITH LOGO & CALL FEE CLARITY)
/// ---------------------------------------------------------------------------

class TelmedNavBar extends StatelessWidget {
  final double navOpacity;

  const TelmedNavBar({super.key, required this.navOpacity});

  @override
  Widget build(BuildContext context) {
    final bool isScrolled = navOpacity > 0.5;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10 * navOpacity, sigmaY: 10 * navOpacity),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(navOpacity * 0.8),
              border: Border(
                bottom: BorderSide(
                  color: isScrolled ? Colors.black12 : Colors.transparent,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  BrandLogo(isDark: isScrolled),
                  const Spacer(),
                  if (MediaQuery.of(context).size.width > 1000)
                    NavLinks(isDark: isScrolled),
                  const SizedBox(width: 40),
                  HeaderCTA(scrolled: isScrolled),
                ],
              ),
            ),
          ),
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
      padding: const EdgeInsets.only(top: 120, left: 100, right: 100, bottom: 50),
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const BrandLogo(isDark: false),
              const FooterColumn("Services", ["Voice Consult", "Homecare", "Clinics"]),
              const FooterColumn("Company", ["About Us", "Careers", "Privacy Policy"]),
              const FooterColumn("Contact", ["support@telmed.com", "+254 700 000000"]),
            ],
          ),
          const SizedBox(height: 80),
          const Divider(color: Colors.white10),
          const SizedBox(height: 30),
          const Text(
            "© 2026 Telmed Health. All rights reserved. Registered with KMPDC.",
            style: TextStyle(color: Colors.white24),
          ),
        ],
      ),
    );
  }
}

// --- SUPPORTING SUB-WIDGETS ---

class BrandLogo extends StatelessWidget {
  final bool isDark;
  const BrandLogo({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: 35,
          width: 35,
          child: Image.asset(
            'assets/images/logo.webp',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Robust fallback if image asset is not found
              return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9A825),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.health_and_safety, color: Colors.white, size: 20),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Text(
          "TELMED",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: isDark ? const Color(0xFF1B4D2C) : Colors.white,
          ),
        ),
      ],
    );
  }
}

class NavLinks extends StatelessWidget {
  final bool isDark;
  const NavLinks({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: isDark ? Colors.black87 : Colors.white70,
      fontWeight: FontWeight.w600,
    );
    return Row(
      children: [
        Text("Voice Call", style: style),
        const SizedBox(width: 30),
        Text("Homecare", style: style),
        const SizedBox(width: 30),
        Text("Our Clinics", style: style),
      ],
    );
  }
}

class HeaderCTA extends StatelessWidget {
  final bool scrolled;
  const HeaderCTA({super.key, required this.scrolled});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // This triggers the KSH 54 voice call consultation
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: scrolled ? const Color(0xFF2D7D46) : Colors.white,
        foregroundColor: scrolled ? Colors.white : const Color(0xFF2D7D46),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text("PIGIA TELMED", style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class FooterColumn extends StatelessWidget {
  final String title;
  final List<String> items;
  const FooterColumn(this.title, this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ...items.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(e, style: const TextStyle(color: Colors.white24)),
            )),
      ],
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
          // Add navigation or call logic here
        },
        child: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          decoration: BoxDecoration(
            color: primary ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: primary ? null : Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconUrl != null) Image.network(iconUrl!, height: 24, width: 24),
              if (iconData != null)
                Icon(
                  iconData,
                  color: primary ? Colors.white : const Color(0xFFF9A825),
                  size: 22,
                ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}