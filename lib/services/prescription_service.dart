import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PrescriptionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Saves or updates a prescription in Firestore linked to the unique [roomId].
  Future<bool> savePrescription({
    required String roomId,
    required String patientAge,
    required List<dynamic> medications, 
    required String doctorNotes,
    required String doctorId,
    String status = 'issued', // NEW: Added status to differentiate live drafts vs finalized
  }) async {
    try {
      DocumentReference prescriptionRef = _db.collection('prescriptions').doc(roomId);

      Map<String, dynamic> prescriptionData = {
        'roomId': roomId,
        'doctorId': doctorId,
        'patientAge': patientAge, 
        'medications': medications,
        'doctorNotes': doctorNotes,
        'issuedAt': FieldValue.serverTimestamp(), 
        'status': status, // Dynamically set to 'draft' or 'issued'
      };

      await prescriptionRef.set(prescriptionData, SetOptions(merge: true));
      
      debugPrint("PrescriptionService: Successfully synced prescription for Room $roomId (Status: $status)");
      return true;
    } catch (e) {
      debugPrint("PrescriptionService: Error saving prescription: $e");
      return false;
    }
  }

  Stream<DocumentSnapshot> getPrescriptionStream(String roomId) {
    return _db.collection('prescriptions').doc(roomId).snapshots();
  }

  Future<Map<String, dynamic>?> getPrescription(String roomId) async {
    try {
      DocumentSnapshot doc = await _db.collection('prescriptions').doc(roomId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint("PrescriptionService: Error fetching prescription: $e");
      return null;
    }
  }
}