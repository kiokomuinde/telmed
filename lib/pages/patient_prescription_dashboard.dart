import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart'; // NEW: Imported QR Flutter
import '../services/prescription_service.dart';

class PatientPrescriptionDashboard extends StatelessWidget {
  final String roomId;
  final PrescriptionService _prescriptionService = PrescriptionService();

  // The primary brand green color used throughout the UI
  final Color primaryGreen = const Color(0xFF2D7D46);

  PatientPrescriptionDashboard({super.key, required this.roomId});

  // --- 1. CORE PDF GENERATOR ---
  Future<Uint8List> _generatePdfBytes(Map<String, dynamic> rxData, List<dynamic> medications) async {
    final pdf = pw.Document();
    final pdfBrandGreen = PdfColor.fromHex('#2D7D46');

    pw.ImageProvider? logoImage;
    try {
      logoImage = await flutterImageProvider(const AssetImage('assets/images/logo.webp'));
    } catch (e) {
      debugPrint("Could not load logo for PDF: $e");
    }

    String dateStr = "Date not available";
    if (rxData['issuedAt'] != null) {
      DateTime dt = (rxData['issuedAt'] as Timestamp).toDate();
      dateStr = DateFormat("MMM dd, yyyy 'at' hh:mm a").format(dt);
    }

    // This is the data the QR code will hold
    final String qrVerificationData = 'VERIFY-RX-$roomId';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // --- HIGHLY PROFESSIONAL BRANDED HEADER ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Left Side: Brand Logo + Company Name
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logoImage != null)
                      pw.Image(logoImage, height: 40)
                    else
                      pw.Icon(const pw.IconData(0xe8e8), color: pdfBrandGreen, size: 35),
                    pw.SizedBox(width: 12),
                    pw.Text(
                      'TELMED', 
                      style: pw.TextStyle(
                        color: pdfBrandGreen, 
                        fontWeight: pw.FontWeight.bold, 
                        fontSize: 26,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                
                // Right Side: Document Title & Tagline
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('OFFICIAL PRESCRIPTION', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: pdfBrandGreen)),
                    pw.SizedBox(height: 2),
                    pw.Text('TELL US TELMED', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600, letterSpacing: 1.2)),
                  ]
                )
              ],
            ),
            pw.SizedBox(height: 15),
            pw.Divider(color: PdfColors.grey300, thickness: 1.5),
            pw.SizedBox(height: 25),
            
            // --- PATIENT, DOCTOR & QR VERIFICATION CARD ---
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Consulting Doctor: ${rxData['doctorId'] ?? 'Unknown'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: pdfBrandGreen)),
                      pw.SizedBox(height: 6),
                      pw.Text('Issued: $dateStr', style: const pw.TextStyle(fontSize: 11)),
                      pw.SizedBox(height: 6),
                      pw.Text('Patient Age: ${rxData['patientAge']} Years', style: const pw.TextStyle(fontSize: 11)),
                    ],
                  ),
                  // NATIVE PDF QR CODE
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        height: 50,
                        width: 50,
                        child: pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: qrVerificationData,
                          color: pdfBrandGreen,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text("SCAN TO VERIFY", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: pdfBrandGreen)),
                    ]
                  )
                ]
              )
            ),
            pw.SizedBox(height: 30),

            // PRESCRIBED ITEMS TABLE
            pw.Text('PRESCRIBED ITEMS', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: pdfBrandGreen)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Medicine Name', 'Dosage & Frequency', 'Duration'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 11),
              headerDecoration: pw.BoxDecoration(color: pdfBrandGreen),
              cellStyle: const pw.TextStyle(fontSize: 11),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
              data: medications.map((med) => [
                med['medicine'] ?? '',
                med['dosage'] ?? '',
                med['duration'] ?? '',
              ]).toList(),
            ),
            
            // DOCTOR'S NOTES
            if (rxData['doctorNotes'] != null && rxData['doctorNotes'].toString().isNotEmpty) ...[
              pw.SizedBox(height: 30),
              pw.Text("DOCTOR'S INSTRUCTIONS", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: pdfBrandGreen)),
              pw.SizedBox(height: 10),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  border: pw.Border.all(color: PdfColors.amber200),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Text(rxData['doctorNotes'], style: const pw.TextStyle(color: PdfColors.brown900, fontSize: 11)),
              ),
            ]
          ];
        },
      ),
    );

    return pdf.save();
  }

  // --- 2. PRINT ACTION ---
  Future<void> _printPdf(BuildContext context, Map<String, dynamic> rxData, List<dynamic> medications) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Preparing document for printing..."), duration: Duration(seconds: 1)),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => await _generatePdfBytes(rxData, medications),
      name: 'Prescription_${rxData['doctorId']?.replaceAll(" ", "_") ?? 'Doc'}.pdf',
    );
  }

  // --- 3. DOWNLOAD/SHARE ACTION ---
  Future<void> _downloadPdf(BuildContext context, Map<String, dynamic> rxData, List<dynamic> medications) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Preparing document for download..."), duration: Duration(seconds: 1)),
    );
    final bytes = await _generatePdfBytes(rxData, medications);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Prescription_${rxData['doctorId']?.replaceAll(" ", "_") ?? 'Doc'}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Prescription Details", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen, 
        elevation: 0.5,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _prescriptionService.getPrescription(roomId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryGreen));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return _buildErrorState();
          }

          var rxData = snapshot.data!;
          List<dynamic> medications = rxData['medications'] ?? [];

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/logo.webp',
                              height: 50,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.health_and_safety,
                                color: primaryGreen,
                                size: 50,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "TELMED",
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: primaryGreen,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      _buildSuccessHeader(),
                      const SizedBox(height: 24),
                      _buildDoctorInfoCard(rxData), // Card now includes the QR Code
                      const SizedBox(height: 30),
                      Text(
                        "PRESCRIBED ITEMS",
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, 
                            fontWeight: FontWeight.w900, 
                            color: primaryGreen,
                            letterSpacing: 1.5
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMedicationsList(medications),
                      
                      if (rxData['doctorNotes'] != null && rxData['doctorNotes'].toString().isNotEmpty) ...[
                        const SizedBox(height: 30),
                        _buildDoctorNotesSection(rxData['doctorNotes']),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _buildBottomActionArea(context, rxData, medications),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Ready for action", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: primaryGreen)),
                const SizedBox(height: 4),
                Text("Your prescription has been finalized by the doctor.", style: TextStyle(color: Colors.green.shade800, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UPDATED UI INFO CARD TO INCLUDE QR CODE ---
  Widget _buildDoctorInfoCard(Map<String, dynamic> data) {
    String dateStr = "Date not available";
    if (data['issuedAt'] != null) {
      DateTime dt = (data['issuedAt'] as Timestamp).toDate();
      dateStr = DateFormat("MMM dd, yyyy 'at' hh:mm a").format(dt);
    }

    final String qrVerificationData = 'VERIFY-RX-$roomId';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          // Left Side: Text Information
          Expanded(
            child: Column(
              children: [
                _infoRow(Icons.person_outline, "Consulting Doctor", data['doctorId'] ?? 'Unknown'),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Color(0xFFF1F5F9))),
                _infoRow(Icons.calendar_today_outlined, "Issued On", dateStr),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Color(0xFFF1F5F9))),
                _infoRow(Icons.face_outlined, "Patient Age", "${data['patientAge']} Years"),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right Side: Beautifully Integrated QR Code
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryGreen.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                QrImageView(
                  data: qrVerificationData,
                  version: QrVersions.auto,
                  size: 75.0,
                  foregroundColor: primaryGreen,
                ),
                const SizedBox(height: 6),
                Text(
                  "VERIFY RX", 
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: primaryGreen)
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: primaryGreen, size: 20), 
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13))),
        Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: primaryGreen, fontSize: 13)),
      ],
    );
  }

  Widget _buildMedicationsList(List<dynamic> medications) {
    if (medications.isEmpty) {
      return const Text("No medications listed.", style: TextStyle(color: Colors.grey));
    }
    
    return Column(
      children: medications.map((med) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.medication_liquid_outlined, color: primaryGreen, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(med['medicine'], style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15, color: primaryGreen)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(med['dosage'], style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(med['duration'], style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDoctorNotesSection(String notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "DOCTOR'S INSTRUCTIONS",
          style: GoogleFonts.plusJakartaSans(
              fontSize: 12, 
              fontWeight: FontWeight.w900, 
              color: primaryGreen, 
              letterSpacing: 1.5
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB), 
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline, color: Color(0xFFD97706), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  notes,
                  style: const TextStyle(color: Color(0xFF92400E), fontSize: 14, height: 1.5, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionArea(BuildContext context, Map<String, dynamic> rxData, List<dynamic> medications) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // BUY BUTTON (Full Width)
            ElevatedButton(
              onPressed: () {
                // TODO: Route to pharmacy cart
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Routing to Pharmacy Checkout...")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9A825),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_checkout, color: Colors.white),
                  const SizedBox(width: 10),
                  Text("BUY PRESCRIBED MEDS", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // PRINT AND DOWNLOAD BUTTONS (Side-by-side)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _printPdf(context, rxData, medications),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      side: BorderSide(color: primaryGreen, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.print_outlined, color: primaryGreen, size: 20), 
                        const SizedBox(width: 8),
                        Text("PRINT", style: GoogleFonts.plusJakartaSans(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _downloadPdf(context, rxData, medications),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      side: BorderSide(color: primaryGreen, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.file_download_outlined, color: primaryGreen, size: 20), 
                        const SizedBox(width: 8),
                        Text("DOWNLOAD", style: GoogleFonts.plusJakartaSans(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
          const SizedBox(height: 16),
          Text("Prescription Not Found", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: primaryGreen)),
          const SizedBox(height: 8),
          const Text("We couldn't locate the prescription for this room.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}