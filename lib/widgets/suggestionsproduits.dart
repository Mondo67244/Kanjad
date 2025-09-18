import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/produit.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/widgets/imagekanjad.dart';

class ProduitSuggestionCard extends StatelessWidget {
  final Produit produit;
  final bool isActionDone;
  final String actionText;
  final String doneText;
  final IconData actionIcon;
  final IconData doneIcon;
  final VoidCallback onAction;

  const ProduitSuggestionCard({
    super.key,
    required this.produit,
    required this.isActionDone,
    required this.actionText,
    required this.doneText,
    required this.actionIcon,
    required this.doneIcon,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Styles.blanc,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/utilisateur/produit/details',
            arguments: produit,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: KanjadImage(
                    imageData: produit.img1,
                    sousCategorie: produit.souscategorie,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      produit.nomproduit,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${produit.prix.toStringAsFixed(0)} CFA',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            produit.enstock
                                ? (isActionDone
                                    ? Colors.blue.shade50
                                    : Styles.bleu)
                                : Colors.red.shade100,
                        foregroundColor:
                            produit.enstock
                                ? (isActionDone ? Styles.bleu : Styles.blanc)
                                : Styles.rouge,
                        side: BorderSide(
                          color:
                              produit.enstock
                                  ? const Color.fromARGB(255, 11, 7, 115)
                                  : Styles.rouge,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: produit.enstock ? onAction : null,
                      icon: Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: Icon(
                          isActionDone ? doneIcon : actionIcon,
                          size: 16,
                        ),
                      ),
                      label: Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: Text(
                          produit.enstock
                              ? (isActionDone ? doneText : actionText)
                              : 'Indisponible',
                          style: const TextStyle(
                            fontSize: 13,
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
      ),
    );
  }
}
