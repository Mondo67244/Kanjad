import 'dart:async';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:kanjad/widgets/indicateurdetats.dart';
import 'package:kanjad/widgets/imagekanjad.dart';
import 'package:provider/provider.dart';
import 'package:kanjad/basicdata/produit.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/services/panier/panierprovider.dart';
import 'package:kanjad/widgets/carteproduit.dart';
import 'package:kanjad/widgets/promotionsdynamiques.dart';
import 'package:kanjad/services/promotion/servicepromotion.dart';

class Voirplus extends StatefulWidget {
  final String title;

  const Voirplus({super.key, required this.title});

  @override
  State<Voirplus> createState() => _VoirplusState();
}

class _VoirplusState extends State<Voirplus> with TickerProviderStateMixin {
  late final Stream<List<Produit>> _productStream;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // États pour les filtres et tri
  String _sortBy = 'popularite'; // popularite, prix_asc, prix_desc, nouveau
  String _filterBy = 'tous'; // tous, en_stock, en_promo
  String _searchQuery = '';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _productStream = SupabaseService.instance.getProduitsStreamForSection(
      widget.title,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isSuccess = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: isSuccess ? Styles.vert : Styles.erreur,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(
              isSuccess
                  ? FluentIcons.checkmark_circle_20_regular
                  : FluentIcons.error_circle_20_regular,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Produit> _filterAndSortProducts(List<Produit> products) {
    List<Produit> filtered = List.from(products);

    // Appliquer la recherche
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (product) =>
                    product.nomproduit.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    product.descriptioncourte.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();
    }

    // Appliquer les filtres
    switch (_filterBy) {
      case 'en_stock':
        filtered = filtered.where((product) => product.enstock).toList();
        break;
      case 'en_promo':
        filtered = filtered.where((product) => product.enpromo).toList();
        break;
    }

    // Appliquer le tri
    switch (_sortBy) {
      case 'prix_asc':
        filtered.sort((a, b) => a.prix.compareTo(b.prix));
        break;
      case 'prix_desc':
        filtered.sort((a, b) => b.prix.compareTo(a.prix));
        break;
      case 'nouveau':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'popularite':
      default:
        filtered.sort((a, b) => b.vues.compareTo(a.vues));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: NestedScrollView(
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              SliverAppBar(
                foregroundColor: Styles.blanc,
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: Styles.rouge,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Styles.rouge, Styles.rouge.withOpacity(0.8)],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo et titre
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/kanjad.png',
                              width: 140,
                              height: 50,
                              fit: BoxFit.contain,
                            ),
                            // const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Barre de recherche
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: SizedBox(
                            width: 500,
                            child: TextField(
                              onChanged:
                                  (value) =>
                                      setState(() => _searchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'Rechercher dans ${widget.title}...',
                                prefixIcon: const Icon(
                                  FluentIcons.search_20_regular,
                                  color: Colors.grey,
                                ),
                                suffixIcon:
                                    _searchQuery.isNotEmpty
                                        ? IconButton(
                                          icon: const Icon(
                                            FluentIcons.dismiss_20_regular,
                                            color: Colors.grey,
                                          ),
                                          onPressed:
                                              () => setState(
                                                () => _searchQuery = '',
                                              ),
                                        )
                                        : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Compteur de résultats (sera mis à jour dynamiquement)
                        Expanded(
                          child: StreamBuilder<List<Produit>>(
                            stream: _productStream,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final filtered = _filterAndSortProducts(
                                  snapshot.data!,
                                );
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    '${filtered.length} produit${filtered.length > 1 ? 's' : ''} trouvé${filtered.length > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        // Menu de tri
                        PopupMenuButton<String>(
                          onSelected:
                              (value) => setState(() => _sortBy = value),
                          itemBuilder:
                              (context) => [
                                const PopupMenuItem(
                                  value: 'popularite',
                                  child: Text('Popularité'),
                                ),
                                const PopupMenuItem(
                                  value: 'prix_asc',
                                  child: Text('Prix croissant'),
                                ),
                                const PopupMenuItem(
                                  value: 'prix_desc',
                                  child: Text('Prix décroissant'),
                                ),
                                const PopupMenuItem(
                                  value: 'nouveau',
                                  child: Text('Nouveautés'),
                                ),
                              ],
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                // Bouton filtres
                                IconButton(
                                  onPressed:
                                      () => setState(
                                        () => _showFilters = !_showFilters,
                                      ),
                                  icon: Icon(
                                    _showFilters
                                        ? FluentIcons.filter_dismiss_20_regular
                                        : FluentIcons.filter_20_regular,
                                    color: Styles.rouge,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  FluentIcons.arrow_sort_20_regular,
                                  color: Styles.rouge,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getSortLabel(),
                                  style: TextStyle(
                                    color: Styles.rouge,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                _buildMainContent(constraints),
                // Filtres overlay
                if (_showFilters) _buildFiltersOverlay(),
              ],
            );
          },
        ),
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'prix_asc':
        return 'Prix ↑';
      case 'prix_desc':
        return 'Prix ↓';
      case 'nouveau':
        return 'Nouveau';
      case 'popularite':
      default:
        return 'Popularité';
    }
  }

  Widget _buildMainContent(BoxConstraints constraints) {
    final screenWidth = constraints.maxWidth;
    if (screenWidth > 1300) {
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: DynamicPromotionImages(
                  cote: 'gauche',
                  promotionService: PromotionService(),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: _buildProductGridWithFilters(isWideScreen: true),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: DynamicPromotionImages(
                  cote: 'droite',
                  promotionService: PromotionService(),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return _buildProductGridWithFilters(isWideScreen: screenWidth > 600);
  }

  Widget _buildProductGridWithFilters({required bool isWideScreen}) {
    final panierProvider = context.watch<PanierProvider>();
    return StreamBuilder<List<Produit>>(
      stream: _productStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: const LoadingIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FluentIcons.error_circle_20_regular,
                  size: 64,
                  color: Styles.erreur,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Styles.erreur,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Veuillez réessayer plus tard',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Styles.rouge,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FluentIcons.box_24_regular,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun produit trouvé',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cette section sera bientôt remplie',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        final filteredProducts = _filterAndSortProducts(snapshot.data!);

        if (filteredProducts.isEmpty) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FluentIcons.search_24_regular,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun résultat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Essayez de modifier vos filtres',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _filterBy = 'tous';
                        _sortBy = 'popularite';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Styles.rouge,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Réinitialiser'),
                  ),
                ],
              ),
            ),
          );
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Container(
              constraints:
                  isWideScreen
                      ? const BoxConstraints(maxWidth: 1200)
                      : const BoxConstraints(maxWidth: 600),
              child:
                  isWideScreen
                      ? GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 320,
                              childAspectRatio: 0.84,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final produit = filteredProducts[index];
                          final bool isPanier = panierProvider
                              .isProduitInPanier(produit.idproduit);
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: ProductCard(
                              produit: produit,
                              isPanier: isPanier,
                              isWideScreen: isWideScreen,
                              onTogglePanier: () async {
                                final result = await panierProvider.clicPanier(
                                  produit.idproduit,
                                );
                                _showSnackBar(
                                  result['message'],
                                  isSuccess: result['success'],
                                );
                              },
                              onTap:
                                  () => Navigator.pushNamed(
                                    context,
                                    '/utilisateur/produit/details',
                                    arguments: produit,
                                  ),
                            ),
                          );
                        },
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final produit = filteredProducts[index];
                          final bool isPanier = panierProvider
                              .isProduitInPanier(produit.idproduit);
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: _buildHorizontalCard(
                              context,
                              produit,
                              panierProvider,
                              isPanier,
                            ),
                          );
                        },
                      ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHorizontalCard(
    BuildContext context,
    Produit produit,
    PanierProvider panierProvider,
    bool isPanier,
  ) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            () => Navigator.pushNamed(
              context,
              '/utilisateur/produit/details',
              arguments: produit,
            ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image du produit
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: KanjadImage(
                    imageData: produit.img1,
                    sousCategorie: produit.souscategorie,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Informations du produit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom du produit (2 lignes max)
                    Text(
                      produit.nomproduit,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Description courte
                    Text(
                      produit.descriptioncourte,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Prix
                    Row(
                      children: [
                        Text(
                          '${produit.prix.toStringAsFixed(0)} CFA',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                        if (produit.enpromo) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${produit.ancientprix.toStringAsFixed(0)} CFA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Colonne avec statut et bouton
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  // Chip de statut
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          produit.enstock
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            produit.enstock
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                      ),
                    ),
                    child: Text(
                      produit.enstock ? 'En stock' : 'Rupture',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color:
                            produit.enstock
                                ? Colors.green.shade600
                                : Colors.red.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Bouton d'action
                  SizedBox(
                    width: 120,
                    child: ElevatedButton.icon(
                      onPressed:
                          produit.enstock
                              ? () async {
                                final result = await panierProvider.clicPanier(
                                  produit.idproduit,
                                );
                                _showSnackBar(
                                  result['message'],
                                  isSuccess: result['success'],
                                );
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            produit.enstock
                                ? (isPanier ? Colors.blue.shade50 : Styles.bleu)
                                : Colors.red.shade100,
                        foregroundColor:
                            produit.enstock
                                ? (isPanier ? Styles.bleu : Colors.white)
                                : Styles.rouge,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        isPanier
                            ? FluentIcons.shopping_bag_tag_24_filled
                            : FluentIcons.shopping_bag_tag_24_regular,
                        size: 16,
                      ),
                      label: Text(
                        produit.enstock
                            ? (isPanier ? 'Ajouté' : 'Ajouter')
                            : 'Indisponible',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersOverlay() {
    return AnimatedOpacity(
      opacity: _showFilters ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: () => setState(() => _showFilters = false),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 300,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Styles.rouge,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          FluentIcons.filter_20_regular,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Filtres',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => setState(() => _showFilters = false),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  // Filtres
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Disponibilité',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        RadioListTile<String>(
                          title: const Text('Tous les produits'),
                          value: 'tous',
                          groupValue: _filterBy,
                          onChanged:
                              (value) => setState(() => _filterBy = value!),
                          activeColor: Styles.rouge,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        RadioListTile<String>(
                          title: const Text('En stock uniquement'),
                          value: 'en_stock',
                          groupValue: _filterBy,
                          onChanged:
                              (value) => setState(() => _filterBy = value!),
                          activeColor: Styles.rouge,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        RadioListTile<String>(
                          title: const Text('En promotion'),
                          value: 'en_promo',
                          groupValue: _filterBy,
                          onChanged:
                              (value) => setState(() => _filterBy = value!),
                          activeColor: Styles.rouge,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _filterBy = 'tous';
                                    _searchQuery = '';
                                    _sortBy = 'popularite';
                                  });
                                  _showFilters = false;
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade200,
                                  foregroundColor: Colors.black87,
                                  elevation: 0,
                                ),
                                child: const Text('Réinitialiser'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    () => setState(() => _showFilters = false),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Styles.rouge,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                ),
                                child: const Text('Appliquer'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
