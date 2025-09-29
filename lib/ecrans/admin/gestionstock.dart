import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/produit.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:kanjad/widgets/imagekanjad.dart';
import 'package:kanjad/widgets/kanjadappbar.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class GestionStockPage extends StatefulWidget {
  const GestionStockPage({super.key});

  @override
  State<GestionStockPage> createState() => _GestionStockPageState();
}

class _GestionStockPageState extends State<GestionStockPage> {
  List<String> _subcategories = [];
  String? _selectedSubcategory;
  String _selectedStockFilter = 'tous'; // tous, abondant, normal, faible
  String _searchQuery = '';
  Stream<List<Produit>>? _productStream;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadSubcategories();
    _searchController.addListener(() {
      if (mounted) {
        Timer(const Duration(milliseconds: 300), () {
          if (mounted && _searchQuery != _searchController.text) {
            setState(() {
              _searchQuery = _searchController.text;
              _updateProductStream();
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSubcategories() async {
    try {
      final subcategories = await SupabaseService.instance.getSousCategories();
      if (mounted) {
        setState(() {
          _subcategories = subcategories;
          if (_subcategories.isNotEmpty) {
            _selectedSubcategory = _subcategories.first;
            _updateProductStream();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur de chargement des sous-catégories: $e")),
        );
      }
    }
  }

  void _updateProductStream() {
    if (_selectedSubcategory == null) return;

    setState(() {
      _productStream = SupabaseService.instance
          .getProduitsStreamForSection(_selectedSubcategory!)
          .map((products) {
        List<Produit> filteredProducts = products;

        // Filtre par recherche textuelle
        if (_searchQuery.isNotEmpty) {
          filteredProducts = filteredProducts
              .where((p) =>
                  p.nomproduit.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
        }

        // Filtre par niveau de stock
        switch (_selectedStockFilter) {
          case 'abondant':
            return filteredProducts.where((p) => p.quantite > 20).toList();
          case 'normal':
            return filteredProducts.where((p) => p.quantite > 10 && p.quantite <= 20).toList();
          case 'faible':
            return filteredProducts.where((p) => p.quantite <= 10).toList();
          default: // 'tous'
            return filteredProducts;
        }
      });
    });
  }

  PreferredSizeWidget _buildAppBar() {
    return KanjadAppBar(
      title: 'Kanjad',
      subtitle: 'Gestion des Stocks',
      actions: [
        IconButton(
          icon: const Icon(FluentIcons.search_24_regular),
          onPressed: () => setState(() => _isSearching = true),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Column(
          children: [
            _buildCategoryFilters(),
            _buildStockFilters(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildSearchBar() {
    return AppBar(
      backgroundColor: Styles.rouge,
      foregroundColor: Colors.white,
      title: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Rechercher un produit...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(FluentIcons.search_24_regular, color: Colors.grey.shade600),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(FluentIcons.dismiss_24_regular),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchController.clear();
            });
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Column(
          children: [
            _buildCategoryFilters(),
            _buildStockFilters(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    if (_subcategories.isEmpty) {
      return const Center(child: LinearProgressIndicator(color: Colors.white));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: _subcategories.map((subcat) {
          final isSelected = _selectedSubcategory == subcat;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(subcat),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedSubcategory = subcat;
                    _updateProductStream();
                  });
                }
              },
              backgroundColor: Colors.white,
              selectedColor: Styles.bleu,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Styles.bleu),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Styles.bleu),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStockFilters() {
    final filters = {
      'tous': 'Tous',
      'abondant': 'Abondant (> 20)',
      'normal': 'Normal (10-20)',
      'faible': 'Faible (< 10)',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: filters.entries.map((entry) {
          final isSelected = _selectedStockFilter == entry.key;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedStockFilter = entry.key;
                    _updateProductStream();
                  });
                }
              },
              backgroundColor: Colors.white,
              selectedColor: Styles.rouge,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Styles.rouge),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Styles.rouge),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _isSearching ? _buildSearchBar() : _buildAppBar(),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _buildProductList(),
        ),
      ),
    );
  }

  Widget _buildProductList() {
    if (_productStream == null) {
      return const Center(child: Text('Sélectionnez une catégorie pour commencer.'));
    }

    return StreamBuilder<List<Produit>>(
      stream: _productStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Erreur: ${snapshot.error}"));
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return const Center(child: Text('Aucun produit trouvé pour ce filtre.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final produit = products[index];
            return _buildProductCard(produit);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Produit produit) {
    Color stockColor;
    if (produit.quantite > 20) {
      stockColor = Colors.green;
    } else if (produit.quantite > 10) {
      stockColor = Colors.orange;
    } else {
      stockColor = Colors.red;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: KanjadImage(
                imageData: produit.img1,
                sousCategorie: produit.souscategorie,
                fit: BoxFit.cover,
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produit.nomproduit,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${produit.idproduit}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Stock',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: stockColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: stockColor),
                  ),
                  child: Text(
                    produit.quantite.toString(),
                    style: TextStyle(
                      color: stockColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}