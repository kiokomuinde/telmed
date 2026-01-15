import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

typedef StreamHandler = void Function(MediaStream stream);

class Signaling {
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

  Stream<QuerySnapshot> getRoomsStream() {
    return FirebaseFirestore.instance.collection('rooms').snapshots();
  }

  // --- 1. SESSION CONTROL ---

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
    roomId = roomRef.id;

    roomRef.snapshots().listen((snapshot) async {
      final data = snapshot.data() as Map<String, dynamic>?;
      if (peerConnection?.getRemoteDescription() == null && data != null && data['answer'] != null) {
        var answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
        await peerConnection?.setRemoteDescription(answer);
      }
    });

    roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          peerConnection!.addCandidate(RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']));
        }
      }
    });

    return roomId!;
  }

  Future<void> joinRoom(String roomId, RTCVideoRenderer remoteVideo) async {
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
      peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        calleeCandidatesCollection.add(candidate.toMap());
      };

      // --- FIXED: Standard Track Handling ---
      peerConnection?.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          remoteStream = event.streams[0];
          if (onAddRemoteStream != null) {
            onAddRemoteStream!(remoteStream!);
          }
        }
      };
      // -------------------------------------

      var data = roomSnapshot.data() as Map<String, dynamic>;
      var offer = data['offer'];
      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );

      var answer = await peerConnection!.createAnswer();
      await peerConnection!.setLocalDescription(answer);

      Map<String, dynamic> roomWithAnswer = {
        'answer': {'type': answer.type, 'sdp': answer.sdp}
      };

      await roomRef.update(roomWithAnswer);

      roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
        for (var document in snapshot.docChanges) {
          var data = document.doc.data() as Map<String, dynamic>;
          peerConnection!.addCandidate(
            RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']),
          );
        }
      });
    }
  }

  // --- 2. MEDIA HANDLING ---

  Future<void> openUserMedia(RTCVideoRenderer localVideo, RTCVideoRenderer remoteVideo) async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 1280},
        'height': {'ideal': 720}
      }
    };

    try {
      var stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      localVideo.srcObject = stream;
      localStream = stream;
    } catch (e) {
      print("WEB_RTC Error: $e");
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
      List<MediaStreamTrack> tracks = localVideo.srcObject!.getTracks();
      for (var track in tracks) {
        track.stop();
      }
    }
    
    if (remoteStream != null) {
      remoteStream!.getTracks().forEach((track) => track.stop());
    }
    
    if (peerConnection != null) {
      peerConnection!.close();
    }

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
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      print('WEB_RTC Connection State: $state');
    };
    
    peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        if (onAddRemoteStream != null) onAddRemoteStream!(remoteStream!);
      }
    };
  }
}