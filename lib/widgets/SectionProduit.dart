import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/produit.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/widgets/carteproduit.dart';

class ProductSection extends StatelessWidget {
  final String title;
  final List<Produit> produits;
  final bool isWideScreen;
  final Function(Produit) onTogglePanier;
  final Function(Produit) onTap;
  final List<String> idsPanier;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final IconData? icon;
  final String? subtitle;
  final VoidCallback? onVoirPlus;

  const ProductSection({
    super.key,
    required this.title,
    required this.produits,
    required this.isWideScreen,
    required this.onTogglePanier,
    required this.onTap,
    required this.idsPanier,
    this.onLoadMore,
    this.hasMore = false,
    this.icon,
    this.subtitle,
    this.onVoirPlus,
  });

  @override
  Widget build(BuildContext context) {
    if (produits.isEmpty) return const SizedBox.shrink();

    final ScrollController scrollController = ScrollController();
    final double cardWidth =
        isWideScreen ? 200 : 180; // Reduced width to fit more cards per row

    void scrollCards(int direction) {
      final double scrollAmount = cardWidth * 2 * direction;
      final double maxScroll = scrollController.position.maxScrollExtent;
      final double currentScroll = scrollController.offset;

      if (direction == 1 && (maxScroll - currentScroll) < cardWidth) {
        onLoadMore?.call();
      }

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
        // Modern header design
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icon section with proper background
              Container(
                width: isWideScreen ? 100 : 80,
                height: isWideScreen ? 100 : 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Styles.rouge.withOpacity(0.8),
                      Styles.rouge.withOpacity(0.6),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon ?? Icons.category,
                  color: Colors.white,
                  size: isWideScreen ? 48 : 32,
                ),
              ),

              const SizedBox(width: 16),

              // Text section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isWideScreen ? 24 : 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: isWideScreen ? 16 : 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Voir plus button and arrow
              Row(
                children: [
                  if (onVoirPlus != null)
                    TextButton(
                      onPressed: onVoirPlus,
                      child: Text(
                        'Voir plus',
                        style: TextStyle(
                          color: Styles.rouge,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Styles.rouge.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Styles.rouge,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height:
                  isWideScreen
                      ? 338
                      : 320, // Adjusted height for smaller cards that still show full content
              child: ListView.builder(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: produits.length,
                itemBuilder: (context, index) {
                  final produit = produits[index];
                  final bool isPanier = idsPanier.contains(produit.idproduit);
                  return Padding(
                    padding: const EdgeInsets.all(
                      9,
                    ), // Add some padding around each card
                    child: SizedBox(
                      width: cardWidth + 30, // Include padding in card width
                      child: ProductCard(
                        produit: produit,
                        isPanier: isPanier,
                        isWideScreen: isWideScreen,
                        onTogglePanier: () => onTogglePanier(produit),
                        onTap: () => onTap(produit),
                      ),
                    ),
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
