import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:RAS/basicdata/produit.dart';
import 'package:RAS/basicdata/style.dart';
import 'package:RAS/services/BD/lienbd.dart';
import 'package:RAS/services/panier/panier_local.dart';
import 'package:RAS/services/souhaits/souhaits_local.dart';
import 'package:provider/provider.dart';
import 'package:RAS/services/synchronisation/notification_service.dart';

class souhaits extends StatefulWidget {
  const souhaits({super.key});

  @override
  State<souhaits> createState() => SouhaitsState();
}

class SouhaitsState extends State<souhaits>
    with AutomaticKeepAliveClientMixin<souhaits> {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  late Stream<List<Produit>> _wishlistStream;
  final SouhaitsLocal _souhaitsLocal = SouhaitsLocal();
  final PanierLocal _panierLocal = PanierLocal();

  List<String> _idsSouhaits = [];
  List<String> _idsPanier = [];
  bool _isLoading = true;
  late Future<void> _initFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _wishlistStream = _databaseService.getProduitsStream();
    _initFuture = _initSouhaitsLocal();
    _initPanierLocal();
  }

  @override
  void didUpdateWidget(covariant souhaits oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _actualiser() async {
    setState(() {
      _isLoading = true;
    });
    await _initSouhaitsLocal();
    await _initPanierLocal();
    setState(() {
      _isLoading = false;
    });

    // Refresh notification service
    if (mounted) {
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      notificationService.refreshWishlistCount();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Liste de souhaits mise à jour !'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _initSouhaitsLocal() async {
    await _souhaitsLocal.init();
    final ids = await _souhaitsLocal.getSouhaits();
    setState(() {
      _idsSouhaits = ids;
      _isLoading = false;
    });

    // Refresh notification service
    if (mounted) {
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      notificationService.refreshWishlistCount();
    }
  }

  Future<void> _initPanierLocal() async {
    await _panierLocal.init();
    final ids = await _panierLocal.getPanier();
    setState(() {
      _idsPanier = ids;
    });
  }

  void _toggleJeVeut(Produit produit) async {
    final bool isCurrentlyWished = _idsSouhaits.contains(produit.idProduit);

    // Update UI immediately for better user experience
    setState(() {
      if (isCurrentlyWished) {
        _idsSouhaits.remove(produit.idProduit);
      } else {
        _idsSouhaits.add(produit.idProduit);
      }
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Connected state - update database
        if (isCurrentlyWished) {
          await _databaseService.retirerDesSouhaits(user.id, produit.idProduit);
        } else {
          await _databaseService.ajouterAuxSouhaits(user.id, produit.idProduit);
        }
      }

      // Always update local storage
      if (isCurrentlyWished) {
        await _souhaitsLocal.retirerDesSouhaits(produit.idProduit);
      } else {
        await _souhaitsLocal.ajouterAuxSouhaits(produit.idProduit);
      }

      _messageReponse(
        isCurrentlyWished
            ? '${produit.nomProduit} retiré de vos souhaits'
            : '${produit.nomProduit} ajouté à vos souhaits',
        isSuccess: !isCurrentlyWished,
      );

      // Refresh notification service
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      notificationService.refreshWishlistCount();
    } catch (e) {
      // Revert UI changes if operation fails
      setState(() {
        if (isCurrentlyWished) {
          _idsSouhaits.add(produit.idProduit);
        } else {
          _idsSouhaits.remove(produit.idProduit);
        }
      });
      _messageReponse(
        'Erreur lors de la modification des souhaits',
        isSuccess: false,
        icon: Icons.error,
      );
    }
  }

  void _deleteProduct(Produit produit) async {
    final bool wasInWishlist = _idsSouhaits.contains(produit.idProduit);

    // Update UI immediately
    setState(() {
      _idsSouhaits.remove(produit.idProduit);
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Connected state - remove from database
        await _databaseService.retirerDesSouhaits(user.id, produit.idProduit);
      }

      // Always remove from local storage
      await _souhaitsLocal.retirerDesSouhaits(produit.idProduit);

      _messageReponse(
        '${produit.nomProduit} supprimé de vos souhaits',
        isSuccess: true,
        icon: FluentIcons.delete_24_regular,
      );

      // Refresh notification service
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      notificationService.refreshWishlistCount();
    } catch (e) {
      // Revert UI changes if operation fails
      setState(() {
        if (wasInWishlist && !_idsSouhaits.contains(produit.idProduit)) {
          _idsSouhaits.add(produit.idProduit);
        }
      });
      _messageReponse(
        'Erreur lors de la suppression du produit',
        isSuccess: false,
        icon: Icons.error,
      );
    }
  }

  Future<void> _togglePanier(Produit produit) async {
    if (_idsPanier.contains(produit.idProduit)) {
      await _panierLocal.retirerDuPanier(produit.idProduit);
      _messageReponse(
        '${produit.nomProduit} retiré du panier',
        isSuccess: false,
        icon: Icons.remove_shopping_cart_outlined,
      );
    } else {
      await _panierLocal.ajouterAuPanier(produit.idProduit);
      _messageReponse(
        '${produit.nomProduit} ajouté au panier',
        isSuccess: true,
        icon: Icons.add_shopping_cart_outlined,
      );
    }
    _initPanierLocal();

    // Refresh notification service
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );
    notificationService.refreshCartCount();
  }

  void _messageReponse(
    String message, {
    bool isSuccess = true,
    IconData? icon,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: isSuccess ? Styles.vert : Styles.erreur,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(message, style: Styles.textebas)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: _actualiser,
      child: FutureBuilder(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          return StreamBuilder<List<Produit>>(
            stream: _wishlistStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final produits = snapshot.data!;
              final produitsFiltres =
                  produits
                      .where(
                        (produit) => _idsSouhaits.contains(produit.idProduit),
                      )
                      .toList();

              // Check if wishlist is empty (either no products in wishlist or no products at all)
              if (produitsFiltres.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FluentIcons.heart_24_regular,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Votre liste de souhaits est vide',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajoutez des articles à votre liste de souhaits\npour les retrouver ici',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _actualiser,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Styles.rouge,
                          side: BorderSide(color: Styles.rouge),
                        ),
                        child: const Text('Actualiser'),
                      ),
                    ],
                  ),
                );
              }

              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 300,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: produitsFiltres.length,
                      itemBuilder: (context, index) {
                        return _produit(produitsFiltres[index]);
                      },
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      heroTag: "souhaits_refresh",
                      onPressed: _actualiser,
                      backgroundColor: Styles.rouge,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.refresh),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _produit(Produit produit) {
    return Container(
      decoration: BoxDecoration(
        color: Styles.blanc,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    image:
                        produit.img1.isNotEmpty
                            ? DecorationImage(
                              image:
                                  produit.img1.startsWith('http')
                                      ? NetworkImage(produit.img1)
                                      : MemoryImage(
                                            base64Decode(
                                              produit.img1.split(',').last,
                                            ),
                                          )
                                          as ImageProvider,
                              fit: BoxFit.cover,
                            )
                            : null,
                    color: Styles.blanc,
                  ),
                  child:
                      produit.img1.isEmpty
                          ? const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: Colors.grey,
                            ),
                          )
                          : null,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white70,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                          icon: Icon(
                            _idsSouhaits.contains(produit.idProduit)
                                ? FluentIcons.heart_24_filled
                                : FluentIcons.heart_24_regular,
                            color:
                                _idsSouhaits.contains(produit.idProduit)
                                    ? Styles.rouge
                                    : Colors.grey,
                          ),
                          onPressed: () => _toggleJeVeut(produit),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                          icon: const Icon(
                            FluentIcons.delete_24_regular,
                            color: Colors.white,
                          ),
                          onPressed: () => _deleteProduct(produit),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produit.nomProduit,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${produit.prix} CFA',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _idsPanier.contains(produit.idProduit)
                                  ? Styles.bleu
                                  : Styles.rouge,
                          foregroundColor: Styles.blanc,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _togglePanier(produit),
                        child: Text(
                          _idsPanier.contains(produit.idProduit)
                              ? 'Ajouté'
                              : 'Ajouter',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
