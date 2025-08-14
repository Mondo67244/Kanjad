
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:RAS/basicdata/commande.dart';
import 'package:RAS/basicdata/style.dart';
import 'package:RAS/basicdata/utilisateur.dart';
import 'package:RAS/services/BD/lienbd.dart';
import 'package:RAS/basicdata/produit.dart';
import 'package:intl/intl.dart';
import 'package:RAS/services/panier/panier_local.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:RAS/services/synchronisation/notification_service.dart';

// Custom exception for cart-related errors
class CartException implements Exception {
  final String message;
  CartException(this.message);
}

class Panier extends StatefulWidget {
  const Panier({super.key});

  @override
  State<Panier> createState() => PanierState();
}

class PanierState extends State<Panier>
    with AutomaticKeepAliveClientMixin<Panier>, WidgetsBindingObserver {
  late Stream<List<Produit>> _cartProductsStream;
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  final PanierLocal _panierLocal = PanierLocal();
  String? _methodePaiementChoisie;
  String? _selectedDeliveryMethod;
  bool _confirmTerms = false;
  final TextEditingController _numeroPaiementController =
      TextEditingController();
  final FocusNode _numeroPaiementFocusNode =
      FocusNode(); // Add focus node for payment field
  final Map<String, int> _productQuantities = {}; // Add the missing map
  List<String> _idsPanier = [];
  bool _isLoading = true;
  late Future<void> _initFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState(); // Keeps the superclass behavior intact
    _cartProductsStream = _databaseService.getProduitsStream();
    _initFuture = _initPanierLocal();
    WidgetsBinding.instance.addObserver(this); // Add observer for app lifecycle
  }

  @override
  void didUpdateWidget(covariant Panier oldWidget) {
    super.didUpdateWidget(
      oldWidget,
    ); // Ensures AutomaticKeepAliveClientMixin works as intended
  }

  Future<void> _actualiser() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await _initPanierLocal();
      if (mounted) {
        // Refresh notification service
        final notificationService = Provider.of<NotificationService>(
          context,
          listen: false,
        );
        notificationService.refreshCartCount();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Styles.bleu,
            content: Text('Panier mis à jour !'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      _handleError('Erreur lors de l\'actualisation du panier: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSavedMethods() async {
    try {
      final deliveryMethod = await _panierLocal.getDeliveryMethod();
      final paymentMethod = await _panierLocal.getPaymentMethod();
      setState(() {
        _selectedDeliveryMethod = deliveryMethod;
        _methodePaiementChoisie = paymentMethod;
      });
    } catch (e) {
      _handleError('Erreur lors du chargement des méthodes sauvegardées: $e');
    }
  }

  Future<void> _initPanierLocal() async {
    try {
      await _panierLocal.init();
      final ids = await _panierLocal.getPanier();
      final quantities = await _panierLocal.getQuantities();
      setState(() {
        _idsPanier = ids;
        _productQuantities.clear();
        _productQuantities.addAll(quantities);
        for (var id in ids) {
          _productQuantities[id] = _productQuantities[id] ?? 1;
        }
        _isLoading = false;
      });
      await _loadSavedMethods();

      // Refresh notification service
      if (mounted) {
        final notificationService = Provider.of<NotificationService>(
          context,
          listen: false,
        );
        notificationService.refreshCartCount();
      }
    } catch (e) {
      _handleError('Erreur lors de l\'initialisation du panier local: $e');
    }
  }

  Future<void> _retirerDuPanier(String idProduit) async {
    try {
      await _panierLocal.retirerDuPanier(idProduit);
      setState(() {
        _idsPanier.remove(idProduit);
        _productQuantities.remove(idProduit);
      });

      // Refresh notification service
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      notificationService.refreshCartCount();
    } catch (e) {
      _handleError('Erreur lors du retrait du produit: $e');
    }
  }

  Future<void> _viderPanier() async {
    try {
      await _panierLocal.viderPanier();
      setState(() {
        _idsPanier.clear();
        _productQuantities.clear();
      });

      // Refresh notification service
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      notificationService.refreshCartCount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Styles.vert,
            content: Text('Panier vidé avec succès !'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _handleError('Erreur lors du vidage du panier: $e');
    }
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Vider le panier'),
          content: Text(
            'Êtes-vous sûr de vouloir vider votre panier ? Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _viderPanier();
              },
              child: Text('Vider', style: TextStyle(color: Styles.rouge)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateQuantity(String idProduit, int nouvelleQuantite) async {
    if (nouvelleQuantite <= 0) return;
    try {
      await _panierLocal.updateQuantity(idProduit, nouvelleQuantite);
      setState(() {
        _productQuantities[idProduit] = nouvelleQuantite;
      });

      // Refresh notification service
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      notificationService.refreshCartCount();
    } catch (e) {
      _handleError('Erreur lors de la mise à jour de la quantité: $e');
    }
  }

  void _handleError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Styles.erreur,
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _numeroPaiementController.dispose();
    _numeroPaiementFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _actualiser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement du panier...'),
                ],
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erreur: ${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _actualiser,
                    child: Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          backgroundColor: Styles.blanc,
          floatingActionButton: FloatingActionButton.extended(
            heroTag: "panier_actualiser",
            foregroundColor: Styles.blanc,
            backgroundColor: Styles.rouge,
            icon: const Icon(Icons.refresh),
            label: const Text(
              'Actualiser',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            onPressed: _actualiser,
            tooltip: 'Rafraîchir le panier',
          ),
          body: GestureDetector(
            onTap: () {
              // Dismiss keyboard when tapping outside text fields
              FocusScope.of(context).unfocus();
            },
            child: RefreshIndicator(
              onRefresh: _actualiser,
              child: StreamBuilder<List<Produit>>(
                stream: _cartProductsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    _handleError(
                      'Erreur de chargement des produits: ${snapshot.error}',
                    );
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Erreur de chargement des produits'),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _actualiser,
                            child: Text('Réessayer'),
                          ),
                        ],
                      ),
                    );
                  }
                  final produitsPanier =
                      (snapshot.data ?? [])
                          .where((p) => _idsPanier.contains(p.idProduit))
                          .toList();
                  if (produitsPanier.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                        FluentIcons.shopping_bag_tag_24_regular,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                          Text(
                            'Votre panier est vide.\nLes produits ajoutés s\'afficherons ici',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _actualiser,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Styles.rouge,
                          side: BorderSide(color: Styles.rouge),
                        ),
                        child: const Text('Actualiser'),
                      ),

                        ],
                      ),
                    );
                  }
                  double grandTotal = 0;
                  try {
                    for (var produit in produitsPanier) {
                      double prix = double.tryParse(produit.prix) ?? 0.0;
                      int currentQuantity =
                          _productQuantities[produit.idProduit] ?? 1;
                      grandTotal += prix * currentQuantity;
                    }
                  } catch (e) {
                    _handleError('Erreur lors du calcul du total: $e');
                  }
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 700) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildCartDetailsColumn(
                                  produitsPanier,
                                  grandTotal,
                                ),
                                const SizedBox(height: 24),
                                const Divider(),
                                _buildActionDetailsColumn(),
                              ],
                            ),
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(24.0),
                                    child: _buildCartDetailsColumn(
                                      produitsPanier,
                                      grandTotal,
                                    ),
                                  ),
                                ),
                                const VerticalDivider(width: 1),
                                Expanded(
                                  flex: 1,
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(24.0),
                                    child: _buildActionDetailsColumn(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartDetailsColumn(
    List<Produit> produitsPanier,
    double grandTotal,
  ) {
    final taille = MediaQuery.of(context).size.width;
    final estGrand = taille > 650;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Prêt à Commander ?',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: _showClearCartDialog,
              child: Text(
                'Vider le panier',
                style: TextStyle(
                  fontSize: 14,
                  color: Styles.rouge,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Récapitulatif des choix :',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: produitsPanier.length,
          itemBuilder: (context, index) {
            return _buildCartItemCard(produitsPanier[index]);
          },
        ),
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.amber[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                estGrand
                    ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total sans frais de livraison :',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          _formatPrice(grandTotal),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    )
                    : Column(
                      children: [
                        const Text(
                          'Total sans frais de livraison :',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          _formatPrice(grandTotal),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionDetailsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _choixpaiement(),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildDeliverySection(),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildConfirmationSection(),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed:
              (_confirmTerms && _isFormValid())
                  ? () async {
                    try {
                      final user = Supabase.instance.client.auth.currentUser;
                      if (user == null) {
                        _showLoginDialog();
                        return;
                      }
                      await _validateAndProcessOrder();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Styles.vert,
                            content: Text('Commande validée avec succès !'),
                          ),
                        );
                      }
                    } catch (e) {
                      _handleError(
                        'Erreur lors de la validation de la commande: $e',
                      );
                    }
                  }
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Styles.bleu,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          label: const Text(
            'Commander',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
        const SizedBox(height: 50),
      ],
    );
  }

  bool _isFormValid() {
    // Vérifier que la méthode de livraison est sélectionnée
    if (_selectedDeliveryMethod == null) {
      return false;
    }

    // Vérifier que la méthode de paiement est sélectionnée
    if (_methodePaiementChoisie == null) {
      return false;
    }

    // Vérifier le numéro de paiement pour les paiements mobiles
    if (_methodePaiementChoisie == 'MTN' ||
        _methodePaiementChoisie == 'ORANGE') {
      final numero = _numeroPaiementController.text.trim();
      if (numero.isEmpty || !_isValidPhoneNumber(numero)) {
        return false;
      }
    }

    // Vérifier que le panier n'est pas vide
    if (_idsPanier.isEmpty) {
      return false;
    }

    return true;
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Connexion requise'),
          content: Text(
            'Vous devez vous connecter pour valider votre commande. Vos données de commande seront sauvegardées.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/connexion');
              },
              style: TextButton.styleFrom(foregroundColor: Styles.rouge),
              child: Text('Se connecter'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _validateAndProcessOrder() async {
    try {
      // 1. Vérifier l'utilisateur connecté
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw CartException('Utilisateur non connecté');
      }

      // 2. Vérifier la validité du formulaire
      if (!_isFormValid()) {
        throw CartException('Veuillez remplir tous les champs requis.');
      }

      // 3. Récupérer les données utilisateur
      Utilisateur utilisateur;
      try {
        final u = await _databaseService.getUtilisateur(user.id);
        if (u == null) {
          throw CartException(
            'Utilisateur non trouvé dans la base de données. Veuillez vous connecter.',
          );
        }
        utilisateur = u;
      } catch (e) {
        throw CartException(
          'Erreur lors de la récupération des données utilisateur: $e',
        );
      }

      // 4. Récupérer les produits du panier
      List<Produit> produitsPanier = [];
      try {
        final allProduits = await _databaseService.getProduits();
        produitsPanier =
            allProduits.where((p) => _idsPanier.contains(p.idProduit)).toList();
      } catch (e) {
        throw CartException('Erreur lors de la récupération des produits: $e');
      }

      if (produitsPanier.isEmpty) {
        throw CartException('Votre panier est vide.');
      }

      // 5. Calculer le total et préparer les données
      double grandTotal = 0;
      final produitsAvecQuantite =
          produitsPanier.map((produit) {
            int quantite = _productQuantities[produit.idProduit] ?? 1;
            double prix = double.tryParse(produit.prix) ?? 0.0;
            grandTotal += prix * quantite;

            return {
              'idProduit': produit.idProduit,
              'nomProduit': produit.nomProduit,
              'prix': produit.prix,
              'quantite': quantite,
            };
          }).toList();

      // 6. Créer la commande
      final commande = Commande(
        idCommande: '',
        dateCommande: DateTime.now().toIso8601String(),
        noteCommande: '',
        pays: 'Cameroun',
        rue: '',
        prixCommande: grandTotal.toStringAsFixed(2),
        ville: utilisateur.villeUtilisateur,
        codePostal: '',
        utilisateur: utilisateur,
        produits: produitsAvecQuantite,
        methodePaiment: _methodePaiementChoisie!,
        choixLivraison: _selectedDeliveryMethod!,
        numeroPaiement: _numeroPaiementController.text.trim(),
        statutPaiement: 'Attente',
      );

      // 7. Ajouter la commande à Supabase
      await _databaseService.addCommande(commande);

      // 8. Vider le panier local
      await _panierLocal.viderPanier();

      // 9. Mettre à jour l'état local
      setState(() {
        _idsPanier.clear();
        _productQuantities.clear();
        _methodePaiementChoisie = null;
        _selectedDeliveryMethod = null;
        _confirmTerms = false;
        _numeroPaiementController.clear();
      });
    } catch (e) {
      throw CartException('Erreur lors de la validation de la commande: $e');
    }
  }

  bool _isValidPhoneNumber(String number) {
    final phoneRegex = RegExp(r'^\+?\d{8,15}$');
    return phoneRegex.hasMatch(number);
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat("#,##0.00", "fr_FR");
    return '${formatter.format(price)} CFA';
  }

  //
  Widget _buildCartItemCard(Produit produit) {
    double prix = double.tryParse(produit.prix) ?? 0.0;
    int quantiteSouhaitee = _productQuantities[produit.idProduit] ?? 1;
    double itemTotal = prix * quantiteSouhaitee;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    'x$quantiteSouhaitee',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          produit.nomProduit,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            _boutonQuantite(
                              icon: Icons.add,
                              onPressed:
                                  () => _updateQuantity(
                                    produit.idProduit,
                                    quantiteSouhaitee + 1,
                                  ),
                            ),
                            const SizedBox(width: 10),
                            _boutonQuantite(
                              icon: Icons.remove,
                              onPressed:
                                  () => _updateQuantity(
                                    produit.idProduit,
                                    quantiteSouhaitee - 1,
                                  ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed:
                                  () => _retirerDuPanier(produit.idProduit),
                              padding: const EdgeInsets.all(4),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatPrice(itemTotal),
              style: const TextStyle(
                fontSize: 15,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boutonQuantite({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 20, color: Colors.black54),
      ),
    );
  }

  // Le widget pour choisir entre MTN ORANGE ou RIEN des deux
  Widget _choixpaiement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisir une méthode de paiement :',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        _boutonRadio('MTN Mobile Money', 'MTN'),
        _boutonRadio('Orange Money', 'ORANGE'),
        _boutonRadio('Monnaie Physique', 'CASH'),
        const SizedBox(height: 8),
        TextFormField(
          enabled:
              (_methodePaiementChoisie == 'MTN' ||
                      _methodePaiementChoisie == 'ORANGE')
                  ? true
                  : false,
          controller: _numeroPaiementController,
          focusNode: _numeroPaiementFocusNode,
          decoration: InputDecoration(
            labelText: 'Entrer le numéro de paiement',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            errorText:
                (_methodePaiementChoisie == 'MTN' ||
                            _methodePaiementChoisie == 'ORANGE') &&
                        !_isValidPhoneNumber(_numeroPaiementController.text)
                    ? 'Numéro de téléphone invalide'
                    : null,
          ),
          keyboardType: TextInputType.phone,
          onChanged: (value) => setState(() {}),
          // Clear focus when user submits
          onFieldSubmitted: (value) {
            _numeroPaiementFocusNode.unfocus();
          },
        ),
      ],
    );
  }

  Widget _boutonRadio(String title, String value) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: _methodePaiementChoisie,
      onChanged: (newValue) {
        setState(() {
          _methodePaiementChoisie = newValue;
          if (newValue == 'CASH') {
            _numeroPaiementController.clear();
          }
        });
        if (newValue != null) {
          _panierLocal.savePaymentMethod(newValue);
        }
      },
      contentPadding: EdgeInsets.zero,
      activeColor: Styles.rouge,
    );
  }

  Widget _buildDeliverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisir une méthode de livraison :',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        CheckboxListTile(
          title: const Text('Je veux être livré à Domicile'),
          value: _selectedDeliveryMethod == 'domicile',
          onChanged: (value) {
            setState(
              () => _selectedDeliveryMethod = value! ? 'domicile' : null,
            );
            if (_selectedDeliveryMethod != null) {
              _panierLocal.saveDeliveryMethod(_selectedDeliveryMethod!);
            }
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: Styles.rouge,
        ),
        CheckboxListTile(
          title: const Text('Je viendrai prendre en boutique'),
          value: _selectedDeliveryMethod == 'boutique',
          onChanged: (value) {
            setState(
              () => _selectedDeliveryMethod = value! ? 'boutique' : null,
            );
            if (_selectedDeliveryMethod != null) {
              _panierLocal.saveDeliveryMethod(_selectedDeliveryMethod!);
            }
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: Styles.rouge,
        ),
      ],
    );
  }

  Widget _buildConfirmationSection() {
    return Row(
      children: [
        Checkbox(
          value: _confirmTerms,
          onChanged: (value) {
            setState(() => _confirmTerms = value!);
          },
          activeColor: Styles.rouge,
        ),
        const Expanded(
          child: Text(
            "Je confirme mes choix et m'engage à payer le prix total des articles",
          ),
        ),
      ],
    );
  }
}
