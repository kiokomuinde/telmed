import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

typedef StreamHandler = void Function(MediaStream stream);
typedef ConnectionHandler = void Function(RTCPeerConnectionState state);
typedef VoidCallback = void Function();

class Signaling {
  // Use public Google STUN servers for network discovery
  Map<String, dynamic> configuration = {
    'iceServers': [
      {'urls': ['stun:stun1.l.google.com:19302', 'stun:stun2.l.google.com:19302']}
    ]
  };

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId;
  
  StreamHandler? onAddRemoteStream;
  ConnectionHandler? onConnectionState;
  VoidCallback? onCallEnded;

  // --- QUEUE SYSTEM: PREVENTS CRASHES ---
  List<RTCIceCandidate> _candidateQueue = [];
  bool _isRemoteDescriptionSet = false;

  Stream<QuerySnapshot> getRoomsStream() {
    return FirebaseFirestore.instance.collection('rooms').snapshots();
  }

  // --- 1. CALLER (Patient) LOGIC ---
  Future<String> createRoom(RTCVideoRenderer remoteRenderer) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc();

    print('Create PeerConnection with configuration: $configuration');
    peerConnection = await createPeerConnection(configuration);
    registerPeerConnectionListeners();

    // Add Local Media Tracks
    if (localStream != null) {
      localStream!.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });
    }

    // 1. Listen for local candidates and upload them
    var callerCandidatesCollection = roomRef.collection('callerCandidates');
    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      print('Got candidate: ${candidate.toMap()}');
      callerCandidatesCollection.add(candidate.toMap());
    };

    // 2. Create Offer
    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};
    await roomRef.set(roomWithOffer);
    roomId = roomRef.id;

    // 3. Listen for Remote Answer
    roomRef.snapshots().listen((snapshot) async {
      // HANDLE CALL ENDED BY DOCTOR
      if (!snapshot.exists) {
        if (onCallEnded != null) onCallEnded!();
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>?;
      if (peerConnection?.getRemoteDescription() == null && data != null && data['answer'] != null) {
        var answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
        
        print("Someone answered the call! Setting remote description.");
        await peerConnection?.setRemoteDescription(answer);
        
        // --- CRITICAL FIX: FLUSH QUEUE ---
        _isRemoteDescriptionSet = true;
        _processCandidateQueue();
      }
    });

    // 4. Listen for Remote Candidates (Callee)
    roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          print('Got remote candidate: ${data['candidate']}');
          
          var candidate = RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
          _addCandidate(candidate); // USE HELPER
        }
      }
    });

    return roomId!;
  }

  // --- 2. JOINER (Doctor) LOGIC ---
  Future<void> joinRoom(String roomId, RTCVideoRenderer remoteVideo) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc(roomId);
    var roomSnapshot = await roomRef.get();

    if (roomSnapshot.exists) {
      print('Create PeerConnection with configuration: $configuration');
      peerConnection = await createPeerConnection(configuration);
      registerPeerConnectionListeners();

      if (localStream != null) {
        localStream!.getTracks().forEach((track) {
          peerConnection?.addTrack(track, localStream!);
        });
      }

      // 1. Listen for local candidates and upload them
      var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
      peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
        calleeCandidatesCollection.add(candidate.toMap());
      };

      // 2. Listen for Call End (Patient hung up)
      roomRef.snapshots().listen((snapshot) {
         if (!snapshot.exists) {
           if (onCallEnded != null) onCallEnded!();
         }
      });

      // 3. Process Offer (Remote Description)
      var data = roomSnapshot.data() as Map<String, dynamic>;
      var offer = data['offer'];
      
      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
      
      // --- CRITICAL FIX: FLUSH QUEUE ---
      _isRemoteDescriptionSet = true;
      _processCandidateQueue();

      // 4. Create Answer
      var answer = await peerConnection!.createAnswer();
      await peerConnection!.setLocalDescription(answer);

      Map<String, dynamic> roomWithAnswer = {
        'answer': {'type': answer.type, 'sdp': answer.sdp}
      };
      await roomRef.update(roomWithAnswer);

      // 5. Listen for Remote Candidates (Caller)
      roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
        for (var document in snapshot.docChanges) {
          var data = document.doc.data() as Map<String, dynamic>;
          var candidate = RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
          _addCandidate(candidate); // USE HELPER
        }
      });
    }
  }

  // --- HELPER: SAFE CANDIDATE ADDING ---
  void _addCandidate(RTCIceCandidate candidate) {
    if (_isRemoteDescriptionSet && peerConnection != null) {
      peerConnection!.addCandidate(candidate);
    } else {
      _candidateQueue.add(candidate);
    }
  }

  void _processCandidateQueue() {
    for (var candidate in _candidateQueue) {
      peerConnection?.addCandidate(candidate);
    }
    _candidateQueue.clear();
  }

  // --- 3. MEDIA & UTILS ---

  Future<void> openUserMedia(RTCVideoRenderer localVideo, RTCVideoRenderer remoteVideo) async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {'facingMode': 'user', 'width': 1280, 'height': 720}
    };

    try {
      var stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      localVideo.srcObject = stream;
      localStream = stream;
    } catch (e) {
      print("Error opening user media: $e");
      rethrow;
    }
  }

  void toggleMic() {
    if (localStream != null && localStream!.getAudioTracks().isNotEmpty) {
      bool enabled = localStream!.getAudioTracks()[0].enabled;
      localStream!.getAudioTracks()[0].enabled = !enabled;
    }
  }

  void toggleCamera() {
    if (localStream != null && localStream!.getVideoTracks().isNotEmpty) {
      bool enabled = localStream!.getVideoTracks()[0].enabled;
      localStream!.getVideoTracks()[0].enabled = !enabled;
    }
  }

  Future<void> hangUp(RTCVideoRenderer localVideo, {String? roomId}) async {
    if (localVideo.srcObject != null) {
      localVideo.srcObject!.getTracks().forEach((track) => track.stop());
    }
    if (remoteStream != null) {
      remoteStream!.getTracks().forEach((track) => track.stop());
    }
    if (peerConnection != null) {
      peerConnection!.close();
    }

    // Delete room to signal "Call Ended"
    if (roomId != null) {
      try {
        await FirebaseFirestore.instance.collection('rooms').doc(roomId).delete();
      } catch (e) {
        print("Error deleting room: $e");
      }
    }
    
    localStream?.dispose();
    remoteStream?.dispose();
    localStream = null;
    remoteStream = null;
    _isRemoteDescriptionSet = false;
    _candidateQueue.clear();
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state change: $state');
      if (onConnectionState != null) onConnectionState!(state);
    };
    
    peerConnection?.onTrack = (RTCTrackEvent event) {
      print('Track received: ${event.streams.length} streams');
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        if (onAddRemoteStream != null) onAddRemoteStream!(remoteStream!);
      }
    };
  }
}