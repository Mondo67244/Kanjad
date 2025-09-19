import 'dart:async';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/produit.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/utilitaires/servicemessagerie.dart';
import 'package:kanjad/widgets/indicateurdetats.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:kanjad/widgets/imagekanjad.dart';
import 'package:provider/provider.dart';
import 'package:kanjad/services/panier/panierprovider.dart';
import 'package:kanjad/services/providers/produitprovider.dart';
import 'package:kanjad/widgets/carteproduit.dart';

enum _SearchMode { ByName, ByFilters }

class Resultats extends StatefulWidget {
  const Resultats({super.key});

  @override
  State<Resultats> createState() => _ResultatsState();
}

class _ResultatsState extends State<Resultats> with TickerProviderStateMixin {
  List<Produit> _allProduits = [];
  List<Produit> _filteredProduits = [];

  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  final List<String> _categories = [
    'Informatique',
    'Électronique',
    'Électro Ménager',
  ];

  final List<String> _brands = [
    '- Autre -',
    'Acer',
    'Alcatel',
    'APC',
    'Apple',
    'Asus',
    'Canon',
    'Cisco',
    'Ck-link',
    'D-link',
    'Delta',
    'Dell',
    'Duracell',
    'Fujitsu',
    'Google',
    'Hikvision',
    'HP',
    'HPE',
    'Huawei',
    'Intel',
    'Kaspersky',
    'Lenovo',
    'LG',
    'Microsoft',
    'NetGear',
    'Nokia',
    'Panasonic',
    'Ricoh',
    'Samsung',
    'Sony',
    'Toshiba',
    'Tp-Link',
    'Ubiquiti',
    'UniFi',
    'ZTE',
  ];

  final Map<String, List<String>> categoryTypes = {
    'Informatique': ['Bureautique', 'Réseau'],
    'Électronique': ['Appareil Mobile', 'Accessoires'],
    'Électro Ménager': ['Divers'],
  };

  final Map<String, List<String>> typeAppareil = {
    'Bureautique': [
      'Antivirus',
      'Badge',
      'Calculatrice',
      'Carte mémoire',
      'Carte SIM',
      'Cartouche d\'impression',
      'Chemise A4',
      'Chrono couleur',
      'Clavier',
      'Clé USB',
      'Colle liquide',
      'Compteur de billets',
      'Ecran',
      'Encre imprimante',
      'Encre toner',
      'Enveloppe A3/A4',
      'Filtre écran',
      'Haut parleur',
      'Imprimante',
      'Laptop',
      'Licence Microsoft',
      'Onduleur',
      'Ordinateur',
      'Rame de papier',
      'Registre courrier',
      'Rouleau de papier',
      'Scanner',
      'Serre document',
      'Souris',
      'Stylo à bille',
      'Unité de fusion',
    ],
    'Réseau': [
      'Cable réseau',
      'Clé wifi',
      'Commutateur',
      'Data card',
      'Fibre optique',
      'Modem',
      'Routeurs',
      'Serveur',
      'Serveur NAS',
      'Switch',
      'Téléphones IP',
    ],
    'Appareil Mobile': [
      'Accessoire mobile',
      'Enregistreur de voix',
      'Tablette',
      'Tablet PC',
      'Téléphone',
    ],
    'Divers': [
      'Boulloire',
      'Cafetière',
      'Décodeur satellite',
      'Fers à repasser',
      'Interrupteur',
      'Machine à laver',
      'Parfum',
      'Prise',
      'Projecteur smart',
      'Rallonge électrique',
      'Régulateur de tension',
      'Support TV',
      'Téléviseur',
      // Suppression de 'Chaussures' et 'Sac à dos' qui sont des accessoires
    ],
    'Accessoires': [
      'Adaptateur',
      'Airpods',
      'Barette mémoire',
      'Batterie',
      'Cables Usb',
      'Câbles divers',
      'Caméra',
      'Casque avec caméra',
      'Casques',
      'Chargeur',
      'Chaussures', // déplacé ici depuis Divers
      'Clé USB',
      'Connecteur',
      'Convertisseur',
      'Cordon HDMI',
      'Écouteur',
      'Finder',
      'Gamepad',
      'Haut parleur sans fil',
      'Hub USB',
      'Montres connectées',
      'Pile',
      'Pointeur PowerPoint',
      'Sac à dos', // déplacé ici depuis Divers
    ],
  };

