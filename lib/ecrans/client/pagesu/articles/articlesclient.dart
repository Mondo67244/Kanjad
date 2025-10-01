import 'dart:async';
import 'package:kanjad/services/panier/panierprovider.dart';
import 'package:kanjad/services/souhaits/souhaitsprovider.dart';
import 'package:kanjad/widgets/SectionProduit.dart';
import 'package:kanjad/widgets/promotionsdynamiques.dart';
import 'package:kanjad/services/promotion/servicepromotion.dart';
import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/produit.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:provider/provider.dart';
import 'package:kanjad/services/providers/produitprovider.dart';

class Recents extends StatefulWidget {
  const Recents({super.key});

  @override
  State<Recents> createState() => RecentsState();
}

class RecentsState extends State<Recents>
    with AutomaticKeepAliveClientMixin<Recents>, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final Map<String, int> _produits = {};

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    // Déclencher le chargement des données si elles ne sont pas déjà chargées
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      if (!productProvider.isLoaded) {
        _refreshData();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onLoadMore(String category) {
    setState(() {
      _produits[category] = (_produits[category] ?? 5) + 2;
    });
  }

  Future<void> _toggleAuPanier(Produit produit) async {
    final panierProvider = Provider.of<PanierProvider>(context, listen: false);
    final result = await panierProvider.clicPanier(produit.idproduit);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Styles.erreur,
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    // Also refresh the cart and wishlist providers
    await Future.wait([
      Provider.of<ProductProvider>(
        context,
        listen: false,
      ).loadProducts(forceRefresh: true),
      Provider.of<PanierProvider>(context, listen: false).loadPanier(),
      Provider.of<SouhaitsProvider>(context, listen: false).loadSouhaits(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: FloatingActionButton(
        heroTag: "recents_search",
        onPressed: () => Navigator.pushNamed(context, '/utilisateur/recherche'),
        backgroundColor: Styles.rouge,
        tooltip: 'Rechercher',
        elevation: 4,
        child: const Icon(Icons.search, color: Colors.white),
      ),
      body: NestedScrollView(
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              SliverAppBar(
                automaticallyImplyLeading: false,
                expandedHeight: 100,
                floating: true,
                pinned: false,
                snap: true,
                backgroundColor: Styles.rouge,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Styles.rouge,
                          Styles.rouge.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo et titre
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Articles Récents',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 55),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Bouton d'actualisation
                        IconButton(
                          onPressed: _refreshData,
                          icon: Icon(Icons.refresh, color: Styles.rouge),
                          tooltip: 'Actualiser',
                        ),
                        // Titre de la section
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Découvrez nos produits récents',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
        body: RefreshIndicator(
          onRefresh: _refreshData,
          color: Styles.rouge,
          backgroundColor: Colors.white,
          strokeWidth: 3,
          child: Consumer2<ProductProvider, PanierProvider>(
            builder: (context, productProvider, panierProvider, child) {
              if (productProvider.isLoading &&
                  productProvider.products.isEmpty) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Center(
                    child: CircularProgressIndicator(color: Styles.rouge),
                  ),
                );
              }

              if (productProvider.error != null) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Styles.erreur,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Erreur de chargement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          productProvider.error!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refreshData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Styles.rouge,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  if (screenWidth > 1300) {
                    // Layout large écran avec sidebar
                    return Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              20,
                              8,
                              20,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: DynamicPromotionImages(
                                cote: 'gauche',
                                promotionService: PromotionService(),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Container(
                            constraints: const BoxConstraints(
                              maxWidth: 1200,
                            ),
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildModernContent(
                                productProvider.products,
                                panierProvider.idsPanier,
                                isWideScreen: true,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              8,
                              20,
                              16,
                              20,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: DynamicPromotionImages(
                                cote: 'droite',
                                promotionService: PromotionService(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Layout mobile/tablet
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildModernContent(
                        productProvider.products,
                        panierProvider.idsPanier,
                        isWideScreen: screenWidth > 550,
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // Widget _imagesEntetes(String imageName, {required bool isWide}) {
  //   final screenHeight = MediaQuery.of(context).size.height;
  //   final double height = isWide ? screenHeight * 0.3 : screenHeight * 0.15;
  //   return SizedBox(
  //     height: height,
  //     width: double.infinity,
  //     child: ClipRRect(
  //       borderRadius: BorderRadius.circular(16),
  //       child: isWide
  //           ? CachedNetworkImage(
  //               imageUrl: Supabase.instance.client.storage
  //                   .from('imagesentetes')
  //                   .getPublicUrl(imageName),
  //               fit: BoxFit.cover,
  //               placeholder: (context, url) =>
  //                   const Center(child: CircularProgressIndicator()),
  //               errorWidget: (context, url, error) => Icon(
  //                 Icons.error_outline,
  //                 color: Colors.grey.shade400,
  //                 size: 60,
  //               ),
  //               fadeInDuration: const Duration(milliseconds: 300),
  //             )
  //           : Image.asset('assets/images/$imageName', fit: BoxFit.cover),
  //     ),
  //   );
  // }

  Widget _buildModernContent(
    List<Produit> produits,
    List<String> idsPanier, {
    required bool isWideScreen,
  }) {
    if (produits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun article trouvé',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Les produits seront bientôt disponibles',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.rouge,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final int limit = isWideScreen ? 8 : 5;

    final dansBureautique =
        produits.where((p) => p.souscategorie == 'Bureautique').toList()..shuffle();
    final dansReseau =
        produits.where((p) => p.souscategorie == 'Réseau').toList()..shuffle();
    final dansMobiles =
        produits.where((p) => p.souscategorie == 'Appareils Mobiles').toList()..shuffle();
    final dansPopulaires = produits.where((p) => p.vues >= 100).toList()
      ..sort((a, b) => b.vues.compareTo(a.vues));
    final dansAccessoires =
        produits.where((p) => p.souscategorie == 'Accessoires').toList()..shuffle();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Populaires
            if (dansPopulaires.isNotEmpty) ...[
              ProductSection(
                title: isWideScreen ? 'Nos Articles les plus populaires' : 'Articles Populaires',
                subtitle: 'Les plus consultés',
                icon: Icons.trending_up,
                allProduits: dansPopulaires,
                initialLimit: limit,
                isWideScreen: isWideScreen,
                onTogglePanier: _toggleAuPanier,
                onTap:
                    (produit) => Navigator.pushNamed(
                      context,
                      '/utilisateur/produit/details',
                      arguments: produit,
                    ),
                idsPanier: idsPanier,
                onVoirPlus:
                    () => Navigator.pushNamed(
                      context,
                      '/utilisateur/produit/voirplus',
                      arguments: {'title': 'Articles Populaires'},
                    ),
              ),
              const SizedBox(height: 32),
            ],

            // Section Mobiles
            if (dansMobiles.isNotEmpty) ...[
              ProductSection(
                title: isWideScreen ? 'Appareils Mobiles' : 'Appareils de la catégorie Mobile',
                subtitle: 'Tous les derniers gadgets du moment',
                icon: Icons.phone_android,
                allProduits: dansMobiles,
                initialLimit: limit,
                isWideScreen: isWideScreen,
                onTogglePanier: _toggleAuPanier,
                onTap:
                    (produit) => Navigator.pushNamed(
                      context,
                      '/utilisateur/produit/details',
                      arguments: produit,
                    ),
                idsPanier: idsPanier,
                onVoirPlus:
                    () => Navigator.pushNamed(
                      context,
                      '/utilisateur/produit/voirplus',
                      arguments: {'title': 'Appareils Mobiles'},
                    ),
              ),
              const SizedBox(height: 32),
            ],

            // Section Bureautique
            if (dansBureautique.isNotEmpty) ...[
              ProductSection(
                title: isWideScreen ?'Appareils de la catégorie Bureautique' : 'Appareils de Bureautique',
                subtitle: 'Outils de productivité',
                icon: Icons.computer,
                allProduits: dansBureautique,
                initialLimit: limit,
                isWideScreen: isWideScreen,
                onTogglePanier: _toggleAuPanier,
                onTap:
                    (produit) => Navigator.pushNamed(
                      context,
                      '/utilisateur/produit/details',
                      arguments: produit,
                    ),
                idsPanier: idsPanier,
                onVoirPlus:
                    () => Navigator.pushNamed(
                      context,
                      '/utilisateur/produit/voirplus',
                      arguments: {'title': 'Appareils de Bureautique'},
                    ),
              ),
              const SizedBox(height: 32),
            ],

            // Section Réseau
            if (dansReseau.isNotEmpty) ...[
              ProductSection(
                title: isWideScreen ? 'Appareils de la catégorie Réseau' :'Appareils Réseau',
                subtitle: 'Connectivité et communication',
                icon: Icons.network_wifi,
                allProduits: dansReseau,
                initialLimit: limit,
                isWideScreen: isWideScreen,
                onTogglePanier: _toggleAuPanier,
                onTap:
                    (produit) => Navigator.pushNamed(
                      context,
                      '/utilisateur/produit/details',
                      arguments: produit,
                    ),
                idsPanier: idsPanier,
                onVoirPlus:
                    () => Navigator.pushNamed(
                      context,
                      '/utilisateur/produit/voirplus',
                      arguments: {'title': 'Appareils Réseau'},
                    ),
              ),
              const SizedBox(height: 32),
            ],

            // Section Accessoires
            if (dansAccessoires.isNotEmpty) ...[
              ProductSection(
                title: isWideScreen ? 'Appareils de la catégorie des Accessoires' : 'Vos nouveaux Accessoires',
                subtitle: 'Complétez votre équipement',
                icon: Icons.headphones,
                allProduits: dansAccessoires,
                initialLimit: limit,
                isWideScreen: isWideScreen,
                onTogglePanier: _toggleAuPanier,
                onTap:
                    (produit) => Navigator.pushNamed(
                      context,
                      '/utilisateur/produit/details',
                      arguments: produit,
                    ),
                idsPanier: idsPanier,
                onVoirPlus:
                    () => Navigator.pushNamed(
                      context,
                      '/utilisateur/produit/voirplus',
                      arguments: {'title': 'Accessoires'},
                    ),
              ),
            ],
            const SizedBox(height: 20),
            // Footer - moved to the end of scrollable content
            _buildCompanyFooter(),

            // Espace en bas pour le FAB
            // const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyFooter() {
    return Container(
      color: Styles.rouge,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          // Logo and Power by text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/kanjad.png',
                  width: 150,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.business,
                      color: Colors.white,
                      size: 30,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Powered by ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'ROYAL ADVANCED SERVICES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,

                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'crafted with ❤ by ',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        'Mondo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,

                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Address and contact information
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.white.withOpacity(0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Adresse: Akwa Douala - Bar',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '| B.P: 3563 | email: info@royaladservices.net |',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'TEL: +237 233 438 552 | +237 697 537 548',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Copyright
          Text(
            '© 2025 ROYAL ADVANCED SERVICES. Tous droits réservés.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoScrollingImages extends StatefulWidget {
  final List<String> imagePaths;
  const _AutoScrollingImages({required this.imagePaths});

  @override
  _AutoScrollingImagesState createState() => _AutoScrollingImagesState();
}

class _AutoScrollingImagesState extends State<_AutoScrollingImages> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    if (widget.imagePaths.length > 1) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _currentPage = (_currentPage + 1) % widget.imagePaths.length;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.imagePaths.length,
      itemBuilder: (context, index) {
        return Image.asset(widget.imagePaths[index], fit: BoxFit.cover);
      },
    );
  }
}
