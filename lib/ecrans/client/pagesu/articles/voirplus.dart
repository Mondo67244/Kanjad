import 'package:flutter/material.dart';
import 'package:RAS/basicdata/produit.dart';
import 'package:RAS/basicdata/style.dart';
import 'package:RAS/services/panier/panier_local.dart';
import 'package:RAS/services/souhaits/souhaits_local.dart';
import 'package:RAS/widgets/carteProduit.dart';

class Voirplus extends StatefulWidget {
  final String title;
  final List<Produit> produits;

  const Voirplus({super.key, required this.title, required this.produits});

  @override
  State<Voirplus> createState() => _VoirplusState();
}

class _VoirplusState extends State<Voirplus> {
  final PanierLocal _panierLocal = PanierLocal();
  final SouhaitsLocal _souhaitsLocal = SouhaitsLocal();

  List<String> _idsPanier = [];
  List<String> _idsSouhaits = [];
  late List<Produit> _produits;

  @override
  void initState() {
    super.initState();
    _produits = widget.produits;
    _initLocalData();
  }

  Future<void> _initLocalData() async {
    await _panierLocal.init();
    await _souhaitsLocal.init();
    final panierIds = await _panierLocal.getPanier();
    final souhaitsIds = await _souhaitsLocal.getSouhaits();
    if (mounted) {
      setState(() {
        _idsPanier = panierIds;
        _idsSouhaits = souhaitsIds;
      });
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
    _initLocalData();
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
    final screenWidth = MediaQuery.of(context).size.width;
    bool isWideScreen = screenWidth > 450;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/kanjad.png',
              key: const ValueKey('logo'),
              width: 140,
              height: 50,
            ),
            Transform.translate(
              offset: const Offset(-20, 12),
              child: Text(
                widget.title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Styles.rouge,
        foregroundColor: Styles.blanc,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      backgroundColor: Styles.blanc,
      body: Center(
        child:
            _produits.isEmpty
                ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Aucun produit dans cette section.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
                : Container(
                  constraints:
                      isWideScreen
                          ? BoxConstraints(maxWidth: 900)
                          : BoxConstraints(maxWidth: 280),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 300,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 5,
                    ),
                    itemCount: _produits.length,
                    itemBuilder: (context, index) {
                      final produit = _produits[index];
                      final bool isPanier = _idsPanier.contains(
                        produit.idProduit,
                      );
                      return ProductCard(
                        produit: produit,
                        isPanier: isPanier,
                        isWideScreen: isWideScreen,
                        onTogglePanier: () => _togglePanier(produit),
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              '/utilisateur/produit/details',
                              arguments: produit,
                            ),
                      );
                    },
                  ),
                ),
      ),
    );
  }
}
