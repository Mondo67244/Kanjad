import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:RAS/basicdata/style.dart';
import 'package:RAS/ecrans/client/pagesu/articles/panier.dart';
// import 'package:RAS/ecrans/client/pagesu/articles/promo.dart';
import 'package:RAS/ecrans/client/pagesu/articles/recents.dart';
import 'package:RAS/ecrans/client/pagesu/articles/resultats.dart';
import 'package:RAS/ecrans/client/pagesu/articles/souhaits.dart';
import 'package:provider/provider.dart';
import 'package:RAS/services/synchronisation/notification_service.dart';
import 'package:RAS/widgets/badge_widget.dart';

class Accueilu extends StatefulWidget {
  const Accueilu({super.key});

  @override
  State<Accueilu> createState() => _AccueiluState();
}

class _AccueiluState extends State<Accueilu> with TickerProviderStateMixin {
  TabController? _tabController;
  int _selectedIndex = 0;
  final bool _isClick = false;
  final List<Widget> _cachedPages = [];
  final Set<int> _loadedPages = <int>{};
  User? _currentUser;
  Map<String, dynamic>? _userData;

  // Create pages with AutomaticKeepAliveClientMixin to preserve state
  Widget _buildPage(Widget page, int index) {
    if (_loadedPages.contains(index)) {
      return _cachedPages[index];
    } else {
      _loadedPages.add(index);
      _cachedPages[index] = page;
      return page;
    }
  }

  List<Widget> get _pages {
    // Initialize cached pages list if empty
    if (_cachedPages.isEmpty) {
      _cachedPages.addAll(
        List.filled(4, Container()),
      ); // 4 pages: Recents, Promo, Panier, souhaits
    }

    return [
      _buildPage(const Recents(), 0),
      // _buildPage(const Promo(), 1),
      _buildPage(const Panier(), 1),
      _buildPage(const souhaits(), 2),
    ];
  }

  final List<Tab> _tabs = const [
    Tab(
      child: Row(
        children: [
          Icon(FluentIcons.home_more_20_filled),
          SizedBox(width: 3),
          Text('Articles'),
        ],
      ),
    ),
    // Tab(
    //   child: Row(
    //     children: [
    //       Icon(FluentIcons.gift_card_24_filled),
    //       SizedBox(width: 3),
    //       Text('Promotions'),
    //     ],
    //   ),
    // ),
    Tab(
      child: Row(
        children: [
          Icon(FluentIcons.shopping_bag_tag_24_filled),
          SizedBox(width: 3),
          Text('Panier'),
        ],
      ),
    ),
    Tab(
      child: Row(
        children: [
          Icon(FluentIcons.class_20_filled),
          SizedBox(width: 3),
          Text('souhaits'),
        ],
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    Supabase.instance.client.auth.onAuthStateChange.listen((
      AuthState response,
    ) {
      final user = response.session?.user;
      setState(() {
        _currentUser = user;
      });
      if (user != null) {
        _loadUserData();
      }
    });

    // Listen to notification service changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      notificationService.refreshAllCounts();
    });
  }

