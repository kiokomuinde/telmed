import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class MpesaService {
  // 🚨 IMPORTANT: Replace 'telmed-backend.vercel.app' with the exact domain from your screenshot!
  // Make sure you keep the 'https://' at the beginning and '/api/initiate_mpesa' at the end.
  static const String _vercelUrl = 'https://telmed-backend.vercel.app/api/initiate_mpesa';
  
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Smart formatter to ensure Safaricom Daraja accepts the number
  /// Converts "0712...", "+254712...", or "712..." to strict "254712..." or "2541..."
  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\D'), ''); // Strip + or spaces
    
    if (cleaned.startsWith('0')) {
      cleaned = '254${cleaned.substring(1)}';
    } else if (cleaned.startsWith('7') || cleaned.startsWith('1')) {
      cleaned = '254$cleaned';
    }
    
    return cleaned;
  }

  /// Sends the phone number to Vercel to trigger the Safaricom STK Push
  /// Returns the checkoutRequestID if successful, or null if it fails.
  Future<String?> initiatePayment({required String phoneNumber, required int amount}) async {
    final formattedPhone = _formatPhoneNumber(phoneNumber);
    
    // Debugging logs to help us trace the exact request in your console
    print('🌐 Attempting to hit Vercel URL: $_vercelUrl');
    print('📱 Formatted Phone Number: $formattedPhone');

    try {
      final response = await http.post(
        Uri.parse(_vercelUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': formattedPhone, 
          'amount': amount,
        }),
      );

      print('📡 Vercel Response Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Success! CheckoutRequestID: ${data['checkoutRequestID']}');
        return data['checkoutRequestID'];
      } else {
        print('🛑 Server Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('🛑 Network Error: $e');
      return null;
    }
  }

  /// Listens to the specific Firestore document for status updates from the Webhook
  Stream<DocumentSnapshot> listenToPaymentStatus(String checkoutRequestId) {
    return _db.collection('payments').doc(checkoutRequestId).snapshots();
  }
}