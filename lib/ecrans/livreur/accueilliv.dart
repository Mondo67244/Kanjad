import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/basicdata/commande.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:intl/intl.dart';
import 'package:kanjad/utilitaires/servicemessagerie.dart';
import 'package:kanjad/widgets/kanjadappbar.dart';
import 'package:kanjad/widgets/indicateurdetats.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kanjad/ecrans/client/pagesu/parametres/monprofil.dart';
import 'package:kanjad/ecrans/livreur/statlivreur.dart';

class AccueilLivreurPage extends StatefulWidget {
  const AccueilLivreurPage({super.key});

  @override
  State<AccueilLivreurPage> createState() => _AccueilLivreurPageState();
}

class _AccueilLivreurPageState extends State<AccueilLivreurPage> {
  final String idlivreur = Supabase.instance.client.auth.currentUser!.id;
  final Map<String, dynamic> _clientCache = {};

  // Informations du livreur connecté
  String _livreurNom = '';
  String _livreurPrenom = '';
  String _livreurEmail = '';
  String _livreurInitiales = '';
  bool _chargementLivreur = true;

  @override
  void initState() {
    super.initState();
    _chargerInformationsLivreur();
  }

  Future<void> _chargerInformationsLivreur() async {
    try {
      final utilisateur = await SupabaseService.instance.getUtilisateur(idlivreur);
      if (utilisateur != null && mounted) {
        setState(() {
          _livreurNom = utilisateur.nomutilisateur ?? '';
          _livreurPrenom = utilisateur.prenomutilisateur ?? '';
          _livreurEmail = utilisateur.emailutilisateur;
          _livreurInitiales = '${_livreurPrenom.isNotEmpty ? _livreurPrenom[0] : ''}${_livreurNom.isNotEmpty ? _livreurNom[0] : ''}'.toUpperCase();
          _chargementLivreur = false;
        });
      }
    } catch (e) {
      print('Erreur chargement infos livreur: $e');
      setState(() => _chargementLivreur = false);
    }
  }

  void _refreshCommandes() async {
    // Actualiser les données utilisateurs aussi
    _clientCache.clear();
    setState(() {});
  }

