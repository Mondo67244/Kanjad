import 'dart:convert';
import 'dart:typed_data';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:RAS/basicdata/produit.dart';
import 'package:RAS/basicdata/style.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    final List<String> images =
        [
          produit.img1,
          // produit.img2,
          // produit.img3,
        ].where((img) => img.isNotEmpty).toList();
    final PageController pageController = PageController();
    final isWideScreen = MediaQuery.of(context).size.width > 700;

    return SizedBox(
      width: isWideScreen ? 260 : 245,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Card(
          color: Styles.blanc,
          margin: const EdgeInsets.all(9),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: SizedBox(
                  height: isWideScreen ? 235 : 200,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      images.isEmpty
                          ? Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey.shade400,
                              size: 50,
                            ),
                          )
                          : PageView.builder(
                            controller: pageController,
                            itemCount: images.length,
                            itemBuilder:
                                (context, index) =>
                                    _appelImages(images[index], context),
                          ),
                      if (produit.enPromo)
                        Positioned(
                          top: 2,
                          left: 5,
                          child: Chip(
                            backgroundColor: Styles.rouge,
                            label: Row(
                              children: [
                                Text(
                                  'En promotion',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Styles.blanc,
                                    fontSize: 11,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produit.nomProduit,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (produit.enPromo)
                          Row(
                            children: [
                              Text(
                                '${produit.prix} CFA',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Styles.rouge,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                produit.ancientPrix,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            '${produit.prix} CFA',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Styles.rouge,
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                produit.enStock
                                    ? Styles.vert.withAlpha((0.1 * 255).round())
                                    : Styles.erreur.withAlpha(
                                      (0.1 * 255).round(),
                                    ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            produit.enStock ? 'En stock' : 'Rupture',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color:
                                  produit.enStock ? Styles.vert : Styles.erreur,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: produit.enStock ? onTogglePanier : null,
                            icon: Icon(
                              isPanier
                                  ? FluentIcons.shopping_bag_tag_24_filled
                                  : FluentIcons.shopping_bag_tag_24_regular,
                              size: 16,
                            ),
                            label: Text(
                              produit.enStock
                                  ? (isPanier ? 'Ajouté' : 'Ajouter au Panier')
                                  : 'Indisponible',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color:
                                    produit.enStock
                                        ? (isPanier
                                            ? Styles.bleu
                                            : Styles.blanc)
                                        : Styles.rouge,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  produit.enStock
                                      ? (isPanier
                                          ? Colors.blue.shade50
                                          : Styles.bleu)
                                      : Colors.red.shade100,
                              foregroundColor:
                                  produit.enStock
                                      ? (isPanier ? Styles.bleu : Styles.blanc)
                                      : Styles.rouge,
                              side: BorderSide(
                                color:
                                    produit.enStock
                                        ? const Color.fromARGB(255, 11, 7, 115)
                                        : Styles.rouge,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
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
        ),
      ),
    );
  }

  //Widget pour appeler les images depuis le document Supabase du produit
  Widget _appelImages(String imageData, BuildContext context) {
    if (imageData.isEmpty) {
      return SizedBox(
        width: MediaQuery.of(context).size.width > 400 ? 300 : 280,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey,
            size: 60,
          ),
        ),
      );
    }

    if (imageData.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageData,
        fit: BoxFit.cover,
        width: MediaQuery.of(context).size.width > 400 ? 300 : 280,
        placeholder:
            (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget:
            (context, url, error) =>
                const Icon(Icons.error_outline, color: Colors.grey, size: 60),
        fadeInDuration: const Duration(milliseconds: 300),
      );
    }

    try {
      final RegExp base64Regex = RegExp(r'^[A-Za-z0-9+/=]+');
      if (!base64Regex.hasMatch(imageData)) {
        throw const FormatException('Chaîne Base64 invalide');
      }

      final Uint8List imageBytes = base64Decode(imageData);
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        width: MediaQuery.of(context).size.width > 400 ? 300 : 280,
        errorBuilder:
            (context, error, stackTrace) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.red,
              size: 60,
            ),
      );
    } catch (e) {
      print('Erreur de décodage Base64: $e');
      return SizedBox(
        width: MediaQuery.of(context).size.width > 400 ? 300 : 280,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.red, size: 60),
        ),
      );
    }
  }
}
