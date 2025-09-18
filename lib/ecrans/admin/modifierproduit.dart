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

  // Two-column layout state
  Produit? _selectedProduit;
  bool _showFormOnLargeScreen = false;

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
    final screenSize = MediaQuery.of(context).size;
    final veryLargeScreen =
        screenSize.width > 1000; // Two-column layout threshold

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: KanjadAppBar(
        title: 'Kanjad',
        subtitle: 'Modifier Produit',
        actions: [
          if (_showFormOnLargeScreen)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _closeFormOnLargeScreen,
              tooltip: 'Fermer le formulaire',
            ),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (veryLargeScreen) {
            return _construireLayoutGrandEcran();
          } else {
            return _construireLayoutMobile();
          }
        },
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
      child: InkWell(
        onTap: () => _naviguerVersEdition(produit),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
              const SizedBox(width: 16),
              // Icône d'édition
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Styles.rouge.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  FluentIcons.edit_24_regular,
                  color: Styles.rouge,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _naviguerVersEdition(Produit produit) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    if (isWideScreen) {
      // For large screens, show form directly in the right column
      setState(() {
        _selectedProduit = produit;
        _showFormOnLargeScreen = true;
      });
    } else {
      // For small screens, navigate to new page
      Navigator.pushNamed(
        context,
        '/admin/ajouterequip',
        arguments: {'produit': produit, 'mode': 'edit'},
      );
    }
  }

  void _closeFormOnLargeScreen() {
    setState(() {
      _selectedProduit = null;
      _showFormOnLargeScreen = false;
    });
  }

  Widget _construireLayoutGrandEcran() {
    return Row(
      children: [
        // Left column: Product search and list
        Expanded(
          flex: _showFormOnLargeScreen ? 2 : 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            margin: const EdgeInsets.all(16),
            child: Column(
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
                      return _construireListeProduits();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right column: Form (when product is selected)
        if (_showFormOnLargeScreen && _selectedProduit != null)
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
              child: _construireFormulaireEditionEmbedde(),
            ),
          ),
      ],
    );
  }

  Widget _construireLayoutMobile() {
    if (_showFormOnLargeScreen && _selectedProduit != null) {
      return Column(children: [_construireFormulaireEditionEmbedde()]);
    }

    return Column(
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
    );
  }

  Widget _construireFormulaireEditionEmbedde() {
    if (_selectedProduit == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Modifier: ${_selectedProduit!.nomproduit}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _closeFormOnLargeScreen,
                  tooltip: 'Fermer',
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image display
                    if (_selectedProduit!.img1.isNotEmpty)
                      Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(_selectedProduit!.img1),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Basic product info - simplified for embedded form
                    TextFormField(
                      initialValue: _selectedProduit!.nomproduit,
                      decoration: const InputDecoration(
                        labelText: 'Nom du produit',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _selectedProduit!.prix
                                .toStringAsFixed(0),
                            decoration: const InputDecoration(
                              labelText: 'Prix',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<bool>(
                            initialValue: _selectedProduit!.enstock,
                            decoration: const InputDecoration(
                              labelText: 'En stock',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              DropdownMenuItem(value: true, child: Text('Oui')),
                              DropdownMenuItem(
                                value: false,
                                child: Text('Non'),
                              ),
                            ],
                            onChanged: (value) {},
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _selectedProduit!.quantite.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Quantité',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SwitchListTile(
                            title: const Text('En promo'),
                            value: _selectedProduit!.enpromo,
                            onChanged: (value) {},
                            dense: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _closeFormOnLargeScreen,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.save,color: Styles.blanc,),
                          label: const Text('Enregistrer',style: TextStyle(color: Styles.blanc),),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Styles.rouge,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
