
import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:kanjad/utilitaires/servicemessagerie.dart';
import 'package:kanjad/widgets/kanjadappbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kanjad/services/BD/notification_service.dart';

class Accueila extends StatefulWidget {
  const Accueila({super.key});

  @override
  State<Accueila> createState() => _AccueilaState();
}

class _AccueilaState extends State<Accueila> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _nombreNotificationsNonLues = 0;

  @override
  void initState() {
    super.initState();
    _chargerNombreNotifications();
  }

  Future<void> _chargerNombreNotifications() async {
    try {
      final notifications = await NotificationService.instance.recupererNotifications(
        statut: 'non_lu',
      );
      if (mounted) {
        setState(() {
          _nombreNotificationsNonLues = notifications.length;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade100,
      appBar: const KanjadAppBar(
        title: 'Kanjad',
        subtitle: 'Tableau de bord',
      ),
      drawer: _construireTiroirNavigation(),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width > 600 ? 630.0 : double.infinity,
          ),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: _construireGrilleActions(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  

  // Widget pour le tiroir de navigation latéral
  Widget _construireTiroirNavigation() {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Styles.rouge),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/kanjad.png',
                        width: 150,
                        height: 60,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Menu Administrateur',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],  
                  ),
                ),
                ListTile(
                  leading: const Icon(FluentIcons.home_24_regular),
                  title: const Text('Tableau de Bord'),
                  onTap: () => Navigator.pop(context),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text('Gestion', style: TextStyle(color: Colors.grey)),
                ),
                ListTile(
                  leading: const Icon(FluentIcons.add_circle_24_regular),
                  title: const Text('Ajouter un Produit'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/ajouterequip');
                  },
                ),
                ListTile(
                  leading: const Icon(FluentIcons.edit_24_regular),
                  title: const Text('Modifier Produit'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/modifierproduit');
                  },
                ),
                ListTile(
                  leading: const Icon(FluentIcons.people_add_24_regular),
                  title: const Text('Ajouter un Utilisateur'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/ajoututilisateur');
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text('Consultation', style: TextStyle(color: Colors.grey)),
                ),
                ListTile(
                  leading: const Icon(FluentIcons.people_audience_24_regular),
                  title: const Text('Voir les Clients'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/voir_clients');
                  },
                ),
                ListTile(
                  leading: const Icon(FluentIcons.receipt_bag_24_regular),
                  title: const Text('Voir les Commandes'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/voir_commandes');
                  },
                ),
                ListTile(
                  leading: const Icon(FluentIcons.receipt_24_regular),
                  title: const Text('Voir les Factures'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/voir_factures');
                  },
                ),
                ListTile(
                  leading: const Icon(FluentIcons.chart_multiple_24_regular),
                  title: const Text('Statistiques des Ventes'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/statistiques_ventes');
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(FluentIcons.arrow_exit_20_regular, color: Styles.rouge),
            title: const Text('Déconnexion', style: TextStyle(color: Styles.rouge)),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                MessagerieService.showInfo(context, 'Vous avez été déconnecté.');
                Navigator.of(context).pushNamedAndRemoveUntil('/connexion', (route) => false);
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Widget pour la grille des cartes d'action
  Widget _construireGrilleActions() {
    final actions = [
      {
        'route': '/admin/notifications',
        'icon': FluentIcons.alert_24_filled,
        'text': 'Notifications',
        'color': Styles.rouge,
        'badge': _nombreNotificationsNonLues,
      },
      {
        'route': '/admin/ajouterequip',
        'icon': FluentIcons.add_circle_24_filled,
        'text': 'Ajouter un Produit',
        'color': Colors.blue,
      },
      {
        'route': '/admin/modifierproduit',
        'icon': FluentIcons.edit_24_filled,
        'text': 'Modifier Produit',
        'color': Colors.amber,
      },
      {
        'route': '/admin/voir_commandes',
        'icon': FluentIcons.receipt_bag_24_filled,
        'text': 'Commandes',
        'color': Colors.orange,
      },
      {
        'route': '/admin/gestion_stock', // Nouvelle page
        'icon': FluentIcons.box_multiple_24_filled, // Nouvelle icône
        'text': 'Gestion des Stocks', // Nouveau texte
        'color': Colors.brown, // Nouvelle couleur
      },
      {
        'route': '/admin/voir_clients',
        'icon': FluentIcons.people_audience_24_filled,
        'text': 'Nos Clients',
        'color': Colors.green,
      },
      {
        'route': '/admin/statistiques_ventes',
        'icon': FluentIcons.chart_multiple_24_filled,
        'text': 'Statistiques',
        'color': Colors.purple,
      },
      {
        'route': '/admin/ajoututilisateur',
        'icon': FluentIcons.people_add_24_filled,
        'text': 'Ajouter un Utilisateur',
        'color': Colors.teal,
      },
      {
        'route': '/admin/voir_factures',
        'icon': FluentIcons.receipt_24_filled,
        'text': 'Factures',
        'color': Colors.indigo,
      },
      {
        'route': '/admin/promotion',
        'icon': FluentIcons.image_sparkle_24_filled,
        'text': 'Promotions',
        'color': Colors.pink,
      },
      {
        'route': '/admin/mettre_en_avant',
        'icon': FluentIcons.rocket_24_filled,
        'text': 'Mettre en Avant',
        'color': Colors.red,
      },
    ];

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        childAspectRatio: 1.0, // Carré
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final action = actions[index];
          return _construireCarteAction(
            auClic: () {
              Navigator.pushNamed(context, action['route'] as String).then((_) {
                if (action['text'] == 'Notifications') {
                  _chargerNombreNotifications();
                }
              });
            },
            icone: action['icon'] as IconData,
            texte: action['text'] as String,
            couleur: action['color'] as Color,
            badge: action['badge'] as int?,
          );
        },
        childCount: actions.length,
      ),
    );
  }

  // Widget pour chaque carte d'action individuelle
  Widget _construireCarteAction({
    required VoidCallback auClic,
    required IconData icone,
    required String texte,
    required Color couleur,
    int? badge,
  }) {
    return Card(
      color: Styles.blanc,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias, // Pour que InkWell suive la forme
      child: InkWell(
        onTap: auClic,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: couleur.withOpacity(0.15),
                  child: Icon(icone, size: 32, color: couleur),
                ),
                if (badge != null && badge > 0)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Styles.rouge,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge > 99 ? '99+' : badge.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                texte,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
