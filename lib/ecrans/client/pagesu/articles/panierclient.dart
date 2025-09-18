import 'dart:io';
import 'package:kanjad/basicdata/utilisateur.dart';
import 'package:kanjad/services/panier/panierprovider.dart';
import 'package:kanjad/services/providers/produitprovider.dart';
import 'package:kanjad/utilitaires/themeglobal.dart';
import 'package:kanjad/widgets/indicateurdetats.dart';
import 'package:kanjad/widgets/suggestionsproduits.dart';
import 'package:kanjad/widgets/dialogueskanjad.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/commande.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:kanjad/basicdata/produit.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:provider/provider.dart';

// Custom exception for cart-related errors
class CartException implements Exception {
  final String message;
  CartException(this.message);
}

class Panier extends StatefulWidget {
  const Panier({super.key});

  @override
  State<Panier> createState() => _PanierState();
}

class _PanierState extends State<Panier>
    with
        AutomaticKeepAliveClientMixin<Panier>,
        WidgetsBindingObserver,
        TickerProviderStateMixin {
  String? _selectedDeliveryMethod;
  String? _deliveryInfoOption;
  Utilisateur? _temporaryUser;
  String _selectedPaymentMethod = 'ELECTRONIC';
  bool _confirmTerms = false;
  late AnimationController _animationController;
 

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _actualiser();
    }
  }
//Procedure pour actualiser le panier
  Future<void> _actualiser() async {
    final panierProvider = Provider.of<PanierProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    await Future.wait([
      panierProvider.loadPanier(),
      productProvider.loadProducts(forceRefresh: true),
    ]);
  }
//Message de confirmation
  void _messageConfirmation(String message, {bool isSuccess = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: isSuccess ? Styles.vert : Styles.erreur,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(
              isSuccess
                  ? FluentIcons.checkmark_circle_20_regular
                  : FluentIcons.error_circle_20_regular,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
//Procedures pour vider le panier
  void _viderPanier() async {
    final panierProvider = Provider.of<PanierProvider>(context, listen: false);
    final result = await DialogService.showConfirmationDialog(
      context,
      title: 'Vider le panier',
      content:
          'Êtes-vous sûr de vouloir vider votre panier ? Cette action est irréversible.',
      confirmText: 'Vider',
      cancelText: 'Annuler',
    );

    if (result == true && mounted) {
      await panierProvider.clearPanier();
      _messageConfirmation('Panier vidé avec succès', isSuccess: true);
    }
  }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final panierProvider = context.watch<PanierProvider>();
    final productProvider = context.watch<ProductProvider>();

    final allProduits = productProvider.products;
    final produitsPanier =
        allProduits
            .where((p) => panierProvider.idsPanier.contains(p.idproduit))
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: NestedScrollView(
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              SliverAppBar(
                automaticallyImplyLeading: false,
                expandedHeight: 100,
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
                                'Mon Panier',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 55),
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
                        // Bouton d'actualisation
                        IconButton(
                          onPressed: _actualiser,
                          icon: Icon(
                            FluentIcons.arrow_sync_20_regular,
                            color: Styles.rouge,
                          ),
                          tooltip: 'Actualiser',
                        ),
                        // Titre de la section avec nombre d'articles
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '${produitsPanier.length} article${produitsPanier.length > 1 ? 's' : ''} dans votre panier',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        // Bouton vider le panier
                        // if (produitsPanier.isNotEmpty)
                        //   IconButton(
                        //     onPressed: _viderPanier,
                        //     icon: Icon(
                        //       FluentIcons.delete_20_regular,
                        //       color: Styles.rouge,
                        //     ),
                        //     tooltip: 'Vider le panier',
                        //   ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: RefreshIndicator(
            onRefresh: _actualiser,
            color: Styles.rouge,
            backgroundColor: Colors.white,
            child: _corpsPanier(
              panierProvider,
              productProvider,
              produitsPanier,
              allProduits,
            ),
          ),
        ),
      ),
    );
  }