  Future<void> _loadUserData() async {
    final User? user = _currentUser;
    if (user != null) {
      try {
        final data =
            await Supabase.instance.client
                .from('utilisateurs')
                .select()
                .eq('idUtilisateur', user.id)
                .single();

        if (mounted) {
          setState(() {
            _userData = data as Map<String, dynamic>?;
          });
        }
      } catch (e) {
        print('Erreur lors du chargement des données utilisateur: $e');
      }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 700;
    final notificationService = Provider.of<NotificationService>(context);

    // Initialisation conditionnelle du TabController
    if (isLargeScreen && _tabController == null) {
      _tabController = TabController(length: _tabs.length, vsync: this);
    }

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        foregroundColor: Styles.blanc,
        backgroundColor: Styles.rouge,

        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/kanjad.png',
              key: const ValueKey('logo'),
              width: 140,
              height: 45,
            ),
            Transform.translate(
              offset: const Offset(-30, 13),
              child: const Text(
                'Cameroun',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Styles.blanc,
                ),
              ),
            ),
          ],
        ),

        centerTitle: true,
        bottom:
            isLargeScreen
                ? PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: Container(
                    color: Colors.white,
                    width: double.infinity,
                    child: Center(
                      child: Container(
                        width: 780,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        decoration: const BoxDecoration(color: Colors.white),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: false,
                            dividerHeight: 0,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              color: Styles.rouge,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.grey[700],
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                            tabs: [
                              Tab(
                                child: Row(
                                  children: [
                                    Icon(FluentIcons.home_more_20_filled),
                                    SizedBox(width: 3),
                                    Text('Articles'),
                                  ],
                                ),
                              ),
                              // Tab(
                              //   child: Row(
                              //     children: [
                              //       Icon(FluentIcons.gift_card_24_filled),
                              //       SizedBox(width: 3),
                              //       Text('Promotions'),
                              //     ],
                              //   ),
                              // ),
                              Tab(
                                child: Row(
                                  children: [
                                    BadgeWidget(
                                      count: notificationService.cartCount,
                                      child: Icon(
                                        FluentIcons.shopping_bag_tag_24_filled,
                                      ),
                                    ),
                                    SizedBox(width: 3),
                                    Text('Panier'),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  children: [
                                    BadgeWidget(
                                      count: notificationService.wishlistCount,
                                      child: Icon(FluentIcons.heart_20_filled),
                                    ),
                                    SizedBox(width: 3),
                                    Text('souhaits'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                : null,
        actions: [
          BadgeWidget(
            count: notificationService.pendingOrdersCount,
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/utilisateur/commandes');
              },
              icon: const Icon(FluentIcons.receipt_bag_24_filled),
              tooltip: 'Mes commandes',
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Plus',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              switch (value) {
                case 'factures':
                  Navigator.pushNamed(context, '/utilisateur/factures');
                  break;
                case 'profil':
                  Navigator.pushNamed(context, '/utilisateur/profile');
                  break;
                case 'chat':
                  Navigator.pushNamed(context, '/utilisateur/chat');
                  break;
                case 'parametres':
                  Navigator.pushNamed(context, '/utilisateur/parametres');
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'chat',
                    child: ListTile(
                      dense: true,
                      leading: Icon(FluentIcons.chat_24_regular),
                      title: Text('Aide / Contact'),
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
                  decoration: BoxDecoration(color: Styles.rouge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CircleAvatar(
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
                            ? '${_userData!['prenomUtilisateur'] ?? ''} ${_userData!['nomUtilisateur'] ?? ''}'
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
                      Navigator.pushNamed(context, '/utilisateur/commandes');
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
                  const Divider(),
                  ListTile(
                    leading: const Icon(FluentIcons.person_24_regular),
                    title: const Text('Mon Profil'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/utilisateur/profile');
                    },
                  ),
                  ListTile(
                    leading: const Icon(FluentIcons.chat_24_regular),
                    title: const Text('Contactez-nous'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/utilisateur/chat');
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
                  ListTile(
                    leading: const Icon(FluentIcons.question_circle_24_regular),
                    title: const Text('Aide'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/utilisateur/chat');
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
          _isClick
              ? const Resultats()
              : isLargeScreen
              ? TabBarView(controller: _tabController!, children: _pages)
              : IndexedStack(index: _selectedIndex, children: _pages),

      bottomNavigationBar:
          isLargeScreen
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
                          // BottomNavigationBarItem(
                          //   icon: Icon(FluentIcons.gift_card_24_filled),
                          //   label: 'Promos',
                          // ),
                          BottomNavigationBarItem(
                            icon: BadgeWidget(
                              count: notificationService.cartCount,
                              child: const Icon(
                                FluentIcons.shopping_bag_tag_24_filled,
                              ),
                            ),
                            label: 'Mon panier',
                          ),
                          BottomNavigationBarItem(
                            icon: BadgeWidget(
                              count: notificationService.wishlistCount,
                              child: Icon(FluentIcons.heart_24_filled),
                            ),
                            label: 'Mes souhaits',
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
