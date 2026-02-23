import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

typedef StreamHandler = void Function(MediaStream stream);
typedef ConnectionHandler = void Function(RTCPeerConnectionState state);
typedef VoidCallback = void Function();

class Signaling {
  Map<String, dynamic> configuration = {
    'iceServers': [
      {'urls': ['stun:stun1.l.google.com:19302', 'stun:stun2.l.google.com:19302']}
    ]
  };

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId; // Class-level roomId
  
  StreamHandler? onAddRemoteStream;
  ConnectionHandler? onConnectionState;
  VoidCallback? onCallEnded;
  VoidCallback? onCallAccepted; // NEW: Callback for immediate UI updates

  List<RTCIceCandidate> _candidateQueue = [];
  bool _isRemoteDescriptionSet = false;

  Stream<QuerySnapshot> getRoomsStream() {
    return FirebaseFirestore.instance.collection('rooms').snapshots();
  }

  // --- 1. CALLER (Patient) ---
  Future<String> createRoom(RTCVideoRenderer remoteRenderer) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc();

    peerConnection = await createPeerConnection(configuration);
    registerPeerConnectionListeners();

    if (localStream != null) {
      localStream!.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });
    }

    var callerCandidatesCollection = roomRef.collection('callerCandidates');
    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      callerCandidatesCollection.add(candidate.toMap());
    };

    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};
    await roomRef.set(roomWithOffer);
    
    roomId = roomRef.id; // Store in class variable

    roomRef.snapshots().listen((snapshot) async {
      if (!snapshot.exists) {
        if (onCallEnded != null) onCallEnded!();
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>?;
      // GUARD CLAUSE: Only set answer if we are actually waiting for one
      bool isWaitingForAnswer = peerConnection?.signalingState == RTCSignalingState.RTCSignalingStateHaveLocalOffer;
      
      if (isWaitingForAnswer && data != null && data['answer'] != null) {
        // NEW: Immediately notify UI that the doctor accepted the call
        if (onCallAccepted != null) onCallAccepted!();

        var answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
        await peerConnection?.setRemoteDescription(answer);
        _isRemoteDescriptionSet = true;
        _processCandidateQueue();
      }
    });

    roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          var candidate = RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
          _addCandidate(candidate);
        }
      }
    });

    return roomId!;
  }

  // --- 2. JOINER (Doctor) ---
  Future<void> joinRoom(String incomingRoomId, RTCVideoRenderer remoteVideo) async {
    roomId = incomingRoomId; // Store in class variable so Doctor can also hang up effectively
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc(roomId);
    var roomSnapshot = await roomRef.get();

    if (roomSnapshot.exists) {
      peerConnection = await createPeerConnection(configuration);
      registerPeerConnectionListeners();

      if (localStream != null) {
        localStream!.getTracks().forEach((track) {
          peerConnection?.addTrack(track, localStream!);
        });
      }

      var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
      peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
        calleeCandidatesCollection.add(candidate.toMap());
      };

      roomRef.snapshots().listen((snapshot) {
         if (!snapshot.exists) {
           if (onCallEnded != null) onCallEnded!();
         }
      });

      var data = roomSnapshot.data() as Map<String, dynamic>;
      
      // GUARD: Check if we are already connected to avoid "stable" state errors
      if (peerConnection?.signalingState != RTCSignalingState.RTCSignalingStateStable) {
        var offer = data['offer'];
        await peerConnection?.setRemoteDescription(
          RTCSessionDescription(offer['sdp'], offer['type']),
        );
        _isRemoteDescriptionSet = true;
        _processCandidateQueue();

        var answer = await peerConnection!.createAnswer();
        await peerConnection!.setLocalDescription(answer);

        Map<String, dynamic> roomWithAnswer = {
          'answer': {'type': answer.type, 'sdp': answer.sdp}
        };
        await roomRef.update(roomWithAnswer);
      }

      roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
        for (var document in snapshot.docChanges) {
          var data = document.doc.data() as Map<String, dynamic>;
          var candidate = RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
          _addCandidate(candidate);
        }
      });
    }
  }

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
      print("Signaling: Error opening user media: $e");
      // Allow proceeding even without local media (Receive only)
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
    // 1. Database Cleanup First: Ensure UI updates immediately
    String? targetRoomId = roomId ?? this.roomId;

    if (targetRoomId != null) {
      try {
        var db = FirebaseFirestore.instance;
        var roomRef = db.collection('rooms').doc(targetRoomId);
        
        // Wipe subcollections first (Prevents Firestore 'ghost' documents)
        var callerCandidates = await roomRef.collection('callerCandidates').get();
        for (var doc in callerCandidates.docs) {
          await doc.reference.delete();
        }

        var calleeCandidates = await roomRef.collection('calleeCandidates').get();
        for (var doc in calleeCandidates.docs) {
          await doc.reference.delete();
        }

        // Wipe the actual room document
        await roomRef.delete();
        print("Signaling: Room $targetRoomId successfully deleted from database.");
      } catch (e) {
        print("Signaling: Error deleting room from database: $e");
      }
    }

    // 2. Hardware Cleanup: Wrapped in try-catches to prevent function failures
    try {
      if (localVideo.srcObject != null) {
        localVideo.srcObject!.getTracks().forEach((track) => track.stop());
      }
      localStream?.getTracks().forEach((track) => track.stop());
    } catch(e) { print("Error stopping local tracks: $e"); }

    try {
      remoteStream?.getTracks().forEach((track) => track.stop());
    } catch(e) { print("Error stopping remote tracks: $e"); }

    // 3. Close the WebRTC PeerConnection safely
    try {
      if (peerConnection != null) {
        await peerConnection!.close();
      }
    } catch(e) { print("Error closing peer connection: $e"); }

    // 4. Memory Cleanup
    localStream?.dispose();
    remoteStream?.dispose();
    localStream = null;
    remoteStream = null;
    peerConnection = null;
    this.roomId = null;
    _isRemoteDescriptionSet = false;
    _candidateQueue.clear();
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Signaling: Connection state change: $state');
      if (onConnectionState != null) onConnectionState!(state);
    };
    
    peerConnection?.onTrack = (RTCTrackEvent event) {
      print('Signaling: Track received: ${event.streams.length} streams');
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        if (onAddRemoteStream != null) onAddRemoteStream!(remoteStream!);
      }
    };
  }
}