import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/basicdata/commande.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:kanjad/widgets/kanjadappbar.dart';
import 'package:kanjad/widgets/indicateurdetats.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatLivreurPage extends StatefulWidget {
  const StatLivreurPage({super.key});

  @override
  State<StatLivreurPage> createState() => _StatLivreurPageState();
}

class _StatLivreurPageState extends State<StatLivreurPage> {
  final String idlivreur = Supabase.instance.client.auth.currentUser!.id;

  @override
  Widget build(BuildContext context) {
    final grandEcran = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: KanjadAppBar(
        title: 'Kanjad',
        subtitle: 'Mes Statistiques',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: grandEcran ? 630.0 : double.infinity,
          ),
          child: FutureBuilder<List<Commande>>(
            future: SupabaseService.instance.getCommandesByLivreur(idlivreur),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingIndicator();
              }

              if (snapshot.hasError) {
                return EmptyStateWidget(
                  message: 'Erreur: ${snapshot.error}',
                  icon: FluentIcons.error_circle_24_regular,
                  onRetry: () => setState(() {}),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const EmptyStateWidget(
                  message: 'Aucune livraison réalisée.',
                  icon: FluentIcons.vehicle_truck_24_regular,
                );
              }

              final commandes = snapshot.data!;
              return _buildStatistics(commandes);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics(List<Commande> commandes) {
    // Calculer les statistiques
    final totalMontant = commandes
        .where((cmd) => cmd.statutpaiement == 'Livré' || cmd.statutpaiement == 'Terminé')
        .fold<double>(0.0, (sum, cmd) => sum + cmd.prixcommande);

    final totalLivraisons = commandes
        .where((cmd) => cmd.statutpaiement == 'Livré' || cmd.statutpaiement == 'Terminé')
        .length;

    // Calculs des produits les plus demandés
    final Map<String, int> produitStats = {};
    final Map<String, double> produitPrixStats = {};

    for (final commande in commandes) {
      for (final produit in commande.produits) {
        final nomProduit = produit['nomproduit'] as String;
        final quantite = produit['quantite'] as int;
        final prix = produit['prix'] as num;

        produitStats[nomProduit] = (produitStats[nomProduit] ?? 0) + quantite;
        produitPrixStats[nomProduit] = (produitPrixStats[nomProduit] ?? 0) + (quantite * prix);
      }
    }

    // Trier les produits par quantité vendue
    final produitsPlusDemandes = produitStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Compter par catégorie
    final Map<String, int> categorieStats = {};
    commandes.expand((cmd) => cmd.produits).forEach((produit) {
      final categorie = produit['categorie'] ?? 'Non classé';
      categorieStats[categorie] = (categorieStats[categorie] ?? 0) + (produit['quantite'] as int);
    });

    final categoriesPlusDemandees = categorieStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Statistiques principales
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: FluentIcons.money_24_regular,
                title: 'Montant Total',
                value: '${totalMontant.toStringAsFixed(0)} CFA',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                icon: FluentIcons.vehicle_truck_profile_24_regular,
                title: 'Livraisons',
                value: '$totalLivraisons',
                color: Styles.bleu,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Section produits les plus demandés
        Card(
          color: Styles.blanc,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FluentIcons.production_24_regular, color: Styles.rouge, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Produits les Plus Demandés',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Styles.bleu,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                ...produitsPlusDemandes.take(5).map((entry) {
                  final revenu = produitPrixStats[entry.key] ?? 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${entry.value} unités',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${revenu.toStringAsFixed(0)} CFA',
                            style: TextStyle(color: Styles.rouge, fontSize: 14, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Section catégories les plus demandées
        Card(
          color: Styles.blanc,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FluentIcons.collections_24_regular, color: Styles.rouge, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Catégories les Plus Vendues',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Styles.bleu,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                ...categoriesPlusDemandees.take(5).map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Styles.rouge.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${entry.value} unités',
                            style: TextStyle(
                              color: Styles.rouge,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Statistiques supplémentaires
        Card(
          color: Styles.blanc,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FluentIcons.data_histogram_24_regular, color: Styles.rouge, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Résumé',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Styles.bleu,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _detailRow('Commandes Totales:', '${commandes.length}'),
                _detailRow('Commandes Livrées:', '${commandes.where((cmd) => cmd.statutpaiement == 'Livré').length}'),
                _detailRow('En Cours:', '${commandes.where((cmd) => cmd.statutpaiement == 'En livraison').length}'),
                _detailRow('Panier Moyen:', '${(totalMontant / totalLivraisons).toStringAsFixed(0)} CFA'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _StatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      color: Styles.blanc,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Styles.bleu,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Styles.rouge,
            ),
          ),
        ],
      ),
    );
  }
}
