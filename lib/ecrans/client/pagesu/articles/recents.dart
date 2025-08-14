import 'package:RAS/widgets/SectionProduit.dart';
import 'package:flutter/material.dart';
import 'package:RAS/basicdata/produit.dart';
import 'package:RAS/basicdata/style.dart';
import 'package:RAS/services/BD/lienbd.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:RAS/services/panier/panier_local.dart';

class Recents extends StatefulWidget {
  const Recents({super.key});

  @override
  State<Recents> createState() => RecentsState();
}

class RecentsState extends State<Recents>
    with AutomaticKeepAliveClientMixin<Recents> {
  late Stream<List<Produit>> _produitsStream;
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  final PanierLocal _panierLocal = PanierLocal();
  List<String> _idsPanier = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _produitsStream = _databaseService.getProduitsStream();
    _initPanierLocal();
  }

  Future<void> _initPanierLocal() async {
    await _panierLocal.init();
    final ids = await _panierLocal.getPanier();
    if (mounted) {
      setState(() {
        _idsPanier = ids;
      });
    }
  }

  Future<void> _toggleAuPanier(Produit produit) async {
    try {
      if (_idsPanier.contains(produit.idProduit)) {
        await _panierLocal.retirerDuPanier(produit.idProduit);
        if (mounted) {
          setState(() {
            _idsPanier.remove(produit.idProduit);
          });
        }
      } else {
        await _panierLocal.ajouterAuPanier(produit.idProduit);
        if (mounted) {
          setState(() {
            _idsPanier.add(produit.idProduit);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _refreshData() async {
    if (mounted) {
      setState(() {
        _produitsStream = _databaseService.getProduitsStream();
        _initPanierLocal();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Styles.bleu,
            content: Text('Page actualisée !'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: Builder(
        builder: (context) {
          return FloatingActionButton(
            heroTag: "recents_menu",
            onPressed: () {
              final RenderBox renderBox =
                  context.findRenderObject() as RenderBox;
              final Offset offset = renderBox.localToGlobal(Offset.zero);
              showMenu<String>(
                context: context,
                position: RelativeRect.fromLTRB(
                  offset.dx,
                  offset.dy - 140,
                  offset.dx + renderBox.size.width,
                  offset.dy,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                items: [
                  PopupMenuItem(
                    value: 'rechercher',
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.search),
                      title: const Text('Rechercher'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'actualiser',
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.refresh),
                      title: const Text('Actualiser'),
                    ),
                  ),
                ],
              ).then((value) {
                if (value == 'rechercher') {
                  Navigator.pushNamed(context, '/utilisateur/recherche');
                } else if (value == 'actualiser') {
                  _refreshData();
                }
              });
            },
            backgroundColor: const Color.fromARGB(255, 163, 14, 3),
            tooltip: 'Options',
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
      ),
      body: StreamBuilder<List<Produit>>(
        stream: _produitsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Styles.rouge),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur: ${snapshot.error}',
                style: TextStyle(color: Styles.erreur, fontSize: 16),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delivery_dining_outlined,
                    size: 150,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun article trouvé',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }
          final produits = snapshot.data!;
          return LayoutBuilder(
            builder: (context, constraints) {
              final bool isWideScreen = constraints.maxWidth > 600;
              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 950),
                  child: _contenu(produits, isWideScreen: isWideScreen),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Construit l'en-tête avec des images (locales ou réseau)
  Widget _imagesEntetes(String path, {required bool isWide}) {
    return SizedBox(
      height: isWide ? 150 : 100,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child:
            isWide
                ? CachedNetworkImage(
                  imageUrl: path,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                  errorWidget:
                      (context, url, error) => Icon(
                        Icons.error_outline,
                        color: Colors.grey.shade400,
                        size: 60,
                      ),
                  fadeInDuration: const Duration(milliseconds: 300),
                )
                : Image.asset(path, fit: BoxFit.cover),
      ),
    );
  }

  /// Construit le contenu principal avec les  sections de produits
  Widget _contenu(List<Produit> produits, {required bool isWideScreen}) {
    final produitsBureautique =
        produits.where((p) => p.sousCategorie == 'Bureautique').toList();
    final produitsReseau =
        produits.where((p) => p.sousCategorie == 'Réseau').toList();
    final produitsMobiles =
        produits.where((p) => p.sousCategorie == 'Appareils Mobiles').toList();

    final produitsPopulaires =
        produits.where((p) => (int.tryParse(p.vues) ?? 0) > 15).toList();
    final produitsAccessoires =
        produits.where((p) => p.sousCategorie == 'Accessoires').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isWideScreen
              ? const Text('')
              : _imagesEntetes('assets/images/PG2.png', isWide: isWideScreen),
          ProductSection(
            title: 'Articles Populaires',
            produits: produitsPopulaires,
            isWideScreen: isWideScreen,
            onTogglePanier: _toggleAuPanier,
            onTap: (produit) {
              Navigator.pushNamed(
                context,
                '/utilisateur/produit/details',
                arguments: produit,
              );
            },
            idsPanier: _idsPanier,
          ),
          const SizedBox(height: 24),
          isWideScreen
              ? const Text('')
              : _imagesEntetes('assets/images/BG.png', isWide: isWideScreen),
          const SizedBox(height: 24),
          ProductSection(
            title: 'Appareils de Bureautique',
            produits: produitsBureautique,
            isWideScreen: isWideScreen,
            onTogglePanier: _toggleAuPanier,
            onTap: (produit) {
              Navigator.pushNamed(
                context,
                '/utilisateur/produit/details',
                arguments: produit,
              );
            },
            idsPanier: _idsPanier,
          ),
          const SizedBox(height: 24),
          isWideScreen
              ? const Text('')
              : _imagesEntetes('assets/images/RG.png', isWide: isWideScreen),
          const SizedBox(height: 24),
          ProductSection(
            title: 'Appareils Réseau',
            produits: produitsReseau,
            isWideScreen: isWideScreen,
            onTogglePanier: _toggleAuPanier,
            onTap: (produit) {
              Navigator.pushNamed(
                context,
                '/utilisateur/produit/details',
                arguments: produit,
              );
            },
            idsPanier: _idsPanier,
          ),
          const SizedBox(height: 24),
          isWideScreen
              ? const Text('')
              : _imagesEntetes('assets/images/EG2.png', isWide: isWideScreen),
          ProductSection(
            title: 'Appareils Mobiles',
            produits: produitsMobiles,
            isWideScreen: isWideScreen,
            onTogglePanier: _toggleAuPanier,
            onTap: (produit) {
              Navigator.pushNamed(
                context,
                '/utilisateur/produit/details',
                arguments: produit,
              );
            },
            idsPanier: _idsPanier,
          ),
          const SizedBox(height: 24),
          isWideScreen
              ? const Text('')
              : _imagesEntetes('assets/images/AG.png', isWide: isWideScreen),
          ProductSection(
            title: 'Accessoires',
            produits: produitsAccessoires,
            isWideScreen: isWideScreen,
            onTogglePanier: _toggleAuPanier,
            onTap: (produit) {
              Navigator.pushNamed(
                context,
                '/utilisateur/produit/details',
                arguments: produit,
              );
            },
            idsPanier: _idsPanier,
          ),
        ],
      ),
    );
  }
}
