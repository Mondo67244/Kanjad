import 'dart:async';
import 'package:kanjad/ecrans/client/pagesu/articles/commandes.dart';
import 'package:kanjad/ecrans/client/pagesu/parametres/contactentreprise.dart';
import 'package:kanjad/ecrans/client/pagesu/parametres/monprofil.dart';
import 'package:kanjad/ecrans/client/pagesu/principales/discusuraccueilpetit.dart';
import 'package:kanjad/ecrans/client/pagesu/principales/discusuraccueillarge.dart';
import 'package:kanjad/utilitaires/servicemessagerie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/ecrans/client/pagesu/articles/panierclient.dart';
import 'package:kanjad/ecrans/client/pagesu/articles/articlesclient.dart';
import 'package:kanjad/ecrans/client/pagesu/articles/souhaitsclient.dart';
import 'package:provider/provider.dart';
import 'package:kanjad/services/BD/servicenotification.dart';
import 'package:kanjad/services/providers/messageprovider.dart';
import 'package:kanjad/widgets/gestbadges.dart';
import 'package:kanjad/widgets/kanjadappbar.dart';

class _DiscussionsWrapper extends StatelessWidget {
  const _DiscussionsWrapper();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Utiliser une largeur plus élevée pour déclencher le grand écran
        // pour correspondre aux dashboards commerciaux qui utilisent > 800
        final isLargeScreen = constraints.maxWidth > 800;

        if (isLargeScreen) {
          return const DiscusuraccueilLarge();
        } else {
          return const Discusuraccueil();
        }
      },
    );
  }
}

class Accueilu extends StatefulWidget {
  const Accueilu({super.key});

  @override
  State<Accueilu> createState() => _AccueiluState();
}

class _AccueiluState extends State<Accueilu> with TickerProviderStateMixin {
  TabController? _tabController;
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  User? _currentUser;
  Map<String, dynamic>? _userData;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _pages = [
      const Recents(),
      const Panier(),
      const SouhaitsPage(),
      const _DiscussionsWrapper(),
      const CommandesPage(),
    ];

