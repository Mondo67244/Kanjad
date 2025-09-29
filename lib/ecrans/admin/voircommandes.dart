import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/basicdata/commande.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:intl/intl.dart';
import 'package:kanjad/utilitaires/servicemessagerie.dart';
import 'package:kanjad/widgets/kanjadappbar.dart';
import 'package:kanjad/widgets/indicateurdetats.dart';
import 'package:kanjad/widgets/dialogueskanjad.dart';

class VoirCommandesPage extends StatefulWidget {
  const VoirCommandesPage({super.key});

  @override
  State<VoirCommandesPage> createState() => _VoirCommandesPageState();
}

class _VoirCommandesPageState extends State<VoirCommandesPage> {
  String _filter = 'Toutes';

  void _setFilter(String filter) {
    setState(() {
      _filter = filter;
    });
  }

  void _refreshCommandes() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final grandEcran = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: KanjadAppBar(
        title: 'Kanjad',
        subtitle: 'Commandes',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCommandes,
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: grandEcran ? 630.0 : double.infinity,
          ),
          child: Column(
            children: [
              _buildFilterChips(),
              Expanded(
                child: StreamBuilder<List<Commande>>(
                  stream: SupabaseService.instance.getAllCommandesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingIndicator();
                    }
                    if (snapshot.hasError) {
                      return EmptyStateWidget(
                        message: 'Erreur: ${snapshot.error}',
                        icon: FluentIcons.error_circle_24_regular,
                        onRetry: _refreshCommandes,
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const EmptyStateWidget(
                        message: 'Aucune commande à afficher.',
                        icon: FluentIcons.receipt_bag_24_regular,
                      );
                    }

                    List<Commande> commandes = snapshot.data!;
                    if (_filter != 'Toutes') {
                      commandes =
                          commandes
                              .where((c) => c.statutpaiement == _filter)
                              .toList();
                    }

                    if (commandes.isEmpty) {
                      return const EmptyStateWidget(
                        message: 'Aucune commande dans cette catégorie.',
                        icon: FluentIcons.receipt_bag_24_regular,
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: commandes.length,
                      itemBuilder: (context, index) {
                        return _commandeCard(commandes[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      'Toutes',
      'En attente',
      'En attente de validation',
      'Validée',
      'Payé',
      'En cours de livraison',
      'Livré',
      'Terminé',
    ];
    final grandEcran = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      color: grandEcran ? null : Styles.blanc,
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children:
              filters.map((filter) {
                final isSelected = _filter == filter;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) _setFilter(filter);
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Styles.rouge.withOpacity(0.8),
                    labelStyle: TextStyle(
                      color: isSelected ? Styles.blanc : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Styles.rouge : Colors.grey[300]!,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'payé':
      case 'terminé':
      case 'livré':
        return Colors.green;
      case 'en attente de validation':
      case 'validée':
      case 'en cours de livraison':
        return Colors.blue;
      case 'en attente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'payé':
      case 'terminé':
      case 'livré':
        return FluentIcons.checkmark_circle_24_filled;
      case 'en cours de livraison':
        return FluentIcons.vehicle_truck_profile_24_filled;
      case 'validée':
        return FluentIcons.clipboard_checkmark_24_filled;
      case 'en attente de validation':
        return FluentIcons.info_24_filled;
      case 'en attente':
        return FluentIcons.clock_24_filled;
      default:
        return FluentIcons.question_circle_24_filled;
    }
  }

  Widget _commandeCard(Commande commande) {
    final date = DateTime.parse(commande.datecommande);
    final formattedDate = DateFormat(
      'dd MMM yyyy à HH:mm',
      'fr_FR',
    ).format(date);
    final statusColor = _getStatusColor(commande.statutpaiement);
    final statusIcon = _getStatusIcon(commande.statutpaiement);

    return Card(
      color: Styles.blanc,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor, size: 28),
        ),
        title: Text(
          'Commande #${commande.idcommande.substring(0, 5).toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'Statut: ${commande.statutpaiement}\n$formattedDate',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Text(
          '${commande.prixcommande.toStringAsFixed(0)} CFA',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Styles.rouge,
            fontSize: 18,
          ),
        ),
        children: [
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Client ID:', commande.utilisateur.idutilisateur),
                _detailRow('Paiement:', commande.methodepaiement),
                _detailRow('Livraison:', commande.choixlivraison),
                if (commande.numeropaiement.isNotEmpty)
                  _detailRow('N° Paiement:', commande.numeropaiement),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(),
                ),

                const Text(
                  'Détail des Produits:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...commande.produits.map(
                  (p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(
                      Icons.playlist_add_check_circle_outlined,
                    ),
                    title: Text('${p['nomproduit']}'),
                    trailing: Text(
                      '${p['quantite']} x ${p['prix']} CFA',
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                  ),
                ),

                // CONDITION : Montrer les boutons seulement si paiement en CASH
                if (commande.methodepaiement.toLowerCase() == 'cash') ...[
                  if (commande.statutpaiement == 'En attente') ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          FluentIcons.clipboard_checkmark_24_filled,
                        ),
                        label: const Text('Valider la Commande'),
                        onPressed: () => _validerCommande(context, commande),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ] else if (commande.statutpaiement == 'Validée') ...[
                    const SizedBox(height: 24),
                    if (commande.choixlivraison == 'Livraison à domicile') ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(
                                FluentIcons.vehicle_truck_profile_24_regular,
                              ),
                              label: const Text('Assigner livreur'),
                              onPressed:
                                  () => _showAssignDialog(context, commande),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Styles.bleu,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(
                                FluentIcons.box_checkmark_24_filled,
                              ),
                              label: const Text('Livrer soi-même'),
                              onPressed: () => _livrerSoiMeme(context, commande),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (commande.choixlivraison ==
                        'Retrait en boutique') ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(FluentIcons.building_shop_24_regular),
                          label: const Text('Marquer comme prêt'),
                          onPressed: () => _marquerCommePret(context, commande),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ] else ...[
                  // Pour paiement électronique - bouton info seulement
                  if (commande.statutpaiement == 'En attente' ||
                      commande.statutpaiement == 'Validée') ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Styles.rouge.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Styles.rouge.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            FluentIcons.info_24_regular,
                            color: Styles.rouge,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Paiement ${commande.methodepaiement} - Validation automatique',
                              style: TextStyle(
                                color: Styles.rouge,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _validerCommande(BuildContext context, Commande commande) async {
    try {
      await SupabaseService.instance.majStatut(commande.idcommande, 'Validée');
      // Décrémenter le stock après validation
      await SupabaseService.instance.decrementStockForOrder(commande);

      if (context.mounted) {
        MessagerieService.showSuccess(context, 'Commande validée et stock mis à jour !');
        _refreshCommandes();
      }
    } catch (e) {
      if (context.mounted) {
        MessagerieService.showError(context, "Erreur: $e");
      }
    }
  }

  void _livrerSoiMeme(BuildContext context, Commande commande) async {
    try {
      await SupabaseService.instance.majStatut(commande.idcommande, 'Livré');
      if (context.mounted) {
        MessagerieService.showSuccess(
          context,
          'Commande marquée comme livrée !',
        );
        _refreshCommandes();
      }
    } catch (e) {
      if (context.mounted) {
        MessagerieService.showError(context, "Erreur: $e");
      }
    }
  }

  // ignore: unused_element
  void _terminerCommande(BuildContext context, Commande commande) async {
    try {
      await SupabaseService.instance.majStatut(commande.idcommande, 'Terminé');

      if (context.mounted) {
        MessagerieService.showSuccess(
          context,
          'Commande terminée avec succès !',
        );
        _refreshCommandes();
      }
    } catch (e) {
      if (context.mounted) {
        MessagerieService.showError(
          context,
          'Erreur lors de la finalisation: $e',
        );
      }
    }
  }

  void _showAssignDialog(BuildContext context, Commande commande) async {
    try {
      final livreurs = await SupabaseService.instance.getLivreurs();
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                backgroundColor: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 500,
                    maxHeight: 600,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Styles.rouge.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header avec icône et titre
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Styles.rouge.withOpacity(0.05),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Styles.bleu,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                FluentIcons.vehicle_truck_profile_24_regular,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Assigner un livreur',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Styles.bleu,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Contenu avec liste des livreurs
                      Flexible(
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: livreurs.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      'Aucun livreur disponible',
                                      style: TextStyle(color: Colors.grey),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        child: Text(
                                          '${livreurs.length} livreur${livreurs.length > 1 ? 's' : ''} disponible${livreurs.length > 1 ? 's' : ''}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Styles.rouge,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: livreurs.length,
                                        itemBuilder: (context, index) {
                                          final livreur = livreurs[index];
                                          return ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                                            title: Text(
                                              '${livreur.prenomutilisateur} ${livreur.nomutilisateur}',
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                            subtitle: Text(
                                              livreur.emailutilisateur,
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            ),
                                            onTap: () async {
                                              Navigator.of(dialogContext).pop();
                                              _assignAndRefresh(
                                                context,
                                                commande.idcommande,
                                                livreur.idutilisateur,
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),

                      // Actions
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: const Text(
                            'Annuler',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        DialogService.showErrorDialog(
          context,
          title: 'Erreur de chargement',
          content: "Impossible de récupérer la liste des livreurs: $e",
        );
      }
    }
  }

  void _assignAndRefresh(
    BuildContext context,
    String commandeId,
    String idlivreur,
  ) async {
    try {
      await SupabaseService.instance.assignLivreur(commandeId, idlivreur);
      if (context.mounted) {
        MessagerieService.showSuccess(context, 'Livreur assigné avec succès !');
        _refreshCommandes();
      }
    } catch (e) {
      if (context.mounted) {
        MessagerieService.showError(
          context,
          "Erreur lors de l'assignation: $e",
        );
      }
    }
  }

  void _marquerCommePret(BuildContext context, Commande commande) async {
    try {
      // Pour les retraits en boutique, on peut marquer directement comme livré
      // car le client viendra récupérer en personne
      await SupabaseService.instance.majStatut(commande.idcommande, 'Livré');
      if (context.mounted) {
        MessagerieService.showSuccess(
          context,
          'Commande marquée comme prête pour retrait !',
        );
        _refreshCommandes();
      }
    } catch (e) {
      if (context.mounted) {
        MessagerieService.showError(context, "Erreur: $e");
      }
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
