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
  // Données principales
  List<String> _subcategories = [];
  String? _selectedSubcategory;
  String _selectedStockFilter = 'tous';
  String _searchQuery = '';
  Stream<List<Produit>>? _productStream;
  final TextEditingController _searchController = TextEditingController();

  // État de l'interface
  bool _isGridView = false;
  String _sortBy = 'nom'; // nom, quantite, prix, vues

  // Métriques
  int _totalProduits = 0;
  int _produitsFaibleStock = 0;
  double _valeurTotaleStock = 0.0;
  int _alertesReappro = 0;

  @override
  void initState() {
    super.initState();
    _loadSubcategories();
    _setupSearchListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setupSearchListener() {
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
        _showErrorSnackBar("Erreur de chargement des sous-catégories: $e");
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
                  p.nomproduit
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  p.idproduit
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()))
              .toList();
        }

        // Filtre par niveau de stock
        switch (_selectedStockFilter) {
          case 'abondant':
            filteredProducts =
                filteredProducts.where((p) => p.quantite > 20).toList();
            break;
          case 'normal':
            filteredProducts = filteredProducts
                .where((p) => p.quantite > 10 && p.quantite <= 20)
                .toList();
            break;
          case 'faible':
            filteredProducts =
                filteredProducts.where((p) => p.quantite <= 10).toList();
            break;
        }

        // Tri des produits
        switch (_sortBy) {
          case 'quantite':
            filteredProducts.sort((a, b) => b.quantite.compareTo(a.quantite));
            break;
          case 'prix':
            filteredProducts.sort((a, b) => b.prix.compareTo(a.prix));
            break;
          case 'vues':
            filteredProducts.sort((a, b) => b.vues.compareTo(a.vues));
            break;
          default: // 'nom'
            filteredProducts
                .sort((a, b) => a.nomproduit.compareTo(b.nomproduit));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _calculateMetrics(filteredProducts);
            });
          }
        });

        return filteredProducts;
      });
    });
  }

  void _calculateMetrics(List<Produit> products) {
    _totalProduits = products.length;
    _produitsFaibleStock = products.where((p) => p.quantite <= 10).length;
    _valeurTotaleStock =
        products.fold(0.0, (sum, p) => sum + (p.prix * p.quantite));
    _alertesReappro = products.where((p) => p.quantite <= 5).length;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Styles.erreur,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isWideScreen ? 850 : 400,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  _buildMetricsSection(constraints),
                  _buildFiltersSection(constraints),
                  Expanded(child: _buildProductList(constraints)),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return KanjadAppBar(
      title: 'Kanjad',
      subtitle: 'Gestion des Stocks',
      actions: [
        IconButton(
          icon: Icon(
              _isGridView ? FluentIcons.list_24_regular : FluentIcons.grid_24_regular),
          onPressed: () => setState(() => _isGridView = !_isGridView),
          tooltip: 'Changer la vue',
        ),
      ],
    );
  }

  Widget _buildMetricsSection(BoxConstraints constraints) {
    bool isWide = constraints.maxWidth > 600;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: GridView.count(
        crossAxisCount: isWide ? 4 : 2,
        shrinkWrap: true,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isWide ? 2.5 : 2,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildMetricCard(
              icon: FluentIcons.box_24_regular,
              value: _totalProduits.toString(),
              label: 'Total Produits',
              color: Styles.bleu),
          _buildMetricCard(
              icon: FluentIcons.warning_24_regular,
              value: _produitsFaibleStock.toString(),
              label: 'Stock Faible',
              color: Colors.orange),
          _buildMetricCard(
              icon: FluentIcons.money_24_regular,
              value: '${_valeurTotaleStock.toStringAsFixed(0)}CFA',
              label: 'Valeur du Stock',
              color: Colors.green),
          _buildMetricCard(
              icon: FluentIcons.alert_24_regular,
              value: _alertesReappro.toString(),
              label: 'Alertes Réappro',
              color: Styles.rouge),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      {required IconData icon,
      required String value,
      required String label,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(BoxConstraints constraints) {
    bool isWide = constraints.maxWidth > 800;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          isWide
              ? Row(
                  children: [
                    Expanded(flex: 2, child: _buildSearchBar()),
                    const SizedBox(width: 12),
                    Expanded(flex: 1, child: _buildCategoryDropdown()),
                    const SizedBox(width: 12),
                    Expanded(flex: 1, child: _buildStockFilterDropdown()),
                    const SizedBox(width: 12),
                    Expanded(flex: 1, child: _buildSortDropdown()),
                  ],
                )
              : Column(
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildCategoryDropdown()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStockFilterDropdown()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSortDropdown(),
                  ],
                ),
          if (_searchQuery.isNotEmpty || _selectedStockFilter != 'tous')
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildActiveFilters(),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Rechercher par nom ou ID...',
        prefixIcon: const Icon(FluentIcons.search_24_regular, size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(FluentIcons.dismiss_24_regular, size: 20),
                onPressed: () => _searchController.clear(),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Styles.bleu, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedSubcategory,
      decoration: _inputDecoration('Catégorie'),
      items: _subcategories
          .map((subcat) => DropdownMenuItem(value: subcat, child: Text(subcat)))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedSubcategory = value;
          _updateProductStream();
        });
      },
      isExpanded: true,
    );
  }

  Widget _buildStockFilterDropdown() {
    final filters = {
      'tous': 'Tous les stocks',
      'abondant': 'Abondant (> 20)',
      'normal': 'Normal (10-20)',
      'faible': 'Faible (≤ 10)',
    };
    return DropdownButtonFormField<String>(
      initialValue: _selectedStockFilter,
      decoration: _inputDecoration('Niveau de stock'),
      items: filters.entries
          .map((entry) =>
              DropdownMenuItem(value: entry.key, child: Text(entry.value)))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedStockFilter = value!;
          _updateProductStream();
        });
      },
      isExpanded: true,
    );
  }

  Widget _buildSortDropdown() {
    final sortOptions = {
      'nom': 'Nom A-Z',
      'quantite': 'Quantité ↓',
      'prix': 'Prix ↓',
      'vues': 'Popularité ↓',
    };
    return DropdownButtonFormField<String>(
      initialValue: _sortBy,
      decoration: _inputDecoration('Trier par'),
      items: sortOptions.entries
          .map((entry) =>
              DropdownMenuItem(value: entry.key, child: Text(entry.value)))
          .toList(),
      onChanged: (value) {
        setState(() {
          _sortBy = value!;
          _updateProductStream();
        });
      },
      isExpanded: true,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Styles.bleu, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }

  Widget _buildActiveFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (_searchQuery.isNotEmpty)
            _buildFilterChip('Recherche: "$_searchQuery"', onDelete: () {
              _searchController.clear();
            }),
          if (_selectedStockFilter != 'tous')
            _buildFilterChip(
                'Stock: $_selectedStockFilter',
                onDelete: () => setState(() {
                      _selectedStockFilter = 'tous';
                      _updateProductStream();
                    })),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {required VoidCallback onDelete}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onDelete,
        backgroundColor: Styles.bleu.withOpacity(0.1),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Styles.bleu.withOpacity(0.3))),
      ),
    );
  }

  Widget _buildProductList(BoxConstraints constraints) {
    if (_productStream == null) {
      return const Center(
          child:
              Text('Sélectionnez une catégorie pour afficher les produits.'));
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

        if (_isGridView) {
          return _buildGridView(products, constraints);
        } else {
          return _buildListView(products);
        }
      },
    );
  }

  Widget _buildListView(List<Produit> products) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) =>
          _buildProductCard(products[index]),
    );
  }

  Widget _buildGridView(List<Produit> products, BoxConstraints constraints) {
    int crossAxisCount = (constraints.maxWidth / 200).floor().clamp(2, 5);
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) =>
          _buildProductGridCard(products[index]),
    );
  }

  Widget _buildProductCard(Produit produit) {
    final stockColor = _getStockColor(produit.quantite);
    final stockLevel = _getStockLevel(produit.quantite);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
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
                width: 70,
                height: 70,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produit.nomproduit,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${produit.idproduit}',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(FluentIcons.eye_24_regular,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text('${produit.vues} vues',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: stockColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${produit.quantite}',
                    style: TextStyle(
                        color: stockColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stockLevel,
                  style: TextStyle(
                      color: stockColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGridCard(Produit produit) {
    final stockColor = _getStockColor(produit.quantite);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: KanjadImage(
              imageData: produit.img1,
              sousCategorie: produit.souscategorie,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produit.nomproduit,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${produit.quantite} unités',
                      style: TextStyle(
                          color: stockColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${produit.prix.toStringAsFixed(0)}€',
                      style: TextStyle(
                          color: Styles.rouge,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStockColor(int quantite) {
    if (quantite > 20) return Colors.green;
    if (quantite > 10) return Colors.orange;
    return Colors.red;
  }

  String _getStockLevel(int quantite) {
    if (quantite > 20) return 'ABONDANT';
    if (quantite > 10) return 'NORMAL';
    if (quantite > 5) return 'FAIBLE';
    return 'CRITIQUE';
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showBulkActions,
      backgroundColor: Styles.rouge,
      icon: const Icon(Icons.inventory_2_outlined),
      label: const Text('Actions'),
    );
  }

  void _showBulkActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions groupées',
              style:
                  Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildActionItem(
                context, Icons.file_download, 'Exporter CSV', _exportToCSV),
            _buildActionItem(
                context, Icons.file_upload, 'Importer stock', _importStock),
            _buildActionItem(context, Icons.notifications_active,
                'Configurer alertes', _configureAlerts),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _exportToCSV() {
    _showErrorSnackBar('Export CSV - Fonctionnalité à venir');
  }

  void _importStock() {
    _showErrorSnackBar('Import stock - Fonctionnalité à venir');
  }

  void _configureAlerts() {
    _showErrorSnackBar('Configuration alertes - Fonctionnalité à venir');
  }
}