//Corps principal du panier
  Widget _corpsPanier(
    PanierProvider panierProvider,
    ProductProvider productProvider,
    List<Produit> produitsPanier,
    List<Produit> allProduits,
  ) {
    if (productProvider.isLoading && productProvider.products.isEmpty) {
      return const LoadingIndicator();
    }

    if (productProvider.error != null) {
      return RefreshIndicator(
        onRefresh: _actualiser,
        color: Styles.rouge,
        backgroundColor: Colors.white,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: EdgeInsets.all(constraints.maxWidth > 800 ? 48 : 24),
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Styles.rouge,
                          size: constraints.maxWidth > 800 ? 80 : 60,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Erreur de chargement des produits',
                          style: TextStyle(
                            fontSize: constraints.maxWidth > 800 ? 24 : 18,
                            fontWeight: FontWeight.w600,
                            color: Styles.bleu,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Une erreur s\'est produite lors du chargement.\nVérifiez votre connexion et réessayez.',
                          style: TextStyle(
                            fontSize: constraints.maxWidth > 800 ? 16 : 14,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: constraints.maxWidth > 800 ? 200 : 160,
                          child: ElevatedButton(
                            onPressed: _actualiser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Styles.rouge,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Réessayer',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    if (produitsPanier.isEmpty) {
      return EmptyStateWidget(
        message:
            'Votre panier est vide.Les produits ajoutés s\'afficherons ici',
        icon: FluentIcons.shopping_bag_tag_24_regular,
        onRetry: _actualiser,
      );
    }

    double subTotal = 0;
    try {
      for (var produit in produitsPanier) {
        double prix = produit.prix;
        int currentQuantity = panierProvider.getQuantity(produit.idproduit);
        subTotal += prix * currentQuantity;
      }
    } catch (e) {
      // Log error for debugging
      debugPrint('Error calculating subtotal: $e');
    }

    const double fraisLivraison = 0;
    final bool livraisonDomiciliee = _selectedDeliveryMethod == 'Livraison à domicile';
    final double finalTotal =
        livraisonDomiciliee ? subTotal + fraisLivraison : subTotal;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _detailsEnColonne(
                    produitsPanier,
                    subTotal,
                    finalTotal,
                    livraisonDomiciliee,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  _detailMethodes(panierProvider.idsPanier),
                ],
              ),
            );
          } else {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _detailsEnColonne(
                            produitsPanier,
                            subTotal,
                            finalTotal,
                            livraisonDomiciliee,
                          ),
                        ),
                        const SizedBox(width: 24),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: _detailMethodes(
                            panierProvider.idsPanier,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 1,
                  child: _SuggestionsPanier(
                    produitsPanier: produitsPanier,
                    allProduits: allProduits,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
//Affiche tous les details en colonne
  Widget _detailsEnColonne(
    List<Produit> produitsPanier,
    double subTotal,
    double finalTotal,
    bool livraisonDomiciliee,
  ) {
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
              onPressed: _viderPanier,
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
            return _carteProduits(produitsPanier[index]);
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sous-total :',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      _formatPrice(subTotal),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                if (livraisonDomiciliee) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Frais de livraison :',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _formatPrice(0),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(color: Colors.black54, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total à payer :  \n${_formatPrice(finalTotal)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
//Detail des methodes de livraison
  Widget _detailMethodes(List<String> idsPanier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: const Color.fromARGB(255, 243, 243, 243),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _sectionLivraison(),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: const Color.fromARGB(255, 243, 243, 243),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _informationsLivraison(),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: const Color.fromARGB(255, 243, 243, 243),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _methodesPaiement(),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: const Color.fromARGB(255, 243, 243, 243),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _sectionConfirmation(),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed:
              (_confirmTerms && _isFormValid(idsPanier))
                  ? () async {
                    try {
                      final user = Supabase.instance.client.auth.currentUser;
                      if (user == null) {
                        _seConnecter();
                        return;
                      }
                      await _validation(idsPanier);
                    } on SocketException {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Styles.erreur,
                          content: Text(
                            'Veuillez vérifier votre connexion internet.',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Styles.erreur,
                          content: Text(
                            e is CartException
                                ? e.message
                                : 'Une erreur est survenue.',
                          ),
                        ),
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
          icon: Icon(Icons.shopping_cart_checkout, color: Styles.blanc),
          label: const Text(
            'Créer la commande',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
        const SizedBox(height: 50),
      ],
    );
  }
//Verifie la validite du formulaire (si des choix ont ete fait)
  bool _isFormValid(List<String> idsPanier) {
    if (_selectedDeliveryMethod == null) return false;
    if (_deliveryInfoOption == null) return false; // Nouvelle condition
    if (idsPanier.isEmpty) return false;
    return true;
  }
//Les informations de livraison qui proviennent du profil
  Widget _informationsLivraison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations de livraison :',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        RadioListTile<String>(
          title: const Text('Utiliser les informations de mon profil'),
          value: 'profil',
          groupValue: _deliveryInfoOption,
          onChanged: (value) {
            setState(() {
              _deliveryInfoOption = value;
              _temporaryUser = null; // On annule les infos temporaires
            });
          },
          activeColor: Styles.rouge,
        ),
        RadioListTile<String>(
          title: const Text('Modifier pour cette commande'),
          value: 'modifier',
          groupValue: _deliveryInfoOption,
          onChanged: (value) {
            setState(() {
              _deliveryInfoOption = value;
            });
            if (value == 'modifier') {
              _modifierInfosLivraison();
            }
          },
          activeColor: Styles.rouge,
        ),
      ],
    );
  }
//Dialogue pour modifier les informations de livraison
  Future<void> _modifierInfosLivraison() async {
    final currentUser = await SupabaseService.instance
        .getUtilisateur(Supabase.instance.client.auth.currentUser!.id);
    if (currentUser == null) return; // Ne pas ouvrir si le profil n'existe pas

    // Utilise les données temporaires si elles existent, sinon celles du profil
    final initialUser = _temporaryUser ?? currentUser;

    final addressController = TextEditingController(text: initialUser.addresse ?? '');
    final cityController = TextEditingController(text: initialUser.villeutilisateur ?? '');
    final countryController = TextEditingController(text: initialUser.pays ?? 'Cameroun');
    final postalController = TextEditingController(text: initialUser.codepostal ?? '');
    final phoneController = TextEditingController(text: initialUser.numeroutilisateur ?? '');

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Styles.rouge.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Styles.rouge,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(FluentIcons.location_24_regular,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          "Modifier l'adresse",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Styles.bleu),
                        ),
                      ),
                    ],
                  ),
                ),
                // Form Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           TextFormField(
                            controller: phoneController,
                            decoration: kanjadInputDecoration('Numéro de téléphone',
                                icon: FluentIcons.phone_24_regular),
                            validator: (v) =>
                                v!.isEmpty ? 'Champ requis' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: countryController,
                            decoration: kanjadInputDecoration('Pays',
                                icon: FluentIcons.earth_24_regular),
                            validator: (v) =>
                                v!.isEmpty ? 'Champ requis' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: cityController,
                            decoration: kanjadInputDecoration('Ville',
                                icon: FluentIcons.city_24_regular),
                            validator: (v) =>
                                v!.isEmpty ? 'Champ requis' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: addressController,
                            decoration: kanjadInputDecoration(
                                'Adresse (Rue, quartier)',
                                icon: FluentIcons.home_24_regular),
                            validator: (v) =>
                                v!.isEmpty ? 'Champ requis' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: postalController,
                            decoration: kanjadInputDecoration(
                                'Code Postal (Optionnel)',
                                icon: FluentIcons.book_letter_20_filled),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Styles.rouge,
                            foregroundColor: Colors.white),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              // On crée une nouvelle instance de l'utilisateur avec les données mises à jour
                              _temporaryUser = Utilisateur(
                                idutilisateur: currentUser.idutilisateur,
                                nomutilisateur: currentUser.nomutilisateur,
                                prenomutilisateur: currentUser.prenomutilisateur,
                                emailutilisateur: currentUser.emailutilisateur,
                                roleutilisateur: currentUser.roleutilisateur,
                                numeroutilisateur: phoneController.text.trim(),
                                addresse: addressController.text.trim(),
                                villeutilisateur: cityController.text.trim(),
                                pays: countryController.text.trim(),
                                codepostal: postalController.text.trim(),
                              );
                            });
                            Navigator.of(context).pop();
                            _updateProfil();
                          }
                        },
                        child: const Text('Enregistrer'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
//Mettre a jour le profil
  Future<void> _updateProfil() async {
    final result = await DialogService.showConfirmationDialog(
      context,
      title: 'Mettre à jour le profil ?',
      content:
          'Voulez-vous enregistrer ces informations comme votre nouvelle adresse de livraison par défaut ?',
      confirmText: 'Oui, mettre à jour',
      cancelText: 'Non, juste pour cette fois',
    );

    if (result == true) {
      if (_temporaryUser != null) {
        try {
          // Utilisation de la même logique que monprofil.dart avec upsert
          await Supabase.instance.client
              .from('utilisateurs')
              .upsert(_temporaryUser!.toMap());
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Profil mis à jour avec succès !'),
              backgroundColor: Colors.green));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }
//Toutes les methodes de paiement
  Widget _methodesPaiement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisir une méthode de paiement :',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        RadioListTile<String>(
          title: const Text('Paiement électronique (Mobile Money)'),
          value: 'ELECTRONIC',
          groupValue: _selectedPaymentMethod,
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value!;
            });
          },
          activeColor: Styles.rouge,
        ),
        RadioListTile<String>(
          title: const Text('Paiement à la livraison (en espèces)'),
          value: 'CASH',
          groupValue: _selectedPaymentMethod,
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value!;
            });
          },
          activeColor: Styles.rouge,
        ),
      ],
    );
  }
