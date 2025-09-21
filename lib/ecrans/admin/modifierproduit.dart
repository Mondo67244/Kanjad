import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/basicdata/produit.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:kanjad/widgets/kanjadappbar.dart';
import 'package:kanjad/widgets/indicateurdetats.dart';
import 'package:kanjad/widgets/imagekanjad.dart';
import 'package:provider/provider.dart';
import 'package:kanjad/services/providers/produitprovider.dart';

class ModifierProduitPage extends StatefulWidget {
  const ModifierProduitPage({super.key});

  @override
  State<ModifierProduitPage> createState() => _ModifierProduitPageState();
}

class _ModifierProduitPageState extends State<ModifierProduitPage> {
  late Future<List<Produit>> _produitsFuture;
  List<Produit> _tousLesProduits = [];
  List<Produit> _produitsFiltres = [];
  final TextEditingController _controleurRecherche = TextEditingController();

  @override
  void initState() {
    super.initState();
    _produitsFuture = _chargerProduits();
    _controleurRecherche.addListener(_filtrerProduits);
  }

  Future<List<Produit>> _chargerProduits() async {
    // Use cache when available, manual refresh via floating button
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    // Load if not already loaded
    if (productProvider.products.isEmpty) {
      await productProvider.loadProducts();
    }
    final produits = productProvider.products;
    if (mounted) {
      setState(() {
        _tousLesProduits = produits;
        _produitsFiltres = produits;
      });
    }
    return produits;
  }

  void _rafraichirProduits() {
    setState(() {
      _controleurRecherche.clear();
      _produitsFuture = _chargerProduits();
    });
  }

  void _filtrerProduits() {
    final requete = _controleurRecherche.text.toLowerCase();
    if (mounted) {
      setState(() {
        _produitsFiltres =
            _tousLesProduits.where((produit) {
              final nom = produit.nomproduit.toLowerCase();
              final marque = produit.marque.toLowerCase();
              final categorie = produit.categorie.toLowerCase();
              final type = produit.type.toLowerCase();
              return nom.contains(requete) ||
                  marque.contains(requete) ||
                  categorie.contains(requete) ||
                  type.contains(requete);
            }).toList();
      });
    }
  }

  @override
  void dispose() {
    _controleurRecherche.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: KanjadAppBar(
        title: 'Kanjad',
        subtitle: 'Modifier Produit',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _rafraichirProduits,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _rafraichirProduits,
        backgroundColor: Styles.rouge,
        tooltip: 'Rafraîchir les produits',
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
      body: Column(
        children: [
          _construireBarreRecherche(),
          Expanded(
            child: FutureBuilder<List<Produit>>(
              future: _produitsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _tousLesProduits.isEmpty) {
                  return const LoadingIndicator();
                }
                if (snapshot.hasError) {
                  return EmptyStateWidget(
                    message: 'Erreur: ${snapshot.error}',
                    icon: FluentIcons.error_circle_24_regular,
                    onRetry: _rafraichirProduits,
                  );
                }
                if (_produitsFiltres.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'Aucun produit trouvé.',
                    icon: FluentIcons.box_24_regular,
                  );
                }

                final isLargeScreen = MediaQuery.of(context).size.width > 800;
                return isLargeScreen
                    ? _construireGrilleProduits()
                    : _construireListeProduits();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _construireBarreRecherche() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _controleurRecherche,
        decoration: InputDecoration(
          hintText: 'Rechercher par nom, marque, catégorie...',
          prefixIcon: const Icon(FluentIcons.search_24_regular),
          suffixIcon:
              _controleurRecherche.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(FluentIcons.dismiss_circle_24_regular),
                    onPressed: () => _controleurRecherche.clear(),
                  )
                  : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _construireListeProduits() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _produitsFiltres.length,
      itemBuilder: (context, index) {
        return _carteProduit(_produitsFiltres[index]);
      },
    );
  }

  Widget _construireGrilleProduits() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        childAspectRatio: 1.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _produitsFiltres.length,
      itemBuilder: (context, index) {
        return _carteProduit(_produitsFiltres[index]);
      },
    );
  }

  Widget _carteProduit(Produit produit) {
    final imageUrl = produit.img1.isNotEmpty ? produit.img1 : null;

    return Card(
      color: Styles.blanc,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Row(
          children: [
            // Image du produit
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child:
                  imageUrl != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: KanjadImage(
                          imageData: imageUrl,
                          sousCategorie: produit.souscategorie,
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                        ),
                      )
                      : const Icon(
                        FluentIcons.image_24_regular,
                        color: Colors.grey,
                        size: 32,
                      ),
            ),
            const SizedBox(width: 16),
            // Informations du produit
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Nom du produit
                  Text(
                    produit.nomproduit,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Marque et modèle
                  Text(
                    '${produit.marque} - ${produit.modele}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Prix et stock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${produit.prix.toStringAsFixed(0)} CFA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Styles.rouge,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              produit.enstock
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          produit.enstock ? 'En stock' : 'Rupture',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                produit.enstock ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Catégorie et type
                  Text(
                    '${produit.categorie} > ${produit.souscategorie} > ${produit.type}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Icônes d'action
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(FluentIcons.edit_24_regular),
                  color: Styles.rouge,
                  tooltip: 'Modifier',
                  onPressed: () => _naviguerVersEdition(produit),
                ),
                IconButton(
                  icon: Icon(FluentIcons.delete_24_regular, color: Colors.red.shade700),
                  tooltip: 'Supprimer',
                  onPressed: () => _confirmerSuppressionProduit(produit),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _naviguerVersEdition(Produit produit) {
    Navigator.pushNamed(
      context,
      '/admin/ajouterequip',
      arguments: {'produit': produit, 'mode': 'edit'},
    );
  }

  void _confirmerSuppressionProduit(Produit produit) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text('Voulez-vous vraiment supprimer le produit "${produit.nomproduit}" ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
              onPressed: () {
                Navigator.of(context).pop();
                _supprimerProduit(produit);
              },
            ),
          ],
        );
      },
    );
  }

  void _supprimerProduit(Produit produit) async {
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      await productProvider.deleteProduct(produit.idproduit);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit supprimé avec succès'), backgroundColor: Colors.green),
        );
        _rafraichirProduits();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}