    _currentUser = Supabase.instance.client.auth.currentUser;
    _loadUserData();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      AuthState response,
    ) {
      if (mounted) {
        final user = response.session?.user;
        setState(() {
          _currentUser = user;
        });
        if (user != null) {
          _loadUserData();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      notificationService.refreshAllCounts();
    });

    _checkMessagesOnStart();
  }

  Future<void> _loadUserData() async {
    final User? user = _currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('utilisateurs')
            .select()
            .eq('idutilisateur', user.id);

        if (mounted) {
          setState(() {
            if (data.isNotEmpty) {
              _userData = data[0] as Map<String, dynamic>?;
            }
          });
        }
      } catch (e) {
        if (mounted) {
          MessagerieService.showError(
            context,
            'Erreur de chargement des données utilisateur.',
          );
        }
      }
    }
  }

  Future<void> _checkMessagesOnStart() async {
    // Petite pause pour laisser l'interface se charger
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      await notificationService.checkMessagesOnAppStart(context);
    }
  }


  void _onTapNav(int index) {
    setState(() {
      _selectedIndex = index;
      _tabController?.index = index;
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tailleEcran = MediaQuery.of(context).size.width;
    final ecranLarge = tailleEcran > 550;
    final notificationService = Provider.of<NotificationService>(context);

    if (ecranLarge && _tabController == null) {
      _tabController = TabController(length: 5, vsync: this);
      _tabController!.addListener(() {
        setState(() {
          _selectedIndex = _tabController!.index;
        });
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: KanjadAppBar(
        title: 'Kanjad',
        subtitle: 'Cameroun',
        bottom:
            ecranLarge
                ? TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  dividerHeight: 0,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(color: Styles.rouge),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    const Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(FluentIcons.home_more_20_filled),
                          SizedBox(width: 8),
                          Text('Articles'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BadgeWidget(
                            count: notificationService.cartCount,
                            child: const Icon(
                              FluentIcons.shopping_bag_tag_24_filled,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Panier'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BadgeWidget(
                            count: notificationService.wishlistCount,
                            child: const Icon(FluentIcons.heart_20_filled),
                          ),
                          const SizedBox(width: 8),
                          const Text('Souhaits'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Consumer<MessageProvider>(
                            builder: (context, messageProvider, child) {
                              return BadgeWidget(
                                count: messageProvider.unreadCount,
                                child: const Icon(FluentIcons.chat_24_regular),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          const Text('Discussions'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BadgeWidget(
                            count: notificationService.pendingOrdersCount,
                            child: const Icon(
                              FluentIcons.receipt_bag_24_filled,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Commandes'),
                        ],
                      ),
                    ),
                  ],
                )
                : null,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Plus',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              switch (value) {
                case 'profil':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ParametresProfilPage(),
                    ),
                  );
                  break;
                case 'chat':
                  Navigator.pushNamed(context, '/admin/accueil');
                  break;
                case 'parametres':
                  Navigator.pushNamed(context, '/utilisateur/parametres');
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'profil',
                    child: ListTile(
                      dense: true,
                      leading: Icon(FluentIcons.person_24_regular),
                      title: Text('Profil'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'parametres',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.settings),
                      title: Text('Paramètres'),
                    ),
                  ),
                ],
          ),
        ],
      ),
      drawer: Drawer(
        child: Consumer<NotificationService>(
          builder: (context, notificationService, child) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Styles.rouge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: Styles.rouge,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _userData != null
                            ? '${_userData!['prenomutilisateur'] ?? ''} ${_userData!['nomutilisateur'] ?? ''}'
                                .trim()
                            : (_currentUser != null ? 'Utilisateur' : 'Invité'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _currentUser != null
                            ? _currentUser!.email ?? 'Connecté'
                            : 'Non connecté',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_currentUser != null) ...[
                  ListTile(
                    leading: BadgeWidget(
                      count: notificationService.pendingOrdersCount,
                      child: const Icon(FluentIcons.receipt_bag_24_regular),
                    ),
                    title: const Text('Voir les commandes'),
                    onTap: () {
                      Navigator.pop(context);
                      _onTapNav(
                        4,
                      ); // Navigate to Commandes tab (shifted by discussions)
                    },
                  ),
                  ListTile(
                    leading: const Icon(FluentIcons.document_pdf_24_regular),
                    title: const Text('Voir les factures'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/utilisateur/factures');
                    },
                  ),
                  ListTile(
                    leading: const Icon(FluentIcons.chat_24_regular),
                    title: const Text('Contactez-nous'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ContactEntreprisePage()),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(FluentIcons.settings_24_regular),
                    title: const Text('Paramètres'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/utilisateur/parametres');
                    },
                  ),
                  
                  const Divider(),
                  ListTile(
                    leading: const Icon(FluentIcons.sign_out_24_regular),
                    title: const Text('Déconnexion'),
                    onTap: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/connexion',
                          (route) => false,
                        );
                      }
                    },
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(
                      FluentIcons.arrow_enter_left_24_regular,
                    ),
                    title: const Text('Connexion'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/connexion',
                        (route) => false,
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(FluentIcons.person_add_24_regular),
                    title: const Text('Inscription'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/inscription',
                        (route) => false,
                      );
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
      body:
          ecranLarge
              ? TabBarView(controller: _tabController!, children: _pages)
              : IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar:
          ecranLarge
              ? null
              : Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Consumer<NotificationService>(
                    builder: (context, notificationService, child) {
                      return BottomNavigationBar(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        currentIndex: _selectedIndex,
                        onTap: _onTapNav,
                        type: BottomNavigationBarType.fixed,
                        selectedItemColor: const Color.fromARGB(
                          255,
                          163,
                          14,
                          3,
                        ),
                        unselectedItemColor: Colors.grey[600],
                        showUnselectedLabels: true,
                        selectedIconTheme: const IconThemeData(size: 23),
                        unselectedIconTheme: const IconThemeData(size: 21),
                        selectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                        items: [
                          const BottomNavigationBarItem(
                            icon: Icon(FluentIcons.home_more_20_filled),
                            label: 'Articles',
                          ),
                          BottomNavigationBarItem(
                            icon: BadgeWidget(
                              count: notificationService.cartCount,
                              child: const Icon(
                                FluentIcons.shopping_bag_tag_24_filled,
                              ),
                            ),
                            label: 'Panier',
                          ),
                          BottomNavigationBarItem(
                            icon: BadgeWidget(
                              count: notificationService.wishlistCount,
                              child: const Icon(FluentIcons.heart_24_filled),
                            ),
                            label: 'Souhaits',
                          ),
                          BottomNavigationBarItem(
                            icon: Consumer<MessageProvider>(
                              builder: (context, messageProvider, child) {
                                return BadgeWidget(
                                  count: messageProvider.unreadCount,
                                  child: const Icon(
                                    FluentIcons.chat_24_regular,
                                  ),
                                );
                              },
                            ),
                            label: 'Discuss.',
                          ),
                          BottomNavigationBarItem(
                            icon: BadgeWidget(
                              count: notificationService.pendingOrdersCount,
                              child: const Icon(
                                FluentIcons.receipt_bag_24_filled,
                              ),
                            ),
                            label: 'Achats',
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
    );
  }
}
