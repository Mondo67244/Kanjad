import 'package:flutter/material.dart';
import 'package:kanjad/widgets/indicateurdetats.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/basicdata/commande.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class ParametresStatsPage extends StatelessWidget {
  const ParametresStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Statistiques d\'Achats',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Styles.rouge,
        foregroundColor: Styles.blanc,
        centerTitle: true,
        elevation: 0,
      ),
      body: user == null ? _buildLoggedOutView() : _buildStatsView(user),
    );
  }

  Widget _buildLoggedOutView() {
    return const EmptyStateWidget(
      message: 'Veuillez vous connecter pour voir vos statistiques d\'achat.',
      icon: FluentIcons.person_prohibited_24_regular,
    );
  }

  Widget _buildStatsView(User user) {
    final stream = SupabaseService.instance.getCommandesPayeesStream(user.id);

    return StreamBuilder<List<Commande>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyView();
        }

        // --- Data Processing ---
        final commandes = snapshot.data!;
        int totalArticles = 0;
        double totalDepenses = 0;
        final Map<String, int> parCategories = {};

        for (final commande in commandes) {
          totalDepenses += commande.prixcommande;
          for (final p in commande.produits) {
            final int q =
                (p['quantite'] is int)
                    ? p['quantite']
                    : int.tryParse('${p['quantite']}') ?? 0;
            totalArticles += q;
            final categorie = (p['categorie'] ?? 'Inconnu').toString();
            parCategories[categorie] = (parCategories[categorie] ?? 0) + q;
          }
        }

        return RefreshIndicator(
          onRefresh: () async {
            // This is a simple way to trigger a refresh, though streams refresh automatically.
            // For a manual refresh, you might need a different state management approach.
          },
          color: Styles.rouge,
          backgroundColor: Styles.blanc,
          displacement: 20.0,
          strokeWidth: 3,
          child: Column(
            children: [
              // Informational text for manual refresh
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.swipe_down, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Tirez vers le bas pour rafraîchir',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // --- KPIs Section ---
                    Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            title: 'Dépense totale',
                            value:
                                '${NumberFormat('#,##0', 'fr_FR').format(totalDepenses)} CFA',
                            icon: FluentIcons.money_24_filled,
                            color: Colors.green.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildKpiCard(
                            title: 'Articles achetés',
                            value: totalArticles.toString(),
                            icon: FluentIcons.shopping_bag_24_filled,
                            color: Styles.bleu,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Purchases by Category Section ---
                    _buildCategoryStatsCard(parCategories),
                    const SizedBox(height: 24),

                    // --- Purchase History Section ---
                    _buildHistoryCard(commandes),
                  ],
                  ),
                ),
              ]
              ),
            
          );
  }
  );
      }
    
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            FluentIcons.chart_multiple_24_regular,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune statistique à afficher.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const Text(
            'Vos statistiques apparaîtront ici après votre premier achat.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      color: Styles.blanc,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 20,
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryStatsCard(Map<String, int> categoryData) {
    if (categoryData.isEmpty ||
        categoryData.keys.every((k) => k == 'Inconnu')) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Styles.blanc,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Achats par Catégorie',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            ...categoryData.entries.map((entry) {
              if (entry.key == 'Inconnu') return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${entry.value} articles',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(List<Commande> commandes) {
    return Card(
      color: Styles.blanc,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historique d\'achats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: commandes.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final commande = commandes[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    FluentIcons.receipt_24_regular,
                    color: Styles.rouge,
                  ),
                  title: Text(
                    'Commande #${commande.idcommande.substring(0, 5).toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    DateFormat(
                      'dd MMMM yyyy',
                      'fr_FR',
                    ).format(DateTime.parse(commande.datecommande)),
                  ),
                  trailing: Text(
                    '${commande.prixcommande.toStringAsFixed(0)} CFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 16,
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
