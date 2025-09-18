import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:kanjad/basicdata/commande.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kanjad/basicdata/facture.dart';
import 'package:kanjad/basicdata/utilisateur.dart';

class FacturePdfService {
  static Future<Uint8List> generateFacturePdf(Facture facture) async {
    final pw.Document document = pw.Document();
    final Commande? commande = await SupabaseService.instance.getCommandeById(facture.idcommande);
    final idFact = facture.idfacture;

    // Logo
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/kanjad.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    // On récupère toujours la version la plus récente de l'utilisateur
    // pour s'assurer que les informations de livraison sont à jour.
    Utilisateur utilisateur = await SupabaseService.instance.getUtilisateur(facture.utilisateur.idutilisateur) ?? facture.utilisateur;

    // Parse date safely
    late String date;
    try {
      final parsedDate = DateTime.parse(facture.datefacture);
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
            // Titre
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.red900,
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
            // Informations sur la facture et le client
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('FACTURE DU CLIENT:',
                        style:
                            pw.TextStyle(color: PdfColors.grey600, fontSize: 10)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                        '${utilisateur.prenomutilisateur ?? ''} ${utilisateur.nomutilisateur ?? ''}',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    if (utilisateur.emailutilisateur.isNotEmpty)
                      pw.Text(utilisateur.emailutilisateur,
                          style: const pw.TextStyle(fontSize: 10)),
                    if (utilisateur.numeroutilisateur?.isNotEmpty ?? false)
                      pw.Text(utilisateur.numeroutilisateur!,
                          style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('N° Facture: $idFact',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text('Date: $date',
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 24),

            // Table listant les produits
            pw.Table.fromTextArray(
              headers: ['Désignation', 'Qté', 'P.U', 'Total'],
              data: [
                ...facture.produits.map((produit) {
                  final prix = produit.prix;
                  final quantite = produit.quantite;
                  final total = prix * quantite;
                  return [
                    produit.nomproduit,
                    quantite.toString(),
                    formatPrice(prix),
                    formatPrice(total),
                  ];
                }),
              ],
              border: pw.TableBorder.all(color: PdfColors.grey200),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
              cellPadding: const pw.EdgeInsets.all(8),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
               rowDecoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
              ),
            ),

            pw.SizedBox(height: 24),

            // Section de livraison et totaux
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Informations de Livraison:',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                            fontSize: 12),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey200),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (utilisateur.addresse?.isNotEmpty ?? false)
                              pw.Text('Adresse: ${utilisateur.addresse}',
                                  style: const pw.TextStyle(fontSize: 10)),
                            if (utilisateur.villeutilisateur?.isNotEmpty ??
                                false)
                              pw.Text(
                                  'Ville: ${utilisateur.villeutilisateur}',
                                  style: const pw.TextStyle(fontSize: 10)),
                            if (utilisateur.pays?.isNotEmpty ?? false)
                              pw.Text('Pays: ${utilisateur.pays}',
                                  style: const pw.TextStyle(fontSize: 10)),
                            if (utilisateur.codepostal?.isNotEmpty ?? false)
                              pw.Text(
                                  'Code Postal: ${utilisateur.codepostal}',
                                  style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  flex: 1,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Sous-total', style: const pw.TextStyle(fontSize: 10)),
                          pw.Text(formatPrice(facture.prixfacture), style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('TVA (0%)', style: const pw.TextStyle(fontSize: 10)),
                          pw.Text(formatPrice(0), style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.Divider(color: PdfColors.grey400),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                           pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                           pw.Text(formatPrice(facture.prixfacture), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            pw.SizedBox(height: 60),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Signature Service Commercial (conditionnelle)
                (commande != null &&
                        commande.choixlivraison == 'domicile' &&
                        commande.methodepaiement == 'ELECTRONIC')
                    ? pw.Column(
                        children: [
                          pw.Container(
                            width: 120,
                            padding: const pw.EdgeInsets.only(top: 20, bottom: 20),
                            child: pw.Text('Facture validée',
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                    color: PdfColors.green,
                                    fontStyle: pw.FontStyle.italic)),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text('Service Commercial Kanjad',
                              style: const pw.TextStyle(fontSize: 9)),
                        ],
                      )
                    : pw.Column(
                        children: [
                          pw.Container(
                            width: 120,
                            padding: const pw.EdgeInsets.only(top: 40),
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                  top: pw.BorderSide(
                                      color: PdfColors.black, width: 1)),
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text('Service Commercial Kanjad',
                              style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                // Signature Livreur
                pw.Column(
                  children: [
                    pw.Container(
                      width: 120,
                      padding: const pw.EdgeInsets.only(top: 40),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                            top: pw.BorderSide(color: PdfColors.black, width: 1)),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text('Le Livreur', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                // Signature Client
                pw.Column(
                  children: [
                    pw.Container(
                      width: 120,
                      padding: const pw.EdgeInsets.only(top: 40),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                            top: pw.BorderSide(color: PdfColors.black, width: 1)),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text('Le Client', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                "NB: Une facture sans la signature du service commercial de Kanjad n'est pas valide.",
                style: pw.TextStyle(
                  fontStyle: pw.FontStyle.italic,
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Spacer(), // Pousse le pied de page vers le bas

            // Pied de page
            pw.Divider(color: PdfColors.grey),
            pw.SizedBox(height: 10),
            pw.Text(
              'Merci d\'avoir choisi Kanjad pour vos achats!',
              style: pw.TextStyle(
                  fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
            ),
          ];
        },
      ),
    );

    return await document.save();
  }
}