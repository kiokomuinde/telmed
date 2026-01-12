import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
// FIX: Using full package import path
import 'package:telmed/widgets/call_overlay.dart'; 

class TelmedNavBar extends StatelessWidget {
  final double navOpacity;
  const TelmedNavBar({super.key, required this.navOpacity});

  @override
  Widget build(BuildContext context) {
    final bool isScrolled = navOpacity > 0.5;
    return Positioned(
      top: 0, left: 0, right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10 * navOpacity, sigmaY: 10 * navOpacity),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(navOpacity * 0.8),
              border: Border(bottom: BorderSide(color: isScrolled ? Colors.black12 : Colors.transparent)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  const BrandLogo(isDark: true), // Using const for static widget
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

class HeaderCTA extends StatelessWidget {
  final bool scrolled;
  const HeaderCTA({super.key, required this.scrolled});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // FIX: Removed 'const' because CallOverlay is a runtime widget with WebRTC
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => CallOverlay(), 
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: scrolled ? const Color(0xFF2D7D46) : Colors.white,
        foregroundColor: scrolled ? Colors.white : const Color(0xFF2D7D46),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text("PIGIA TELMED", style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

// ... (Rest of common_widget.dart remains similar, ensure BrandLogo and NavLinks are present)
class BrandLogo extends StatelessWidget {
  final bool isDark;
  const BrandLogo({super.key, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.health_and_safety, color: Color(0xFFF9A825), size: 30),
        const SizedBox(width: 12),
        Text("TELMED", style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? const Color(0xFF1B4D2C) : Colors.black)),
      ],
    );
  }
}

class NavLinks extends StatelessWidget {
  final bool isDark;
  const NavLinks({super.key, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: isDark ? Colors.black87 : Colors.white70, fontWeight: FontWeight.w600);
    return Row(children: [Text("Voice Call", style: style), const SizedBox(width: 30), Text("Homecare", style: style), const SizedBox(width: 30), Text("Our Clinics", style: style)]);
  }
}

class ActionBtn extends StatelessWidget {
  final String label;
  final String? iconUrl;
  final IconData? iconData;
  final Color color;
  final bool primary;

  const ActionBtn({super.key, required this.label, this.iconUrl, this.iconData, required this.color, required this.primary});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (label.contains("Call") || label.contains("Pigia")) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => CallOverlay(),
            );
          }
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
              if (iconData != null) Icon(iconData, color: primary ? Colors.white : const Color(0xFFF9A825), size: 22),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
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
      padding: const EdgeInsets.all(60),
      color: const Color(0xFF0F172A),
      child: const Center(child: Text("© 2026 Telmed Health", style: TextStyle(color: Colors.white24))),
    );
  }
}