//Dialogue pour forcer a se connecter
  void _seConnecter() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => KanJadInfoDialog(
            title: 'Connexion requise',
            content:
                'Vous devez vous connecter pour valider votre commande. Vos données de commande seront sauvegardées.',
            buttonText: 'Connexion',
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/connexion');
            },
            icon: Icons.account_circle,
          ),
    );
  }
//Validation des informations du formulaire
  Future<void> _validation(List<String> idsPanier) async {
    final panierProvider = Provider.of<PanierProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw CartException('Utilisateur non connecté');

      if (!_isFormValid(idsPanier)) {
        throw CartException('Veuillez remplir tous les champs requis.');
      }

      final SupabaseService databaseService = SupabaseService.instance;
      final utilisateur = _temporaryUser ?? await databaseService.getUtilisateur(user.id);
      if (utilisateur == null) {
        throw CartException('Profil utilisateur introuvable.');
      }

      final allProduits = productProvider.products;
      final produitsPanier =
          allProduits.where((p) => idsPanier.contains(p.idproduit)).toList();

      if (produitsPanier.isEmpty) throw CartException('Votre panier est vide.');

      double grandTotal = 0;
      final produitsAvecQuantite = produitsPanier.map((produit) {
        int quantite = panierProvider.getQuantity(produit.idproduit);
        grandTotal += produit.prix * quantite;
        return {
          'idproduit': produit.idproduit,
          'nomproduit': produit.nomproduit,
          'prix': produit.prix,
          'quantite': quantite,
        };
      }).toList();

      const double fraisLivraison = 0;
      if (_selectedDeliveryMethod == 'Livraison à domicile') {
        grandTotal += fraisLivraison;
      }

      final nouvelleCommande = Commande(
        idcommande: '', // Supabase will generate this
        datecommande: DateTime.now().toIso8601String(),
        notecommande: '',
        pays: utilisateur.pays ?? 'Cameroun',
        addresse: utilisateur.addresse ?? '',
        prixcommande: grandTotal,
        ville: utilisateur.villeutilisateur ?? '',
        codepostal: utilisateur.codepostal ?? '',
        utilisateur: utilisateur,
        produits: produitsAvecQuantite,
        methodepaiement: _selectedPaymentMethod,
        choixlivraison: _selectedDeliveryMethod!,
        statutpaiement: 'En attente',
        numeropaiement: '',
      );

      await databaseService.addCommande(nouvelleCommande);
      await panierProvider.clearPanier();

      setState(() {
        _selectedDeliveryMethod = null;
        _confirmTerms = false;
        _deliveryInfoOption = null;
        _temporaryUser = null;
      });

      if (mounted) {
        if (_selectedDeliveryMethod == 'Retrait en boutique') {
          await DialogService.showSuccessDialog(
            context,
            title: 'Commande validée !',
            content:
                'Votre commande a bien été enregistrée. Vous pouvez passer en boutique pour la récupérer.',
            buttonText: 'Continuer',
          );
        } else if (_selectedDeliveryMethod == 'Livraison à domicile' &&
            _selectedPaymentMethod == 'CASH') {
          await DialogService.showSuccessDialog(
            context,
            title: 'Commande validée !',
            content:
                'Votre commande a bien été enregistrée. Elle sera livrée à votre adresse. Le paiement se fera à la livraison.',
            buttonText: 'Continuer',
          );
        } else {
          // Home delivery with ELECTRONIC payment
          await DialogService.showSuccessDialog(
            context,
            title: 'Commande enregistrée',
            content:
                'Votre commande a été enregistrée. Vous pouvez maintenant procéder au paiement depuis la page de vos commandes.',
            buttonText: 'Continuer',
          );
        }
      }
    } catch (e, s) {
      // Log error for debugging
      debugPrint('Erreur lors de la validation de la commande: $e\n$s');
      throw CartException('Erreur lors de la validation de la commande: $e');
    }
  }
