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
  bool _isProcessing = false; // PREVENTS DOUBLE CLICKS
  
  String? _localMediaError;
  String _connectionStatus = "Ready"; 

  @override
  void initState() {
    super.initState();
    _initRenderers();

    _signaling.onCallEnded = () {
      if (mounted && _isJoined) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Call ended by patient"), backgroundColor: Colors.red),
         );
         _signaling.hangUp(_localRenderer);
         Navigator.pop(context);
      }
    };
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    
    _signaling.onAddRemoteStream = (stream) {
      _remoteRenderer.srcObject = stream;
      if (mounted) setState(() {});
    };

    _signaling.onConnectionState = (state) {
      if (mounted) setState(() => _connectionStatus = state.toString().split('.').last);
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("DOCTOR PORTAL", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 2)),
              Text("Status: $_connectionStatus", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  Widget _buildQueueList() {
    return Center(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white12)),
        child: Column(
          children: [
            const Icon(Icons.medical_services, color: Color(0xFFF9A825), size: 50),
            const SizedBox(height: 15),
            Text("Waiting Patients", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _signaling.getRoomsStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF2D7D46)));
                  var queue = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return data['offer'] != null && data['answer'] == null;
                  }).toList();
                  
                  if (queue.isEmpty) return const Center(child: Text("No patients waiting", style: TextStyle(color: Colors.white38)));

                  return ListView.builder(
                    itemCount: queue.length,
                    itemBuilder: (context, index) {
                      var room = queue[index];
                      return ListTile(
                        leading: const Icon(Icons.person, color: Colors.white),
                        title: Text("Patient #${index + 1}", style: const TextStyle(color: Colors.white)),
                        trailing: ElevatedButton(
                          onPressed: _isProcessing ? null : () => _joinRoom(room.id),
                          child: _isProcessing && _isJoined == false 
                             ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                             : const Text("ACCEPT"),
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

  Future<void> _joinRoom(String roomId) async {
    if (_isProcessing) return; // PREVENT DOUBLE CLICK
    
    setState(() {
      _isProcessing = true;
      _localMediaError = null;
    });

    try {
      await _signaling.openUserMedia(_localRenderer, _remoteRenderer);
      await _signaling.joinRoom(roomId, _remoteRenderer);
      setState(() => _isJoined = true);
    } catch (e) {
      setState(() {
        _localMediaError = e.toString();
        // Try joining anyway (Receive Only mode)
        _signaling.joinRoom(roomId, _remoteRenderer);
        _isJoined = true;
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Widget _buildCallUI() {
    bool hasRemoteVideo = _remoteRenderer.srcObject != null && _remoteRenderer.srcObject!.getVideoTracks().isNotEmpty;

    return Stack(
      children: [
        RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
        
        if (!hasRemoteVideo)
          Container(
            color: Colors.black87,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.signal_wifi_off, color: Colors.orange, size: 50),
                  const SizedBox(height: 20),
                  Text("NO PATIENT VIDEO", style: GoogleFonts.plusJakartaSans(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 10),
                  Text("Connection: $_connectionStatus", style: const TextStyle(color: Colors.white70)),
                  if (_localMediaError != null)
                     Text("Your Cam: $_localMediaError", style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ],
              ),
            ),
          ),
          
        Positioned(
          right: 30, top: 30,
          child: Container(
            width: 180, height: 260,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24, width: 2)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _localMediaError != null
                 ? Container(color: Colors.red.withOpacity(0.3), child: const Center(child: Icon(Icons.warning, color: Colors.red)))
                 : RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
            ),
          ),
        ),
        
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 50),
            child: IconButton(
               icon: const Icon(Icons.call_end, color: Colors.red, size: 40), 
               onPressed: () {
                 _signaling.hangUp(_localRenderer);
                 Navigator.pop(context);
               }
            ),
          ),
        ),
      ],
    );
  }
}