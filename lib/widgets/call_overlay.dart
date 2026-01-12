import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../services/signaling.dart';

class CallOverlay extends StatefulWidget {
  const CallOverlay({super.key});

  @override
  State<CallOverlay> createState() => _CallOverlayState();
}

class _CallOverlayState extends State<CallOverlay> {
  // WebRTC & Signaling Objects
  final Signaling _signaling = Signaling();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  // State Management
  bool _isPaying = false;
  bool _paymentConfirmed = false;
  bool _callConnecting = false;
  String? _roomId; // To store the created room ID

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    // Listen for the remote doctor's stream via the signaling service
    _signaling.onAddRemoteStream = (stream) {
      _remoteRenderer.srcObject = stream;
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    // IMPORTANT: Hang up and dispose renderers when widget is closed
    _signaling.hangUp(_localRenderer);
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  /// Initiates M-Pesa KSH 54 Payment
  Future<void> _processPayment() async {
    setState(() => _isPaying = true);

    // Simulation of M-Pesa STK Push logic
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _isPaying = false;
        _paymentConfirmed = true;
      });
      _startWebRTCCall();
    }
  }

  /// Starts WebRTC signaling after payment success
  Future<void> _startWebRTCCall() async {
    setState(() => _callConnecting = true);
    try {
      // 1. Open local camera/mic
      await _signaling.openUserMedia(_localRenderer, _remoteRenderer);
      
      // 2. Create the signaling room
      _roomId = await _signaling.createRoom(_remoteRenderer);
      
      // DEBUG: Print the room ID so you can test connection (e.g., share with 'doctor')
      print("TELMED ROOM ID CREATED: $_roomId");

      if (mounted) setState(() => _callConnecting = false);
    } catch (e) {
      debugPrint("Call failed: $e");
      if (mounted) setState(() => _callConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      body: Stack(
        children: [
          // 1. Remote Video Layer (Full Screen)
          if (_paymentConfirmed && !_callConnecting)
            Positioned.fill(child: RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)),

          // 2. Payment Prompt Layer
          if (!_paymentConfirmed) _buildPaymentUI(),

          // 3. Connection Status Layer
          if (_callConnecting)
            const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),

          // 4. Local Preview (Floating) & Controls
          if (_paymentConfirmed && !_callConnecting) ...[
            _buildLocalThumbnail(),
            _buildActionControls(),
            _buildRoomIdDisplay(), // Temporary Helper for testing
          ],

          // Close Overlay Button (Top Right)
          Positioned(
            top: 40,
            right: 30,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () {
                 _signaling.hangUp(_localRenderer);
                 Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper to show Room ID on screen so you can copy it easily for testing
  Widget _buildRoomIdDisplay() {
    return Positioned(
      top: 40,
      left: 30,
      child: SelectableText(
        "Room ID: ${_roomId ?? 'Generating...'}",
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
    );
  }

  Widget _buildPaymentUI() {
    return Center(
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.security_rounded, size: 60, color: Color(0xFF2D7D46)),
            const SizedBox(height: 20),
            Text("Secure Voice Session", style: GoogleFonts.plusJakartaSans(fontSize: 16, color: Colors.grey)),
            Text("KSH 54", style: GoogleFonts.plusJakartaSans(fontSize: 48, fontWeight: FontWeight.w900, color: const Color(0xFF1B4D2C))),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isPaying ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9A825),
                minimumSize: const Size(double.infinity, 65),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: _isPaying
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("PAY & CONNECT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalThumbnail() {
    return Positioned(
      bottom: 140,
      right: 25,
      child: Container(
        width: 120,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white38, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
        ),
      ),
    );
  }

  Widget _buildActionControls() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _circleBtn(Icons.mic, Colors.white10),
          const SizedBox(width: 25),
          // RED HANGUP BUTTON
          _circleBtn(Icons.call_end, Colors.red, isEnd: true, onTap: () {
            _signaling.hangUp(_localRenderer);
            Navigator.pop(context);
          }),
          const SizedBox(width: 25),
          _circleBtn(Icons.videocam, Colors.white10),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, Color color, {bool isEnd = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }
}