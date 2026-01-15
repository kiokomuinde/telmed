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

  // Logic State
  bool _isPaying = false;
  bool _paymentConfirmed = false;
  bool _callConnecting = false;
  bool _hasPermissions = false;
  
  // Media State
  bool _isMicOn = true;
  bool _isCameraOn = true;

  // DEBUGGING STATES
  String? _localMediaError; // "Camera not found", etc.
  String _connectionStatus = "Initializing"; // "Connected", "Failed", etc.
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

    // Listen for connection health
    _signaling.onConnectionState = (state) {
      if (mounted) {
        setState(() {
          _connectionStatus = state.toString().split('.').last; // e.g., "connected", "failed"
        });
      }
    };
  }

  @override
  void dispose() {
    _signaling.hangUp(_localRenderer, roomId: _roomId);
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> _validateAndProcessPayment() async {
    setState(() {
      _isPaying = true;
      _localMediaError = null;
    });

    try {
      await _signaling.openUserMedia(_localRenderer, _remoteRenderer);
      
      if (mounted) {
        setState(() => _hasPermissions = true);
      }

      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        setState(() {
          _isPaying = false;
          _paymentConfirmed = true;
        });
        _startWebRTCCall();
      }

    } catch (e) {
      debugPrint("Permission Error: $e");
      if (mounted) {
        setState(() {
          _isPaying = false;
          // Capture friendly error messages
          String errorStr = e.toString();
          if (errorStr.contains('NotFoundError')) {
             _localMediaError = "Hardware Missing: No Camera/Mic found.";
          } else if (errorStr.contains('NotAllowedError') || errorStr.contains('PermissionDeniedError')) {
             _localMediaError = "Permission Denied: Click lock icon 🔒 to allow.";
          } else {
             _localMediaError = "Media Error: $e";
          }
        });
      }
    }
  }

  Future<void> _startWebRTCCall() async {
    setState(() => _callConnecting = true);
    try {
      _roomId = await _signaling.createRoom(_remoteRenderer);
      if (mounted) setState(() => _callConnecting = false);
    } catch (e) {
      debugPrint("Call failed: $e");
      if (mounted) {
        setState(() {
          _callConnecting = false;
          _connectionStatus = "Room Creation Failed: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      body: Stack(
        children: [
          // 1. Remote Video Layer (Big Screen)
          if (_paymentConfirmed && !_callConnecting)
            Positioned.fill(
              child: _buildRemoteView(),
            ),

          // 2. Payment UI
          if (!_paymentConfirmed) _buildPaymentUI(),

          // 3. Loader
          if (_callConnecting)
            const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),

          // 4. Local Preview (Floating)
          // Always show this if we tried to get permissions, even if it failed (to show error)
          if (_hasPermissions || _localMediaError != null) 
            _buildLocalThumbnail(),

          // 5. Controls
          if (_paymentConfirmed && !_callConnecting) ...[
            _buildActionControls(),
            _buildRoomIdDisplay(),
          ],

          Positioned(
            top: 40, right: 30,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () {
                 _signaling.hangUp(_localRenderer, roomId: _roomId);
                 Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW: DEBUGGING REMOTE VIEW ---
  Widget _buildRemoteView() {
    bool hasRemoteVideo = _remoteRenderer.srcObject != null && 
                          _remoteRenderer.srcObject!.getVideoTracks().isNotEmpty;
    bool hasRemoteAudio = _remoteRenderer.srcObject != null && 
                          _remoteRenderer.srcObject!.getAudioTracks().isNotEmpty;

    return Stack(
      children: [
        // The Video
        RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
        
        // The Debug Overlay (Only shows if there is an issue)
        if (!hasRemoteVideo)
          Container(
            color: Colors.black87,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam_off, color: Colors.redAccent, size: 50),
                  const SizedBox(height: 20),
                  Text(
                    "REMOTE VIDEO MISSING",
                    style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Status: $_connectionStatus",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Waiting for doctor's stream...",
                    style: TextStyle(color: Colors.white38),
                  ),
                ],
              ),
            ),
          ),
        
        // Audio Warning (Overlay at top)
        if (hasRemoteVideo && !hasRemoteAudio)
           Positioned(
             top: 100, left: 0, right: 0,
             child: Center(
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                 child: const Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Icon(Icons.mic_off, color: Colors.orange, size: 16),
                     SizedBox(width: 8),
                     Text("Remote Audio Missing", style: TextStyle(color: Colors.white)),
                   ],
                 ),
               ),
             ),
           ),
      ],
    );
  }

  Widget _buildRoomIdDisplay() {
    return Positioned(
      top: 40, left: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            "Room ID: ${_roomId ?? 'Generating...'}",
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          // Connection Debug Text
          Text(
            "Conn: $_connectionStatus",
            style: TextStyle(
              color: _connectionStatus == 'connected' ? Colors.green : Colors.orange, 
              fontSize: 10
            ),
          ),
        ],
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
            Text("KSH 54", style: GoogleFonts.plusJakartaSans(fontSize: 48, fontWeight: FontWeight.w900, color: const Color(0xFF1B4D2C))),
            const SizedBox(height: 30),
            
            // SHOW LOCAL ERRORS HERE
            if (_localMediaError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_localMediaError!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                  ],
                ),
              ),

            ElevatedButton(
              onPressed: _isPaying ? null : _validateAndProcessPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: _localMediaError != null ? Colors.redAccent : const Color(0xFFF9A825),
                minimumSize: const Size(double.infinity, 65),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: _isPaying
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_localMediaError != null ? "RETRY ACCESS" : "PAY & CONNECT", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalThumbnail() {
    return Positioned(
      bottom: 140, right: 25,
      child: Container(
        width: 120, height: 180,
        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white38, width: 2)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: _localMediaError != null
              ? Container(
                  color: Colors.red.withOpacity(0.2),
                  child: const Center(child: Icon(Icons.no_photography, color: Colors.red, size: 30)),
                )
              : RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
        ),
      ),
    );
  }

  Widget _buildActionControls() {
    return Positioned(
      bottom: 40, left: 0, right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _circleBtn(
            icon: _isMicOn ? Icons.mic : Icons.mic_off, 
            bgColor: _isMicOn ? Colors.white10 : Colors.white, 
            iconColor: _isMicOn ? Colors.white : Colors.black,
            onTap: () {
              _signaling.toggleMic();
              setState(() => _isMicOn = !_isMicOn);
            }
          ),
          const SizedBox(width: 25),
          _circleBtn(
            icon: Icons.call_end, bgColor: Colors.red, iconColor: Colors.white,
            onTap: () {
              _signaling.hangUp(_localRenderer, roomId: _roomId);
              Navigator.pop(context);
            }
          ),
          const SizedBox(width: 25),
          _circleBtn(
            icon: _isCameraOn ? Icons.videocam : Icons.videocam_off, 
            bgColor: _isCameraOn ? Colors.white10 : Colors.white, 
            iconColor: _isCameraOn ? Colors.white : Colors.black,
            onTap: () {
              _signaling.toggleCamera();
              setState(() => _isCameraOn = !_isCameraOn);
            }
          ),
        ],
      ),
    );
  }

  Widget _circleBtn({required IconData icon, required Color bgColor, required Color iconColor, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 30),
      ),
    );
  }
}