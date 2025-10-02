import 'package:kanjad/services/panier/panierprovider.dart';
import 'package:kanjad/services/souhaits/souhaitsprovider.dart';
import 'package:kanjad/services/providers/produitprovider.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:kanjad/basicdata/produit.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/utilitaires/servicemessagerie.dart';
import 'package:kanjad/widgets/indicateurdetats.dart';
import 'package:kanjad/widgets/imagekanjad.dart';
import 'package:kanjad/widgets/suggestionsproduits.dart';
import 'package:provider/provider.dart';

class SouhaitsPage extends StatefulWidget {
  const SouhaitsPage({super.key});

  @override
  State<SouhaitsPage> createState() => _SouhaitsPageState();
}

class _SouhaitsPageState extends State<SouhaitsPage>
    with AutomaticKeepAliveClientMixin<SouhaitsPage>, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _actualiser() async {
    await Future.wait([
      Provider.of<ProductProvider>(
        context,
        listen: false,
      ).loadProducts(forceRefresh: true),
      Provider.of<PanierProvider>(context, listen: false).loadPanier(),
      Provider.of<SouhaitsProvider>(context, listen: false).loadSouhaits(),
    ]);
    if (mounted) {
      MessagerieService.showInfo(context, 'Liste de souhaits mise à jour !');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
                                'Mes Souhaits',
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
                          onPressed: _actualiser,
                          icon: Icon(
                            FluentIcons.arrow_sync_20_regular,
                            color: Styles.rouge,
                          ),
                          tooltip: 'Actualiser',
                        ),
                        // Titre de la section
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Vos produits préférés',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        // Bouton de tri (optionnel)
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            // Logique de tri si nécessaire
                          },
                          itemBuilder:
                              (context) => [
                                const PopupMenuItem(
                                  value: 'date',
                                  child: Text('Par date d\'ajout'),
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
                                  value: 'nom',
                                  child: Text('Par nom'),
                                ),
                              ],
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Icon(
                                  FluentIcons.arrow_sort_20_regular,
                                  color: Styles.rouge,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Trier',
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
        body: RefreshIndicator(
          onRefresh: _actualiser,
          child: Consumer3<ProductProvider, SouhaitsProvider, PanierProvider>(
            builder: (
              context,
              productProvider,
              souhaitsProvider,
              panierProvider,
              child,
            ) {
              if (productProvider.isLoading &&
                  productProvider.products.isEmpty) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: const LoadingIndicator(),
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
                          FluentIcons.error_circle_20_regular,
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
                          onPressed: _actualiser,
                          icon: const Icon(FluentIcons.arrow_sync_20_regular),
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

              final allProduits = productProvider.products;
              final produitsFiltres =
                  allProduits
                      .where(
                        (produit) => souhaitsProvider.idsSouhaits.contains(
                          produit.idproduit,
                        ),
                      )
                      .toList();

              if (produitsFiltres.isEmpty) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FluentIcons.heart_24_regular,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Votre liste de souhaits est vide',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ajoutez des produits qui vous intéressent',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/'),
                          icon: const Icon(FluentIcons.search_20_regular),
                          label: const Text('Découvrir des produits'),
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
                  final isWideScreen = constraints.maxWidth > 900;
                  if (isWideScreen) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildModernWishlistContent(
                              produitsFiltres,
                              panierProvider,
                              souhaitsProvider,
                              true,
                            ),
                          ),
                        ),
                        const VerticalDivider(
                          width: 1,
                          color: Color(0xFFEEEEEE),
                        ),
                        Expanded(
                          flex: 1,
                          child: _buildModernSuggestions(
                            produitsFiltres,
                            allProduits,
                            souhaitsProvider,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildModernWishlistContent(
                        produitsFiltres,
                        panierProvider,
                        souhaitsProvider,
                        false,
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


  Widget _buildModernWishlistContent(
    List<Produit> produitsFiltres,
    PanierProvider panierProvider,
    SouhaitsProvider souhaitsProvider,
    bool isWideScreen,
  ) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child:
            isWideScreen
                ? GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: produitsFiltres.length,
                  itemBuilder: (context, index) {
                    return _buildModernWishlistCard(
                      produitsFiltres[index],
                      panierProvider,
                      souhaitsProvider,
                    );
                  },
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: produitsFiltres.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildModernWishlistCard(
                        produitsFiltres[index],
                        panierProvider,
                        souhaitsProvider,
                      ),
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildModernWishlistCard(
    Produit produit,
    PanierProvider panierProvider,
    SouhaitsProvider souhaitsProvider,
  ) {
    final bool isInCart = panierProvider.isProduitInPanier(produit.idproduit);

    return Card(
      color: Colors.white,
      elevation: 3,
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
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image avec indicateurs
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: KanjadImage(
                        imageData: produit.img1,
                        sousCategorie: produit.souscategorie,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (produit.enpromo)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PROMO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (!produit.enstock)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'RUPTURE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 16),

              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Nom du produit
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

                    // Catégorie et type
                    Text(
                      '${produit.categorie} • ${produit.type}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Prix
                    Row(
                      children: [
                        Text(
                          '${produit.prix.toStringAsFixed(0)} CFA',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                        if (produit.enpromo) ...[
                          const SizedBox(width: 8),
                          Text(
                            produit.ancientprix.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Actions
                    Row(
                      children: [
                        // Bouton panier
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed:
                                produit.enstock
                                    ? () async {
                                      final result = await panierProvider
                                          .clicPanier(produit.idproduit);
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(result['message']),
                                            backgroundColor:
                                                result['success']
                                                    ? Colors.green
                                                    : Styles.erreur,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  produit.enstock
                                      ? (isInCart
                                          ? Colors.blue.shade50
                                          : Styles.bleu)
                                      : Colors.red.shade100,
                              foregroundColor:
                                  produit.enstock
                                      ? (isInCart ? Styles.bleu : Colors.white)
                                      : Styles.rouge,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: Icon(
                              isInCart
                                  ? FluentIcons.shopping_bag_tag_24_filled
                                  : FluentIcons.shopping_bag_tag_24_regular,
                              size: 16,
                            ),
                            label: Text(
                              produit.enstock
                                  ? (isInCart ? 'Ajouté' : 'Ajouter')
                                  : 'Indisponible',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Bouton supprimer des souhaits
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            onPressed: () async {
                              final result = await souhaitsProvider.clicSouhait(
                                produit.idproduit,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message']),
                                    backgroundColor: Colors.blue,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(
                              FluentIcons.heart_off_20_regular,
                              color: Colors.red,
                            ),
                            tooltip: 'Retirer des souhaits',
                            padding: const EdgeInsets.all(8),
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
    );
  }

  Widget _buildModernSuggestions(
    List<Produit> produitsSouhaits,
    List<Produit> allProduits,
    SouhaitsProvider souhaitsProvider,
  ) {
    final categoriesInWishlist =
        produitsSouhaits.map((p) => p.categorie).toSet();

    final suggestions =
        allProduits.where((p) {
          return categoriesInWishlist.contains(p.categorie) &&
              !produitsSouhaits.any((ps) => ps.idproduit == p.idproduit);
        }).toList();

    if (suggestions.isEmpty) {
      return Container(
        color: const Color(0xFFF8F9FA),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FluentIcons.lightbulb_24_regular,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Suggestions intelligentes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Découvrez d\'autres produits similaires',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  FluentIcons.lightbulb_20_regular,
                  color: Styles.rouge,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Vous pourriez aimer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Liste des suggestions
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final produit = suggestions[index];
                return Container(
                  key: ValueKey(produit.idproduit),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap:
                        () => Navigator.pushNamed(
                          context,
                          '/utilisateur/produit/details',
                          arguments: produit,
                        ),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: KanjadImage(
                                imageData: produit.img1,
                                sousCategorie: produit.souscategorie,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Contenu
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  produit.nomproduit,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${produit.prix.toStringAsFixed(0)} CFA',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Bouton d'action
                          IconButton(
                            onPressed:
                                () => souhaitsProvider.clicSouhait(
                                  produit.idproduit,
                                ),
                            icon: Icon(
                              souhaitsProvider.isProduitInSouhaits(
                                    produit.idproduit,
                                  )
                                  ? FluentIcons.heart_20_filled
                                  : FluentIcons.heart_20_regular,
                              color:
                                  souhaitsProvider.isProduitInSouhaits(
                                        produit.idproduit,
                                      )
                                      ? Colors.red
                                      : Colors.grey,
                              size: 20,
                            ),
                            tooltip: 'Ajouter aux souhaits',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _SuggestionsSouhaits extends StatelessWidget {
  final List<Produit> produitsSouhaits;
  final List<Produit> allProduits;

  const _SuggestionsSouhaits({
    required this.produitsSouhaits,
    required this.allProduits,
  });

  @override
  Widget build(BuildContext context) {
    final souhaitsProvider = context.watch<SouhaitsProvider>();
    final categoriesInWishlist =
        produitsSouhaits.map((p) => p.categorie).toSet();

    final suggestions =
        allProduits.where((p) {
          return categoriesInWishlist.contains(p.categorie) &&
              !produitsSouhaits.any((ps) => ps.idproduit == p.idproduit);
        }).toList();

    if (suggestions.isEmpty) {
      return const Center(child: Text('Aucune suggestion pour le moment.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Ceci pourrait vous plaire',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final produit = suggestions[index];
              return ProduitSuggestionCard(
                produit: produit,
                isActionDone: souhaitsProvider.isProduitInSouhaits(
                  produit.idproduit,
                ),
                actionText: 'Je souhaite',
                doneText: 'Souhaité',
                actionIcon: FluentIcons.heart_24_regular,
                doneIcon: FluentIcons.heart_24_filled,
                onAction: () {
                  souhaitsProvider.clicSouhait(produit.idproduit);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
