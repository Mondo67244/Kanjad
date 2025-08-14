import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:RAS/basicdata/produit.dart';
import 'package:RAS/basicdata/style.dart';
import 'package:RAS/widgets/carteProduit.dart';

class ProductSection extends StatelessWidget {
  final String title;
  final List<Produit> produits;
  final bool isWideScreen;
  final Function(Produit) onTogglePanier;
  final Function(Produit) onTap;
  final List<String> idsPanier;

  const ProductSection({
    super.key,
    required this.title,
    required this.produits,
    required this.isWideScreen,
    required this.onTogglePanier,
    required this.onTap,
    required this.idsPanier,
  });

  @override
  Widget build(BuildContext context) {
    if (produits.isEmpty) return const SizedBox.shrink();

    final ScrollController scrollController = ScrollController();
    final double cardWidth = isWideScreen ? 290 : 280;

    void scrollCards(int direction) {
      final double scrollAmount = cardWidth * 2 * direction;
      final double maxScroll = scrollController.position.maxScrollExtent;
      final double currentScroll = scrollController.offset;
      final double targetScroll = (currentScroll + scrollAmount).clamp(
        0.0,
        maxScroll,
      );

      scrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    FluentIcons.arrow_right_24_filled,
                    color: Styles.bleu,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/utilisateur/produit/voirplus',
                    arguments: {'title': title, 'produits': produits},
                  );
                },
                child: Text(
                  'Voir plus',
                  style: TextStyle(
                    color: Styles.rouge,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: isWideScreen ? 360 : 330,
              child: ListView.builder(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: produits.length,
                itemBuilder: (context, index) {
                  final produit = produits[index];
                  final bool isPanier = idsPanier.contains(produit.idProduit);
                  return ProductCard(
                    produit: produit,
                    isPanier: isPanier,
                    isWideScreen: isWideScreen,
                    onTogglePanier: () => onTogglePanier(produit),
                    onTap: () => onTap(produit),
                  );
                },
              ),
            ),
            if (produits.length >= 4)
              Positioned(
                left: 0,
                child: _navButton(
                  icon: Icons.arrow_back_ios_new,
                  onPressed: () => scrollCards(-1),
                ),
              ),
            if (produits.length >= 4)
              Positioned(
                right: 0,
                child: _navButton(
                  icon: Icons.arrow_forward_ios,
                  onPressed: () => scrollCards(1),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _navButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.2 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onPressed,
      ),
    );
  }
}
