import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:RAS/basicdata/facture.dart';

class FacturePdfService {
  static Future<Uint8List> generateFacturePdf(factures facture) async {
    final pw.Document document = pw.Document();
    final idFact = facture.idFacture;

    // Logo
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/kanjad.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    // Parse date safely
    late String date;
    try {
      final parsedDate = DateTime.parse(facture.dateFacture);
      date = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(parsedDate);
    } catch (e) {
      // Fallback to current date if parsing fails
      date = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(DateTime.now());
    }

    // Helpers
    String formatPrice(num value) => '${value.toStringAsFixed(0)} CFA';

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        build: (context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.red800,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Royal Advanced Services',
                        style: pw.TextStyle(
                          fontSize: 17,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'B.P: 3563',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'Akwa Douala-Bar',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'info@royaladservices.net',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        '+237-233-438-552 | +237-697-537-548',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'Facturation du $date',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                  if (logoImage != null)
                    pw.Column(
                      children: [
                        pw.Container(
                          height: 48,
                          width: 140,
                          alignment: pw.Alignment.centerRight,
                          child: pw.Image(logoImage, height: 48),
                        ),
                        pw.Text(
                          'Cameroun',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            pw.SizedBox(height: 15),
            pw.Text(
              idFact,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(),
            pw.SizedBox(height: 12),

            // Client info
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'factures de Mr./Mme/Mlle.: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${facture.utilisateur.prenomUtilisateur} ${facture.utilisateur.nomUtilisateur}',
                      ),
                      if (facture.utilisateur.emailUtilisateur.isNotEmpty)
                        pw.Text(facture.utilisateur.emailUtilisateur),
                      if (facture.utilisateur.numeroUtilisateur.isNotEmpty)
                        pw.Text(facture.utilisateur.numeroUtilisateur),
                      if (facture.utilisateur.villeUtilisateur.isNotEmpty)
                        pw.Text(facture.utilisateur.villeUtilisateur),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 24),

            // Products table
            pw.Table.fromTextArray(
              headers: ['Désignation', 'Qté', 'P.U', 'Total'],
              data: [
                ...facture.produits.map((produit) {
                  final prix = int.tryParse(produit.prix) ?? 0;
                  final quantite = int.tryParse(produit.quantite) ?? 0;
                  final total = prix * quantite;
                  return [
                    produit.nomProduit,
                    '$quantite',
                    formatPrice(prix),
                    formatPrice(total),
                  ];
                }),
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
              border: null,
            ),

            pw.SizedBox(height: 24),

            // Total
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                  ),
                  child: pw.Text(
                    'Total: ${formatPrice(facture.prixFacture)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 24),

            // Footer
            pw.Column(
              children: [
                pw.Divider(),
                pw.Text(
                  'Merci pour votre confiance!',
                  style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return await document.save();
  }
}