  String? _selectedCategory;
  String? _selectedSousCat;
  String? _selectedType;
  String? _selectedBrand;
  bool _isLoading = true;
  final bool _isSearchFormVisible = true;
  bool _showResults =
      false; // Nouvel état pour contrôler l'affichage des résultats
  _SearchMode _currentSearchMode = _SearchMode.ByFilters;
  Timer? _debounce;

  // Pagination progressive
  final ScrollController _scrollController = ScrollController();
  static const int _batchSize = 20;
  int _currentBatch = 1;
  List<Produit> _allFilteredProducts = [];
  List<Produit> _displayedProducts = [];
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;

  @override
  void initState() {
    super.initState();
    _loadAllProduits();
    _searchController.addListener(_onFilterChanged);
    _minPriceController.addListener(_onFilterChanged);
    _maxPriceController.addListener(_onFilterChanged);

    // Initialiser le listener pour la pagination infinie
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadAllProduits() async {
    setState(() => _isLoading = true);
    try {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      await productProvider.loadProducts();
      if (mounted) {
        setState(() {
          _allProduits = productProvider.products;
          _filteredProduits = productProvider.products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        MessagerieService.showError(
          context,
          'Erreur de chargement des produits: $e',
        );
      }
    }
  }

  void _onFilterChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _performSearch);
  }

  //Faire la recherche
  void _performSearch() {
    if (!mounted) return;

    List<Produit> results = List.from(_allProduits);
    final searchText = _searchController.text.toLowerCase().trim();

    if (searchText.isNotEmpty) {
      results =
          results
              .where(
                (p) =>
                    p.nomproduit.toLowerCase().contains(searchText) ||
                    p.description.toLowerCase().contains(searchText),
              )
              .toList();
    }

    if (_currentSearchMode == _SearchMode.ByFilters) {
      final minPriceText = _minPriceController.text.trim();
      final maxPriceText = _maxPriceController.text.trim();

      if (_selectedCategory != null) {
        results =
            results.where((p) => p.categorie == _selectedCategory).toList();
      }
      if (_selectedSousCat != null) {
        results =
            results.where((p) => p.souscategorie == _selectedSousCat).toList();
      }
      if (_selectedType != null) {
        results = results.where((p) => p.type == _selectedType).toList();
      }
      if (_selectedBrand != null) {
        results = results.where((p) => p.marque == _selectedBrand).toList();
      }

      final minPrice = double.tryParse(minPriceText);
      if (minPrice != null) {
        results = results.where((p) => p.prix >= minPrice).toList();
      }

      final maxPrice = double.tryParse(maxPriceText);
      if (maxPrice != null) {
        results = results.where((p) => p.prix <= maxPrice).toList();
      }
    }

    setState(() {
      _filteredProduits = results;
    });
  }

  // Nouvelle méthode pour appliquer les filtres
  void _applyFilters() {
    _performSearch();
    setState(() {
      _showResults = true;
    });
  }

  // Nouvelle méthode pour réinitialiser et afficher les filtres
  void _showFilters() {
    setState(() {
      _showResults = false;
    });
  }

  void _toggleSearchMode(_SearchMode mode) {
    setState(() {
      if (_currentSearchMode == mode) {
        _currentSearchMode = _SearchMode.ByFilters;
      } else {
        _currentSearchMode = mode;
      }
      _searchController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _selectedCategory = null;
      _selectedSousCat = null;
      _selectedType = null;
      _selectedBrand = null;
      _performSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: NestedScrollView(
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              SliverAppBar(
                foregroundColor: Styles.blanc,
                expandedHeight: 180,
                floating: false,
                pinned: true,
                backgroundColor: Styles.rouge,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Styles.rouge, Styles.rouge.withOpacity(0.8)],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo et titre
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/kanjad.png',
                              width: 150,
                              height: 40,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Recherche Avancée',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Compteur de résultats
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _isLoading
                                  ? 'Chargement...'
                                  : '${_filteredProduits.length} résultat${_filteredProduits.length > 1 ? 's' : ''} trouvé${_filteredProduits.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        // Mode de recherche
                        PopupMenuButton<_SearchMode>(
                          onSelected: _toggleSearchMode,
                          itemBuilder:
                              (context) => [
                                const PopupMenuItem(
                                  value: _SearchMode.ByName,
                                  child: Text('Recherche par nom'),
                                ),
                                const PopupMenuItem(
                                  value: _SearchMode.ByFilters,
                                  child: Text('Recherche par filtres'),
                                ),
                              ],
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Icon(
                                  _currentSearchMode == _SearchMode.ByName
                                      ? FluentIcons.search_20_regular
                                      : FluentIcons.filter_20_regular,
                                  color: Styles.rouge,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _currentSearchMode == _SearchMode.ByName
                                      ? 'Par nom'
                                      : 'Par filtres',
                                  style: TextStyle(
                                    color: Styles.rouge,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
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
              ),
            ],
        body: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            if (screenWidth > 550) {
              // À partir de 550px : layout grand écran
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Panneau de filtres (masquable)
                  if (_isSearchFormVisible)
                    Container(
                      width: 350,
                      height: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          right: BorderSide(color: Colors.grey, width: 0.5),
                        ),
                      ),
                      child: _buildModernSearchPanel(),
                    ),
                  // Résultats
                  Expanded(
                    child: _buildModernResultsSection(isWideScreen: true),
                  ),
                ],
              );
            } else {
              // Mobile uniquement (< 550px) : layout empilé
              return Stack(
                children: [
                  // Affichage des filtres ou des résultats selon l'état
                  if (!_showResults)
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey, width: 0.5),
                        ),
                      ),
                      child: _buildModernSearchPanel(),
                    )
                  else
                    _buildModernResultsSection(isWideScreen: false),

                  // Bouton flottant pour basculer entre filtres et résultats
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      onPressed: _showResults ? _showFilters : _applyFilters,
                      backgroundColor: Styles.rouge,
                      foregroundColor: Colors.white,
                      child: Icon(
                        _showResults
                            ? FluentIcons.eye_20_regular
                            : FluentIcons.checkmark_20_regular,
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    final List<Widget> chips = [];
    if (_currentSearchMode == _SearchMode.ByFilters) {
      if (_selectedCategory != null) {
        chips.add(
          _buildFilterChip(
            'Cat: $_selectedCategory',
            () => setState(() {
              _selectedCategory = null;
              _performSearch();
            }),
          ),
        );
      }
      if (_selectedSousCat != null) {
        chips.add(
          _buildFilterChip(
            'Sous-cat: $_selectedSousCat',
            () => setState(() {
              _selectedSousCat = null;
              _performSearch();
            }),
          ),
        );
      }
      if (_selectedType != null) {
        chips.add(
          _buildFilterChip(
            'Type: $_selectedType',
            () => setState(() {
              _selectedType = null;
              _performSearch();
            }),
          ),
        );
      }
      if (_selectedBrand != null) {
        chips.add(
          _buildFilterChip(
            'Marque: $_selectedBrand',
            () => setState(() {
              _selectedBrand = null;
              _performSearch();
            }),
          ),
        );
      }
      if (_minPriceController.text.isNotEmpty) {
        chips.add(
          _buildFilterChip(
            'Min: ${_minPriceController.text}',
            () => setState(() {
              _minPriceController.clear();
              _performSearch();
            }),
          ),
        );
      }
      if (_maxPriceController.text.isNotEmpty) {
        chips.add(
          _buildFilterChip(
            'Max: ${_maxPriceController.text}',
            () => setState(() {
              _maxPriceController.clear();
              _performSearch();
            }),
          ),
        );
      }
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Styles.bleu, fontWeight: FontWeight.w600),
      ),
      backgroundColor: Styles.bleu.withAlpha(20),
      onDeleted: onDeleted,
      deleteIconColor: Styles.bleu,
    );
  }

  Widget _buildModernSearchPanel() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _buildModernSearchPanelContent(),
      ),
    );
  }

  Widget _buildModernSearchPanelContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header du panneau
          Row(
            children: [
              Icon(FluentIcons.filter_20_regular, color: Styles.rouge),
              const SizedBox(width: 12),
              const Text(
                'Filtres de recherche',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Mode de recherche
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mode de recherche',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildModeButton(
                        _SearchMode.ByName,
                        'Par nom',
                        FluentIcons.search_20_regular,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildModeButton(
                        _SearchMode.ByFilters,
                        'Par filtres',
                        FluentIcons.filter_20_regular,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Recherche par nom
          if (_currentSearchMode == _SearchMode.ByName) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        FluentIcons.search_20_regular,
                        color: Styles.bleu,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Recherche par nom',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tapez le nom du produit...',
                      prefixIcon: const Icon(FluentIcons.search_20_regular),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Filtres avancés
            _buildAdvancedFilters(),
          ],

          const SizedBox(height: 20),

          // Filtres actifs
          if (_hasActiveFilters()) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtres actifs',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildActiveFilters(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _clearAllFilters,
                icon: const Icon(FluentIcons.dismiss_20_regular),
                label: const Text('Effacer tous les filtres'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],

          // Bouton Valider pour mobile
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth <= 550) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _applyFilters,
                      icon: const Icon(FluentIcons.checkmark_20_regular),
                      label: const Text('Valider les filtres'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Styles.rouge,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(_SearchMode mode, String label, IconData icon) {
    final isSelected = _currentSearchMode == mode;
    return ElevatedButton.icon(
      onPressed: () => _toggleSearchMode(mode),
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Styles.rouge : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: isSelected ? 2 : 0,
        side: BorderSide(
          color: isSelected ? Styles.rouge : Colors.grey.shade300,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Column(
      children: [
        // Catégorie
        _buildModernDropdown(
          _categories,
          'Catégorie',
          _selectedCategory,
          (val) => setState(() {
            _selectedCategory = val;
            _selectedSousCat = null;
            _selectedType = null;
            _onFilterChanged();
          }),
          FluentIcons.apps_list_20_regular,
        ),

        if (_selectedCategory != null) ...[
          const SizedBox(height: 16),
          _buildModernDropdown(
            categoryTypes[_selectedCategory!]!,
            'Sous-catégorie',
            _selectedSousCat,
            (val) => setState(() {
              _selectedSousCat = val;
              _selectedType = null;
              _onFilterChanged();
            }),
            FluentIcons.list_20_regular,
          ),
        ],

        if (_selectedSousCat != null) ...[
          const SizedBox(height: 16),
          _buildModernDropdown(
            typeAppareil[_selectedSousCat!]!,
            'Type d\'appareil',
            _selectedType,
            (val) => setState(() {
              _selectedType = val;
              _onFilterChanged();
            }),
            FluentIcons.device_eq_20_regular,
          ),
        ],

        const SizedBox(height: 16),
        _buildModernDropdown(
          _brands,
          'Marque',
          _selectedBrand,
          (val) => setState(() {
            _selectedBrand = val;
            _onFilterChanged();
          }),
          FluentIcons.tag_20_regular,
        ),

        const SizedBox(height: 16),
        // Prix
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    FluentIcons.money_20_regular,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Fourchette de prix',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minPriceController,
                      decoration: InputDecoration(
                        hintText: 'Min',
                        suffixText: 'CFA',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maxPriceController,
                      decoration: InputDecoration(
                        hintText: 'Max',
                        suffixText: 'CFA',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdown(
    List<String> items,
    String hint,
    String? selectedValue,
    void Function(String?) onChanged,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Styles.rouge, size: 20),
              const SizedBox(width: 8),
              Text(
                hint,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButton2<String>(
            isExpanded: true,
            value: selectedValue,
            hint: Text(
              'Sélectionner...',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            items:
                items
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
            onChanged: onChanged,
            buttonStyleData: const ButtonStyleData(
              padding: EdgeInsets.symmetric(horizontal: 16),
              height: 48,
            ),
            dropdownStyleData: const DropdownStyleData(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernResultsSection({required bool isWideScreen}) {
    final panierProvider = context.watch<PanierProvider>();

    if (_isLoading) {
      return const LoadingIndicator();
    }

    // Mettre à jour les produits filtrés si nécessaire
    if (_allFilteredProducts.length != _filteredProduits.length ||
        !_areListsEqual(_allFilteredProducts, _filteredProduits)) {
      _allFilteredProducts = List.from(_filteredProduits);
      _resetPagination();
      _displayedProducts = _allFilteredProducts.take(_batchSize).toList();
    }

    if (_filteredProduits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FluentIcons.search_24_regular, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aucun résultat trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Essayez de modifier vos filtres ou votre recherche',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.refresh),
              label: const Text('Réinitialiser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.rouge,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: isWideScreen
                ? GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    childAspectRatio: 1,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: _displayedProducts.length + (_hasMoreProducts ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _displayedProducts.length) {
                      // Loading indicator
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final produit = _displayedProducts[index];
                    final bool isPanier = panierProvider.isProduitInPanier(
                      produit.idproduit,
                    );
                    return ProductCard(
                      produit: produit,
                      isPanier: isPanier,
                      isWideScreen: false,
                      onTogglePanier: () async {
                        final result = await panierProvider.clicPanier(
                          produit.idproduit,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message']),
                              backgroundColor:
                                  result['success']
                                      ? Colors.green
                                      : Styles.erreur,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                      onTap:
                          () => Navigator.pushNamed(
                            context,
                            '/utilisateur/produit/details',
                            arguments: produit,
                          ),
                    );
                  },
                )
                : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _displayedProducts.length + (_hasMoreProducts ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _displayedProducts.length) {
                      // Loading indicator
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final produit = _displayedProducts[index];
                    final bool isPanier = panierProvider.isProduitInPanier(
                      produit.idproduit,
                    );
                    return _buildHorizontalCard(
                      context,
                      produit,
                      panierProvider,
                      isPanier,
                    );
                  },
                ),
          ),
          // Indicateur de chargement en bas si nécessaire
          if (_isLoadingMore)
            Container(
              padding: const EdgeInsets.all(16),
              child: const CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCard(
    BuildContext context,
    Produit produit,
    PanierProvider panierProvider,
    bool isPanier,
  ) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            () => Navigator.pushNamed(
              context,
              '/utilisateur/produit/details',
              arguments: produit,
            ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image du produit
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: KanjadImage(
                    imageData: produit.img1,
                    sousCategorie: produit.souscategorie,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Informations du produit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom du produit (2 lignes max)
                    Text(
                      produit.nomproduit,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Description courte
                    Text(
                      produit.descriptioncourte,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Prix
                    Row(
                      children: [
                        Text(
                          '${produit.prix.toStringAsFixed(0)} CFA',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                        if (produit.enpromo) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${produit.ancientprix.toStringAsFixed(0)} CFA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Colonne avec statut et bouton
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  // Chip de statut
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          produit.enstock
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            produit.enstock
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                      ),
                    ),
                    child: Text(
                      produit.enstock ? 'En stock' : 'Rupture',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color:
                            produit.enstock
                                ? Colors.green.shade600
                                : Colors.red.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Bouton d'action
                  SizedBox(
                    width: 120,
                    child: ElevatedButton.icon(
                      onPressed:
                          produit.enstock
                              ? () async {
                                final result = await panierProvider.clicPanier(
                                  produit.idproduit,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result['message']),
                                      backgroundColor:
                                          result['success']
                                              ? Colors.green
                                              : Styles.erreur,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              }
                              : null,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
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
                            ? (isPanier ? 'Ajouté' : 'Ajouter')
                            : 'Indisponible',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedCategory != null ||
        _selectedSousCat != null ||
        _selectedType != null ||
        _selectedBrand != null ||
        _minPriceController.text.isNotEmpty ||
        _maxPriceController.text.isNotEmpty;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedSousCat = null;
      _selectedType = null;
      _selectedBrand = null;
      _searchController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _performSearch();
    });
  }

  // Méthodes pour la pagination progressive
  void _onScroll() {
    if (_isLoadingMore || !_hasMoreProducts) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8;

    if (currentScroll >= threshold) {
      _loadMoreProducts();
    }
  }

  void _loadMoreProducts() {
    if (_isLoadingMore || !_hasMoreProducts) return;

    setState(() => _isLoadingMore = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          final currentDisplayedCount = _currentBatch * _batchSize;
          final nextBatchEnd = (_currentBatch + 1) * _batchSize;

          if (nextBatchEnd <= _allFilteredProducts.length) {
            _currentBatch++;
            _displayedProducts = _allFilteredProducts.take(nextBatchEnd).toList();
          } else {
            _hasMoreProducts = false;
          }

          _isLoadingMore = false;
        });
      }
    });
  }

  void _resetPagination() {
    _currentBatch = 1;
    _displayedProducts = [];
    _hasMoreProducts = true;
    _isLoadingMore = false;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  bool _areListsEqual(List<Produit> list1, List<Produit> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].idproduit != list2[i].idproduit) {
        return false;
      }
    }
    return true;
  }

  // Méthode pour afficher un snackbar (copiée de voirplus.dart)
}
