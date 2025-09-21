import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/facture.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';
import 'package:kanjad/ecrans/client/pagesu/reglement/genfacturepdf.dart';
import 'package:kanjad/basicdata/commande.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:kanjad/widgets/indicateurdetats.dart';

class VoirFacture extends StatefulWidget {
  final Facture facture;

  const VoirFacture({super.key, required this.facture});

  @override
  State<VoirFacture> createState() => _VoirFactureState();
}

class _VoirFactureState extends State<VoirFacture> {
  Commande? _commande;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCommandeDetails();
  }

  Future<void> _fetchCommandeDetails() async {
    final commande = await SupabaseService.instance
        .getCommandeById(widget.facture.idcommande);
    if (mounted) {
      setState(() {
        _commande = commande;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    final datefacture = DateTime.parse(widget.facture.datefacture);
    final date = dateFormat.format(datefacture);
    final idFact = widget.facture.idfacture;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/kanjad.png',
              key: const ValueKey('logo'),
              width: 140,
              height: 50,
            ),
            Transform.translate(
              offset: const Offset(-20, 12),
              child: const Text(
                'Facturation',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Styles.rouge,
        foregroundColor: Styles.blanc,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        actions: [
          
          IconButton(
            tooltip: 'Télécharger',
            icon: const Icon(Icons.download),
            onPressed: () async {
              final bytes =
                  await FacturePdfService.generateFacturePdf(widget.facture);
              if (kIsWeb) {
                await Printing.layoutPdf(
                  onLayout: (format) async => bytes,
                  name: 'Facture_${widget.facture.idfacture}.pdf',
                );
              } else {
                await Printing.sharePdf(
                  bytes: bytes,
                  filename: 'Facture_${widget.facture.idfacture}.pdf',
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                      maxWidth: isWideScreen ? 800 : double.infinity),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _buildHeader(date),
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              _buildClientInfo(idFact, date),
                              const SizedBox(height: 24),
                              _buildProductsTable(),
                              const SizedBox(height: 24),
                              _buildTotalsAndDelivery(),
                              const SizedBox(height: 40),
                              _buildSignatures(),
                              const SizedBox(height: 20),
                              _buildDisclaimer(),
                            ],
                          ),
                        ),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(String date) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Styles.rouge,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Royal Advanced Services',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Styles.blanc)),
              Text('B.P: 3563, Akwa Douala-Bar',
                  style: TextStyle(fontSize: 12, color: Styles.blanc)),
              Text('info@royaladservices.net',
                  style: TextStyle(fontSize: 12, color: Styles.blanc)),
              Text('+237-233-438-552',
                  style: TextStyle(fontSize: 12, color: Styles.blanc)),
            ],
          ),
          Image.asset('assets/images/kanjad.png',
              width: 100, height: 50, fit: BoxFit.contain),
        ],
      ),
    );
  }

  Widget _buildClientInfo(String idFact, String date) {
    final utilisateur = widget.facture.utilisateur;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FACTURE POUR:',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                  '${utilisateur.prenomutilisateur ?? ''} ${utilisateur.nomutilisateur ?? ''}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              if (utilisateur.emailutilisateur.isNotEmpty)
                Text(utilisateur.emailutilisateur,
                    style: const TextStyle(fontSize: 14)),
              if (utilisateur.numeroutilisateur?.isNotEmpty ?? false)
                Text(utilisateur.numeroutilisateur!,
                    style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('N° Facture: $idFact',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text('Date: $date', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildProductsTable() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: const Row(
            children: [
              Expanded(
                  flex: 4,
                  child: Text('Désignation',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white))),
              Expanded(
                  flex: 1,
                  child: Text('Qté',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white))),
              Expanded(
                  flex: 2,
                  child: Text('P.U',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white))),
              Expanded(
                  flex: 2,
                  child: Text('Total',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white))),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(8)),
          ),
          child: Column(
            children: widget.facture.produits.map((produit) {
              final total = produit.prix * produit.quantite;
              return Container(
                padding: 
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!))),
                child: Row(
                  children: [
                    Expanded(flex: 4, child: Text(produit.nomproduit)),
                    Expanded(
                        flex: 1,
                        child: Text(produit.quantite.toString(),
                            textAlign: TextAlign.center)),
                    Expanded(
                        flex: 2,
                        child: Text('${produit.prix.toStringAsFixed(0)} CFA',
                            textAlign: TextAlign.right)),
                    Expanded(
                        flex: 2,
                        child: Text('${total.toStringAsFixed(0)} CFA',
                            textAlign: TextAlign.right)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsAndDelivery() {
    final utilisateur = widget.facture.utilisateur;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Informations de Livraison:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (utilisateur.addresse?.isNotEmpty ?? false)
                      Text('Adresse: ${utilisateur.addresse}'),
                    if (utilisateur.villeutilisateur?.isNotEmpty ?? false)
                      Text('Ville: ${utilisateur.villeutilisateur}'),
                    if (utilisateur.pays?.isNotEmpty ?? false)
                      Text('Pays: ${utilisateur.pays}'),
                    if (utilisateur.codepostal?.isNotEmpty ?? false)
                      Text('Code Postal: ${utilisateur.codepostal}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildTotalRow('Sous-total',
                  '${widget.facture.prixfacture.toStringAsFixed(0)} CFA'),
              _buildTotalRow('TVA (0%)', '0 CFA'),
              const Divider(),
              _buildTotalRow('TOTAL',
                  '${widget.facture.prixfacture.toStringAsFixed(0)} CFA',
                  isBold: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String title, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isBold ? 16 : 14)),
          Text(value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }

  Widget _buildSignatures() {
    final showValidated = _commande != null &&
        _commande!.choixlivraison == 'domicile' &&
        _commande!.methodepaiement == 'ELECTRONIC';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSignatureZone(
            'Service Commercial Kanjad',
            showValidated
                ? const Text('Facture validée', 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.green, fontStyle: FontStyle.italic))
                : null),
        _buildSignatureZone('Le Livreur', null),
        _buildSignatureZone('Le Client', null),
      ],
    );
  }

  Widget _buildSignatureZone(String title, Widget? signatureContent) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 60,
          alignment: Alignment.center,
          child: signatureContent ??
              Container(
                height: 1,
                color: Colors.black,
                margin: const EdgeInsets.only(top: 40),
              ),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildDisclaimer() {
    return const Center(
      child: Text(
        "NB: Une facture sans la signature du service commercial de Kanjad n'est pas valide.",
        style: TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 10,
          color: Colors.grey,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: const Text(
        'Merci d\'avoir choisi Kanjad pour vos achats!',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      ),
    );
  }
}