  void _deconnexion() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/connexion', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        MessagerieService.showError(context, 'Erreur lors de la déconnexion: $e');
      }
    }
  }

  Future<Map<String, dynamic>> _getClientInfo(String userId) async {
    if (_clientCache.containsKey(userId)) {
      return _clientCache[userId]!;
    }

    try {
      final utilisateur = await SupabaseService.instance.getUtilisateur(userId);
      if (utilisateur != null) {
        final clientInfo = {
          'prenom': utilisateur.prenomutilisateur ?? 'Client',
          'nom': utilisateur.nomutilisateur ?? 'Inconnu',
          'adresse': utilisateur.addresse ?? 'Non spécifiée',
          'telephone': utilisateur.numeroutilisateur ?? 'Non spécifié',
          'ville': utilisateur.villeutilisateur ?? 'Non spécifiée',
          'pays': utilisateur.pays ?? 'Non spécifié',
          'codepostal': utilisateur.codepostal ?? 'Non spécifié',
        };
        _clientCache[userId] = clientInfo;
        return clientInfo;
      }
    } catch (e) {
      print('Erreur récupération client $userId: $e');
    }

    return {
      'prenom': 'Client',
      'nom': 'Inconnu',
      'adresse': 'Non spécifiée',
      'telephone': 'Non spécifié',
      'ville': 'Non spécifiée',
      'pays': 'Non spécifié',
      'codepostal': 'Non spécifié',
    };
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _construireDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Header du drawer avec les informations du livreur
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Styles.rouge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: _chargementLivreur
                      ? const CircularProgressIndicator(color: Colors.grey)
                      : Text(
                          _livreurInitiales,
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$_livreurPrenom $_livreurNom',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _livreurEmail,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Liste des options
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: Icon(
                    FluentIcons.data_line_24_regular,
                    color: Styles.bleu,
                  ),
                  title: const Text('Mes Statistiques'),
                  onTap: () {
                    // Fermer le drawer
                    Navigator.pop(context);
                    // Naviguer vers la page de statistiques
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StatLivreurPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.person,
                    color: Colors.grey,
                  ),
                  title: const Text('Mon profil'),
                  onTap: () {
                    // Fermer le drawer
                    Navigator.pop(context);
                    // Naviguer vers la page de profil
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ParametresProfilPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: Colors.grey,
                  ),
                  title: const Text('Se déconnecter'),
                  onTap: () {
                    // Fermer le drawer
                    Navigator.pop(context);
                    // Déconnexion
                    _deconnexion();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grandEcran = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      drawer: _construireDrawer(),
      endDrawer: _construireDrawer(),
      appBar: KanjadAppBar(
        title: 'Kanjad',
        subtitle: 'Mes Livraisons',
        actions: [
          
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: _refreshCommandes,
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: grandEcran ? 630.0 : double.infinity,
          ),
          child: StreamBuilder<List<Commande>>(
            stream: SupabaseService.instance.getCommandesByLivreurStream(
              idlivreur,
            ),
            builder: (context, snapshot) {
              print('=== DEBUG LIVREUR PAGE ===');
              print('Connection state: ${snapshot.connectionState}');
              print('Has data: ${snapshot.hasData}');
              print('Has error: ${snapshot.hasError}');

              if (snapshot.hasError) {
                print('Error: ${snapshot.error}');
                return EmptyStateWidget(
                  message: 'Erreur: ${snapshot.error}',
                  icon: FluentIcons.error_circle_24_regular,
                  onRetry: _refreshCommandes,
                );
              }

              if (!snapshot.hasData) {
                print('No data received');
                return const EmptyStateWidget(
                  message: 'Chargement des livraisons...',
                  icon: FluentIcons.vehicle_truck_24_regular,
                );
              }

              final data = snapshot.data!;
              print('Data length: ${data.length}');

              for (int i = 0; i < data.length; i++) {
                print('Commande $i: ${data[i].idcommande}');
                print('  Status: ${data[i].statutpaiement}');
                print('  Livreur: ${data[i].idlivreur}');
                print('  User: ${data[i].utilisateur.nomutilisateur ?? "null"}');
              }

              if (data.isEmpty) {
                return const EmptyStateWidget(
                  message: 'Aucune livraison assignée à votre compte.',
                  icon: FluentIcons.vehicle_truck_24_regular,
                );
              }

              List<Commande> commandes = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: commandes.length,
                itemBuilder: (context, index) {
                  return _livraisonCard(commandes[index]);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'terminé':
      case 'livré':
        return Colors.green;
      case 'en attente de validation':
        return Colors.blue;
      case 'en cours de livraison':
      case 'en livraison':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'terminé':
      case 'livré':
        return FluentIcons.checkmark_circle_24_filled;
      case 'en attente de validation':
        return FluentIcons.info_24_filled;
      case 'en cours de livraison':
      case 'en livraison':
        return FluentIcons.vehicle_truck_profile_24_filled;
      default:
        return FluentIcons.question_circle_24_filled;
    }
  }

  Widget _livraisonCard(Commande commande) {
    final date = DateTime.parse(commande.datecommande);
    final formattedDate = DateFormat(
      'dd MMM yyyy à HH:mm',
      'fr_FR',
    ).format(date);
    final statusColor = _getStatusColor(commande.statutpaiement);
    final statusIcon = _getStatusIcon(commande.statutpaiement);

    return FutureBuilder<Map<String, dynamic>>(
      future: _getClientInfo(commande.utilisateur.idutilisateur),
      builder: (context, clientSnapshot) {
        final clientInfo = clientSnapshot.data ?? {
          'prenom': commande.utilisateur.prenomutilisateur ?? '',
          'nom': commande.utilisateur.nomutilisateur ?? '',
          'adresse': commande.utilisateur.addresse ?? 'Non spécifiée',
          'telephone': commande.utilisateur.numeroutilisateur ?? 'Non spécifié',
          'ville': commande.utilisateur.villeutilisateur ?? 'Non spécifiée',
          'pays': commande.utilisateur.pays ?? 'Non spécifié',
          'codepostal': commande.utilisateur.codepostal ?? 'Non spécifié',
        };

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
              'Livraison #${commande.idcommande.substring(0, 5).toUpperCase()}',
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
                    _detailRow(
                      'Client:',
                      '${clientInfo['prenom']} ${clientInfo['nom']}'.trim(),
                    ),
                    _detailRow(
                      'Adresse:',
                      clientInfo['adresse']!,
                    ),
                    _detailRow(
                      'Téléphone:',
                      clientInfo['telephone']!,
                    ),
                    _detailRow(
                      'Ville:',
                      clientInfo['ville']!,
                    ),
                    _detailRow(
                      'Pays:',
                      clientInfo['pays']!,
                    ),
                    _detailRow(
                      'Code postal:',
                      clientInfo['codepostal']!,
                    ),
                    _detailRow('Paiement:', commande.methodepaiement),
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

                    if (commande.statutpaiement == 'En livraison') ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(FluentIcons.box_checkmark_24_filled),
                          label: const Text('Marquer comme livré'),
                          onPressed: () => _marquerCommeLivre(context, commande),
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
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _marquerCommeLivre(BuildContext context, Commande commande) async {
    try {
      await SupabaseService.instance.majStatut(commande.idcommande, 'Livré');

      if (context.mounted) {
        MessagerieService.showSuccess(
          context,
          'Livraison marquée comme livrée !',
        );
        _refreshCommandes();
      }
    } catch (e) {
      if (context.mounted) {
        MessagerieService.showError(context, 'Erreur: $e');
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
