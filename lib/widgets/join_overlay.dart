import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../services/signaling.dart';

class JoinOverlay extends StatefulWidget {
  const JoinOverlay({super.key});

  @override
  State<JoinOverlay> createState() => _JoinOverlayState();
}

class _JoinOverlayState extends State<JoinOverlay> {
  final Signaling _signaling = Signaling();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isJoined = false;
  bool _isMicOn = true;
  bool _isCameraOn = true;

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
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: const Color(0xFF0F172A).withOpacity(0.9),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isJoined ? _buildCallUI() : _buildQueueList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("DOCTOR PORTAL", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 2)),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  // --- NEW: REPLACED MANUAL ENTRY WITH QUEUE LIST ---
  Widget _buildQueueList() {
    return Center(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white10, 
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white12)
        ),
        child: Column(
          children: [
            const Icon(Icons.medical_services, color: Color(0xFFF9A825), size: 50),
            const SizedBox(height: 15),
            Text(
              "Waiting Patients", 
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 5),
            const Text(
              "Select a patient from the queue to start consultation.",
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _signaling.getRoomsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading queue', style: TextStyle(color: Colors.redAccent)));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF2D7D46)));
                  }

                  // FILTER: Only show rooms that are created (have offer) but NOT answered yet
                  var queue = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return data['offer'] != null && data['answer'] == null;
                  }).toList();

                  if (queue.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.coffee, size: 60, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 20),
                          const Text("No patients waiting", style: TextStyle(color: Colors.white38, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: queue.length,
                    itemBuilder: (context, index) {
                      var room = queue[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white12)
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(color: Color(0xFF2D7D46), shape: BoxShape.circle),
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            "Patient #${index + 1}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "ID: ...${room.id.substring(room.id.length - 6)}", // Showing last 6 chars for brevity
                            style: const TextStyle(color: Colors.white54, fontFamily: 'monospace'),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _joinRoom(room.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0F172A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                            ),
                            child: const Text("ACCEPT", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER TO JOIN ROOM ---
  Future<void> _joinRoom(String roomId) async {
    // Show simple loader or transition if needed
    try {
      await _signaling.openUserMedia(_localRenderer, _remoteRenderer);
      await _signaling.joinRoom(roomId, _remoteRenderer);
      setState(() => _isJoined = true);
    } catch (e) {
      print("Error joining room: $e");
    }
  }

  Widget _buildCallUI() {
    return Stack(
      children: [
        RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
        Positioned(
          right: 30, top: 30,
          child: Container(
            width: 180, height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
            ),
          ),
        ),
        _buildControls(),
      ],
    );
  }

  Widget _buildControls() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 50),
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
              icon: Icons.call_end,
              bgColor: Colors.red,
              iconColor: Colors.white,
              onTap: () {
                _signaling.hangUp(_localRenderer);
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
      ),
    );
  }

  Widget _circleBtn({required IconData icon, required Color bgColor, required Color iconColor, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor, border: Border.all(color: Colors.white10)),
        child: Icon(icon, color: iconColor, size: 28),
      ),
    );
  }
}