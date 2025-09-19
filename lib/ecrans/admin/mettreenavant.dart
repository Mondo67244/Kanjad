import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/produit.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:kanjad/widgets/dialogueskanjad.dart';
import 'package:kanjad/widgets/imagekanjad.dart';
import 'package:kanjad/widgets/kanjadappbar.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class MettreEnAvant extends StatefulWidget {
  const MettreEnAvant({super.key});

  @override
  State<MettreEnAvant> createState() => _MettreEnAvantState();
}

class _MettreEnAvantState extends State<MettreEnAvant> {
  List<String> _subcategories = [];
  String? _selectedSubcategory;
  String _searchQuery = '';
  Stream<List<Produit>>? _productStream;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // Pagination progressive
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
    if (_selectedSubcategory != null) {
      setState(() {
        _productStream = SupabaseService.instance
            .getProduitsStreamForSection(_selectedSubcategory!)
            .map((products) {
          if (_searchQuery.isEmpty) {
            return products;
          }
          return products
              .where((p) =>
                  p.nomproduit.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
        });
      });
    }
  }

  Future<void> _toggleHighlight(Produit produit, bool isHighlighted) async {
    if (isHighlighted) {
      final int? newViewCount = await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (context) => KanJadInputViewsDialog(
          title: 'Mettre en Avant',
          content: 'Entrez le nombre de vues pour "${produit.nomproduit}"',
          initialValue: produit.vues >= 100 ? produit.vues : 100,
        ),
      );

      if (newViewCount != null && mounted) {
        try {
          await SupabaseService.instance
              .updateVuesProduit(produit.idproduit, newViewCount);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produit mis en avant !')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur: $e")),
          );
        }
      }
    } else {
      try {
        await SupabaseService.instance.updateVuesProduit(produit.idproduit, 0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit retiré de la mise en avant.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e")),
        );
      }
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return KanjadAppBar(
      title: 'Kanjad',
      subtitle: 'Mettre en Avant',
      actions: [
        IconButton(
          icon: const Icon(FluentIcons.search_24_regular),
          onPressed: () => setState(() => _isSearching = true),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: _buildCategoryFilters(),
      ),
    );
  }

  PreferredSizeWidget _buildSearchBar() {
    return AppBar(
      backgroundColor: Styles.rouge,
      foregroundColor: Colors.white,
      title: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
        ),
        child: TextField(
          
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
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: _buildCategoryFilters(),
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
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Styles.bleu,
              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _isSearching ? _buildSearchBar() : _buildAppBar(),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          child: _buildProductList(),
        ),
      ),
    );
  }

  Widget _buildProductList() {
    if (_productStream == null) {
      return const Center(
        child: Text('Sélectionnez une catégorie pour commencer.'),
      );
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
          return const Center(child: Text('Aucun produit trouvé.'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 250,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
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
    final isHighlighted = produit.vues >= 100;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 15 / 9,
            child: KanjadImage(
              imageData: produit.img1,
              sousCategorie: produit.souscategorie,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(7.0),
            child: Text(
              produit.nomproduit,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          SwitchListTile(
            title: const Text('Favori', style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold)),
            value: isHighlighted,
            onChanged: (value) => _toggleHighlight(produit, value),
            activeThumbColor: Styles.vert,
            dense: true,
          ),
        ],
      ),
    );
  }
}
