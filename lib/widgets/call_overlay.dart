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
  final Signaling _signaling = Signaling();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  // State Management
  bool _isPaying = false;
  bool _paymentConfirmed = false;
  bool _callConnecting = false;
  
  // Permission States
  bool _hasPermissions = false;
  String? _permissionError; // To show specific errors to user
  String? _roomId;

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    _signaling.onAddRemoteStream = (stream) {
      _remoteRenderer.srcObject = stream;
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    _signaling.hangUp(_localRenderer);
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  /// 1. Secure Flow: Check Permissions -> Then Pay -> Then Connect
  Future<void> _validateAndProcessPayment() async {
    setState(() {
      _isPaying = true;
      _permissionError = null;
    });

    try {
      // Step A: Request Permissions FIRST. 
      // If the user blocks this, the catch block handles it.
      await _signaling.openUserMedia(_localRenderer, _remoteRenderer);
      
      if (mounted) {
        setState(() => _hasPermissions = true);
      }

      // Step B: If permissions passed, Simulate Payment
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        setState(() {
          _isPaying = false;
          _paymentConfirmed = true;
        });
        
        // Step C: Start the signaling now that we have the stream
        _startWebRTCCall();
      }

    } catch (e) {
      // Handle Permission Errors gracefully
      debugPrint("Permission Error: $e");
      if (mounted) {
        setState(() {
          _isPaying = false;
          // Determine if it was a permission error
          String errorStr = e.toString();
          if (errorStr.contains('NotAllowedError') || errorStr.contains('PermissionDeniedError')) {
             _permissionError = "Camera blocked! Please click the lock icon 🔒 in your browser address bar to allow access.";
          } else if (errorStr.contains('NotFoundError')) {
             _permissionError = "No camera or microphone found on this device.";
          } else {
             _permissionError = "Connection failed: Please allow camera access to continue.";
          }
        });
      }
    }
  }

  Future<void> _startWebRTCCall() async {
    setState(() => _callConnecting = true);
    try {
      // We already opened user media in the previous step, so we just create room
      _roomId = await _signaling.createRoom(_remoteRenderer);
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
          // 1. Remote Video Layer
          if (_paymentConfirmed && !_callConnecting)
            Positioned.fill(child: RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)),

          // 2. Payment & Permission UI
          if (!_paymentConfirmed) _buildPaymentUI(),

          // 3. Loader
          if (_callConnecting)
            const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),

          // 4. Local Preview (Floating) - Show this AS SOON as we have permissions (even during payment)
          if (_hasPermissions) 
            _buildLocalThumbnail(),

          // 5. Controls
          if (_paymentConfirmed && !_callConnecting) ...[
            _buildActionControls(),
            _buildRoomIdDisplay(),
          ],

          // Close Button
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
            
            // ERROR MESSAGE DISPLAY
            if (_permissionError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200)
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_permissionError!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                  ],
                ),
              ),

            ElevatedButton(
              // Change action to Validate Permissions first
              onPressed: _isPaying ? null : _validateAndProcessPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: _permissionError != null ? Colors.redAccent : const Color(0xFFF9A825),
                minimumSize: const Size(double.infinity, 65),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: _isPaying
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                         SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                         SizedBox(width: 15),
                         Text("Accessing Camera...", style: TextStyle(color: Colors.white))
                      ],
                    )
                  : Text(_permissionError != null ? "RETRY ACCESS" : "PAY & CONNECT", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
          color: Colors.black54,
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