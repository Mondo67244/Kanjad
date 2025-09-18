import 'package:kanjad/basicdata/commande.dart';
import 'package:kanjad/basicdata/facture.dart';
import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:intl/intl.dart';
import 'package:kanjad/widgets/kanjadappbar.dart';
import 'package:kanjad/widgets/indicateurdetats.dart';

class StatistiquesVentesPage extends StatefulWidget {
  const StatistiquesVentesPage({super.key});

  @override
  State<StatistiquesVentesPage> createState() => _StatistiquesVentesPageState();
}

class _StatistiquesVentesPageState extends State<StatistiquesVentesPage> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _calculerStatistiques();
  }

  Future<void> _rafraichirStatistiques() async {
    setState(() {
      _statsFuture = _calculerStatistiques();
    });
  }

  Future<Map<String, dynamic>> _calculerStatistiques() async {
    // Fetch both invoices and orders in parallel
    final results = await Future.wait([
      SupabaseService.instance.getAllFactures(),
      SupabaseService.instance.getAllCommandes(),
    ]);

    final List<Facture> factures = results[0] as List<Facture>;
    final List<Commande> commandes = results[1] as List<Commande>;

    double totalVentes = 0;
    int totalCommandes = factures.length;
    int totalProduitsVendus = 0;
    Map<String, int> produitsPopulaires = {};

    for (var facture in factures) {
      totalVentes += facture.prixfacture;
      for (var produit in facture.produits) {
        final int quantite = produit.quantite;
        final String nomproduit = produit.nomproduit;
        totalProduitsVendus += quantite;
        produitsPopulaires[nomproduit] =
            (produitsPopulaires[nomproduit] ?? 0) + quantite;
      }
    }

    double gainsProbables = 0;
    for (var commande in commandes) {
      if (commande.statutpaiement == 'En attente' ||
          commande.statutpaiement == 'En attente de validation') {
        gainsProbables += commande.prixcommande;
      }
    }

    final sortedProduits =
        produitsPopulaires.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalVentes': totalVentes,
      'totalCommandes': totalCommandes,
      'totalProduitsVendus': totalProduitsVendus,
      'produitsPopulaires': sortedProduits.take(5).toList(),
      'gainsProbables': gainsProbables,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: KanjadAppBar(
        title: 'Kanjad',
        subtitle: 'Statistiques',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _rafraichirStatistiques,
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth:
                MediaQuery.of(context).size.width > 600
                    ? 630.0
                    : double.infinity,
          ),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return LoadingIndicator();
              }
              if (snapshot.hasError) {
                return EmptyStateWidget(
                  message: 'Erreur: ${snapshot.error}',
                  icon: FluentIcons.error_circle_24_regular,
                  onRetry: _rafraichirStatistiques,
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const EmptyStateWidget(
                  message: 'Aucune donnée à afficher.',
                  icon: FluentIcons.chart_multiple_24_regular,
                );
              }

              final stats = snapshot.data!;
              final totalVentes = stats['totalVentes'] as double;
              final totalCommandes = stats['totalCommandes'] as int;
              final totalProduitsVendus = stats['totalProduitsVendus'] as int;
              final produitsPopulaires =
                  stats['produitsPopulaires'] as List<MapEntry<String, int>>;
              final gainsProbables = stats['gainsProbables'] as double;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _construireGrilleStatistiques(
                      totalVentes,
                      totalCommandes,
                      totalProduitsVendus,
                      gainsProbables,
                    ),
                    const SizedBox(height: 24),
                    _lesPlusVendus(produitsPopulaires),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _construireGrilleStatistiques(
    double totalVentes,
    int totalCommandes,
    int totalProduitsVendus,
    double gainsProbables,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _indicateur(
                'Revenu Total',
                NumberFormat.currency(
                  locale: 'fr_FR',
                  symbol: 'CFA',
                  decimalDigits: 0,
                ).format(totalVentes),
                FluentIcons.money_24_filled,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _indicateur(
                'Gains Probables',
                NumberFormat.currency(
                  locale: 'fr_FR',
                  symbol: 'CFA',
                  decimalDigits: 0,
                ).format(gainsProbables),
                FluentIcons.money_calculator_24_filled,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _indicateur(
                'Factures',
                totalCommandes.toString(),
                FluentIcons.receipt_bag_24_filled,
                Colors.blue,
                isSmall: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _indicateur(
                'Produits Vendus',
                totalProduitsVendus.toString(),
                FluentIcons.box_24_filled,
                Colors.orange,
                isSmall: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _indicateur(
    String titre,
    String valeur,
    IconData icone,
    Color couleur, {
    bool isSmall = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [couleur.withOpacity(0.8), couleur],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: isSmall ? 28 : 36, color: Colors.white),
            SizedBox(height: isSmall ? 8 : 12),
            Text(
              titre,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              valeur,
              style: TextStyle(
                fontSize: isSmall ? 22 : 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lesPlusVendus(List<MapEntry<String, int>> produits) {
    return Card(
      color: Styles.blanc,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(FluentIcons.trophy_24_filled, color: Styles.rouge),
                SizedBox(width: 8),
                Text(
                  'Produits les plus vendus',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            if (produits.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text('Aucun produit vendu pour le moment.'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: produits.length,
                separatorBuilder:
                    (_, __) => const Divider(height: 1, indent: 56),
                itemBuilder: (context, index) {
                  final item = produits[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: _getClassementIcon(index),
                    title: Text(
                      item.key,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      '${item.value} unités',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _getClassementIcon(int index) {
    if (index == 0) {
      // Or
      return const CircleAvatar(
        backgroundColor: Color(0xFFFFD700), // Gold
        foregroundColor: Colors.white,
        child: Icon(FluentIcons.star_24_filled),
      );
    }
    if (index == 1) {
      // Argent
      return const CircleAvatar(
        backgroundColor: Color(0xFFC0C0C0), // Silver
        foregroundColor: Colors.white,
        child: Icon(FluentIcons.star_24_filled),
      );
    }
    if (index == 2) {
      // Bronze
      return const CircleAvatar(
        backgroundColor: Color(0xFFCD7F32), // Bronze
        foregroundColor: Colors.white,
        child: Icon(FluentIcons.star_24_filled),
      );
    }
    return CircleAvatar(
      backgroundColor: Colors.grey[300],
      foregroundColor: Colors.black54,
      child: Text(
        '#${index + 1}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