//Format du prix
  String _formatPrice(double price) {
    final formatter = NumberFormat("#,##0.00", "fr_FR");
    return '${formatter.format(price)} CFA';
  }
//Carte des produits
  Widget _carteProduits(Produit produit) {
    final panierProvider = context.read<PanierProvider>();
    int quantiteSouhaitee = panierProvider.getQuantity(produit.idproduit);
    double itemTotal = produit.prix * quantiteSouhaitee;

    return Card(
      color: const Color.fromARGB(255, 245, 229, 229),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                          produit.nomproduit,
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
                                  () => _modifierQuantite(
                                    panierProvider,
                                    produit.idproduit,
                                    quantiteSouhaitee + 1,
                                  ),
                            ),
                            const SizedBox(width: 10),
                            _boutonQuantite(
                              icon: Icons.remove,
                              onPressed:
                                  () => _modifierQuantite(
                                    panierProvider,
                                    produit.idproduit,
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
                                  () => panierProvider.clicPanier(
                                    produit.idproduit,
                                  ),
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
//Modifier la quantite d'un produit choisi
  Future<void> _modifierQuantite(
    PanierProvider provider,
    String productId,
    int newQuantity,
  ) async {
    // Ne pas permettre une quantité inférieure à 1
    if (newQuantity < 1) {
      // Au lieu de simplement retourner, on supprime le produit du panier
      await provider.clicPanier(productId);
      return;
    }

    // Mettre à jour la quantité du produit dans le panier
    await provider.updateQuantity(productId, newQuantity);
  }
//Bouton pour augmenter ou diminuer la quantite
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
//Section des informations de livraison
  Widget _sectionLivraison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisir une méthode de livraison :',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        CheckboxListTile(
          title: const Text('Je veux être livré à Domicile'),
          value: _selectedDeliveryMethod == 'Livraison à domicile',
          onChanged: (value) {
            setState(() {
              _selectedDeliveryMethod = value! ? 'Livraison à domicile' : null;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: Styles.rouge,
        ),
        CheckboxListTile(
          title: const Text('Je viendrai prendre en boutique'),
          value: _selectedDeliveryMethod == 'Retrait en boutique',
          onChanged: (value) {
            setState(() {
              _selectedDeliveryMethod = value! ? 'Retrait en boutique' : null;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: Styles.rouge,
        ),
      ],
    );
  }
//Section de confirmation des informations
  Widget _sectionConfirmation() {
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
//Suggestions du panier pour engager encore plus la clientele et l'incite a l'achat
class _SuggestionsPanier extends StatelessWidget {
  final List<Produit> produitsPanier;
  final List<Produit> allProduits;

  const _SuggestionsPanier({
    required this.produitsPanier,
    required this.allProduits,
  });

  @override
  Widget build(BuildContext context) {
    final panierProvider = context.watch<PanierProvider>();
    final categoriesInCart = produitsPanier.map((p) => p.categorie).toSet();

    final suggestions =
        allProduits.where((p) {
          return categoriesInCart.contains(p.categorie) &&
              !produitsPanier.any((pc) => pc.idproduit == p.idproduit);
        }).toList();

    if (suggestions.isEmpty) {
      return const Center(child: Text('Aucune suggestion pour le moment.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Vous pourriez aussi aimer\nd\'autres produits de cette categorie !',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 3,
          child: ListView.builder(
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final produit = suggestions[index];
              return ProduitSuggestionCard(
                produit: produit,
                isActionDone: panierProvider.isProduitInPanier(
                  produit.idproduit,
                ),
                actionText: 'Ajouter',
                doneText: 'Ajouté',
                actionIcon: FluentIcons.shopping_bag_tag_24_regular,
                doneIcon: FluentIcons.shopping_bag_tag_24_filled,
                onAction: () {
                  panierProvider.clicPanier(produit.idproduit);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
