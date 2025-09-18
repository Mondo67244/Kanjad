import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/produit.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/widgets/imagekanjad.dart';

class ProductCard extends StatelessWidget {
  final Produit produit;
  final bool isPanier;
  final bool isWideScreen;
  final VoidCallback onTogglePanier;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.produit,
    required this.isPanier,
    required this.isWideScreen,
    required this.onTogglePanier,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec indicateurs
            Stack(
              children: [
                SizedBox(
                  height:
                      isWideScreen
                          ? 170
                          : 140, // Reduced height to match smaller card width
                  width: double.infinity,

                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: KanjadImage(
                      imageData: produit.img1,
                      sousCategorie: produit.souscategorie,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (produit.enpromo)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'PROMO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (!produit.enstock)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'RUPTURE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Contenu
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom du produit
                  Text(
                    produit.nomproduit,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Catégorie et type
                  Text(
                    '${produit.categorie} • ${produit.type}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 3),

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
                            fontSize: isWide ? 12 : 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Bouton d'action
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: produit.enstock ? onTogglePanier : null,
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
                            ? (isPanier
                                ? 'Ajouté au panier'
                                : 'Ajouter au panier')
                            : 'Indisponible',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
