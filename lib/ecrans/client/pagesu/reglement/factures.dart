import 'package:RAS/ecrans/client/pagesu/reglement/voir_facture.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:RAS/basicdata/facture.dart';
import 'package:RAS/basicdata/utilisateur.dart';
import 'package:RAS/basicdata/style.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';
import 'package:RAS/services/synchronisation/facture_pdf_service.dart';

class Factures extends StatefulWidget {
  const Factures({super.key});

  @override
  State<Factures> createState() => _FacturesState();
}

class _FacturesState extends State<Factures> {
  Stream<List<factures>>? _facturesStream;

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
          .from('Factures')
          .stream(primaryKey: ['id']) // Assuming 'id' is the primary key
          .eq('utilisateur->idUtilisateur', user.id)
          .order('dateFacture', ascending: false)
          .map((data) {
            return data.map((map) {
              try {
                return factures.fromMap(map);
              } catch (e) {
                print('Erreur de parsing pour le document ${map['id']}: $e');
                // Amélioration de la gestion des erreurs pour éviter que les factures disparaissent
                try {
                  return factures(
                    idFacture: map['id'] ?? 'unknown',
                    dateFacture:
                        map['dateFacture'] ?? DateTime.now().toIso8601String(),
                    utilisateur:
                        map['utilisateur'] != null
                            ? Utilisateur.fromMap(
                              map['utilisateur'] as Map<String, dynamic>,
                            )
                            : Utilisateur(
                              idUtilisateur: user.id,
                              nomUtilisateur:
                                  map['nomUtilisateur'] ?? 'Inconnu',
                              prenomUtilisateur: map['prenomUtilisateur'] ?? '',
                              emailUtilisateur: map['emailUtilisateur'] ?? '',
                              numeroUtilisateur: map['numeroUtilisateur'] ?? '',
                              villeUtilisateur: map['villeUtilisateur'] ?? '',
                              roleUtilisateur: 'user',
                            ),
                    produits: [], // Initialisation avec une liste vide
                    prixFacture: map['prixFacture'] ?? 0,
                    quantite: map['quantite'] ?? 0,
                  );
                } catch (innerError) {
                  print(
                    'Erreur lors de la création de la facture de secours: $innerError',
                  );
                  // Retourner une facture minimale pour éviter que l'interface ne disparaisse
                  return factures(
                    idFacture: map['id'] ?? 'unknown',
                    dateFacture: DateTime.now().toIso8601String(),
                    utilisateur: Utilisateur(
                      idUtilisateur: user.id,
                      nomUtilisateur: 'Inconnu',
                      prenomUtilisateur: '',
                      emailUtilisateur: '',
                      numeroUtilisateur: '',
                      villeUtilisateur: '',
                      roleUtilisateur: 'user',
                    ),
                    produits: [],
                    prixFacture: 0,
                    quantite: 0,
                  );
                }
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
          child: StreamBuilder<List<factures>>(
            stream: _facturesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Styles.rouge),
                  ),
                );
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
                          FluentIcons.document_pdf_24_filled,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucune facture trouvée',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Vos factures apparaîtront ici après avoir passé des commandes',
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

  Widget _buildFactureCard(BuildContext context, factures facture) {
    final date = DateTime.parse(facture.dateFacture);
    final formattedDate = DateFormat(
      'dd MMMM yyyy à HH:mm',
      'fr_FR',
    ).format(date);
    final String displayId =
        facture.idFacture.length >= 10
            ? facture.idFacture.substring(0, 10).toUpperCase()
            : facture.idFacture.toUpperCase();

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
                                name: 'Facture_${facture.idFacture}.pdf',
                              );
                            } else {
                              await Printing.sharePdf(
                                bytes: bytes,
                                filename: 'Facture_${facture.idFacture}.pdf',
                              );
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Télécharger',
                          icon: const Icon(Icons.download),
                          onPressed: () async {
                            final bytes =
                                await FacturePdfService.generateFacturePdf(
                                  facture,
                                );
                            if (kIsWeb) {
                              await Printing.layoutPdf(
                                onLayout: (format) async => bytes,
                                name: 'Facture_${facture.idFacture}.pdf',
                              );
                            } else {
                              await Printing.sharePdf(
                                bytes: bytes,
                                filename: 'Facture_${facture.idFacture}.pdf',
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${facture.prixFacture} CFA',
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
