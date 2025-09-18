import 'package:kanjad/ecrans/client/pagesu/reglement/detailsfacture.dart';
import 'package:kanjad/widgets/indicateurdetats.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:kanjad/basicdata/facture.dart';
import 'package:kanjad/basicdata/utilisateur.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';
import 'package:kanjad/ecrans/client/pagesu/reglement/genfacturepdf.dart';

class Factures extends StatefulWidget {
  const Factures({super.key});

  @override
  State<Factures> createState() => _FacturesState();
}

class _FacturesState extends State<Factures> {
  Stream<List<Facture>>? _facturesStream;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
    _loadFactures();
  }

  void _loadFactures() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _facturesStream = Supabase.instance.client
          .from('factures')
          .stream(primaryKey: ['idfacture'])
          .eq('idutilisateur', user.id)
          .order('datefacture', ascending: false)
          .map((data) {
            return data.map((map) {
              try {
                return Facture.fromMap(map);
              } catch (e) {
                print(
                  'Erreur de parsing pour la facture ${map['idfacture']}: $e',
                );
                return Facture(
                  idfacture: map['idfacture'] ?? 'Inconnu',
                  idcommande: map['idcommande'] ?? 'Inconnu',
                  datefacture: DateTime.now().toIso8601String(),
                  utilisateur: Utilisateur(
                    idutilisateur: user.id,
                    nomutilisateur: 'N/A',
                    prenomutilisateur: '',
                    emailutilisateur: '',
                    numeroutilisateur: '',
                    villeutilisateur: '',
                    roleutilisateur: 'client',
                  ),
                  produits: [],
                  prixfacture: (map['prixfacture'] as num?)?.toDouble() ?? 0.0,
                  quantite: (map['quantite'] as num?)?.toInt() ?? 0,
                );
              }
            }).toList();
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
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
                'Factures',
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
      ),
      body: Center(
        child: Container(
          constraints:
              isWideScreen
                  ? const BoxConstraints(maxWidth: 600)
                  : const BoxConstraints(maxWidth: 400),
          child: StreamBuilder<List<Facture>>(
            stream: _facturesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingIndicator();
              }

              // Gestion améliorée des erreurs
              if (snapshot.hasError) {
                print(
                  'Erreur lors du chargement des factures: ${snapshot.error}',
                );
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          FluentIcons.error_circle_24_filled,
                          size: 48,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Erreur de chargement',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Une erreur est survenue lors du chargement des factures. Veuillez réessayer.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _loadFactures();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Styles.rouge,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return EmptyStateWidget(
                  message: 'Aucune facture trouvée',
                  icon: FluentIcons.document_pdf_24_filled,
                  onRetry: () {
                    setState(() {
                      _loadFactures();
                    });
                  },
                );
              }

              final factures = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: factures.length,
                itemBuilder: (context, index) {
                  final facture = factures[index];
                  return _buildFactureCard(context, facture);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFactureCard(BuildContext context, Facture facture) {
    final date = DateTime.parse(facture.datefacture);
    final formattedDate = DateFormat(
      'dd MMMM yyyy à HH:mm',
      'fr_FR',
    ).format(date);
    final String displayId =
        facture.idfacture.length >= 10
            ? facture.idfacture.substring(0, 10).toUpperCase()
            : facture.idfacture.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VoirFacture(facture: facture),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Styles.rouge.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  FluentIcons.receipt_bag_24_filled,
                                  color: Styles.rouge,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                displayId,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.shade600.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FluentIcons.checkmark_circle_24_filled,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Payé',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          FluentIcons.shopping_bag_24_filled,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${facture.produits.length} articles',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Imprimer',
                          icon: const Icon(Icons.print),
                          onPressed: () async {
                            final bytes =
                                await FacturePdfService.generateFacturePdf(
                                  facture,
                                );
                            if (kIsWeb) {
                              await Printing.layoutPdf(
                                onLayout: (format) async => bytes,
                                name: 'Facture_${facture.idfacture}.pdf',
                              );
                            } else {
                              await Printing.sharePdf(
                                bytes: bytes,
                                filename: 'Facture_${facture.idfacture}.pdf',
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${facture.prixfacture.toStringAsFixed(0)} CFA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
