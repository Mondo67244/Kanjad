import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/produit.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/services/panier/panierprovider.dart';
import 'package:kanjad/services/souhaits/souhaitsprovider.dart';
import 'package:kanjad/widgets/dialogueskanjad.dart';
import 'package:kanjad/widgets/imagekanjad.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Details extends StatefulWidget {
  const Details({super.key, required this.produit});
  final Produit produit;

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  late PageController _pageController;
  int _currentPage = 0;
  List<String> _images = [];
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _images =
        [
          widget.produit.img1,
          widget.produit.img2,
          widget.produit.img3,
        ].where((img) => img.isNotEmpty).toList();
    _pageController = PageController();
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final userData =
            await Supabase.instance.client
                .from('utilisateurs')
                .select('roleutilisateur')
                .eq('idutilisateur', user.id)
                .single();

        if (mounted) {
          setState(() {
            _userRole = userData['roleutilisateur'] as String?;
          });
        }
      } catch (e) {
        print('Erreur lors de la récupération du rôle utilisateur: $e');
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleSouhait() async {
    final souhaitsProvider = Provider.of<SouhaitsProvider>(
      context,
      listen: false,
    );
    final result = await souhaitsProvider.clicSouhait(widget.produit.idproduit);
    _reponse(result['message'], isSuccess: result['success']);
  }

  void _togglePanier() async {
    final panierProvider = Provider.of<PanierProvider>(context, listen: false);
    final result = await panierProvider.clicPanier(widget.produit.idproduit);
    _reponse(result['message'], isSuccess: result['success']);
  }

  void _reponse(String message, {bool isSuccess = true, IconData? icon}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor:
            isSuccess ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Styles.blanc,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startDiscussion() {
    if (_userRole == null) {
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Dismiss',
        barrierColor: Colors.black.withOpacity(0.5),
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) => KanJadConfirmationDialog(
          title: 'Connexion requise',
          content: 'Veuillez vous connecter pour envoyer des messages concernant un produit',
          confirmText: 'Se connecter',
          cancelText: 'Annuler',
          onConfirm: () {
            Navigator.of(context).pop();
            Navigator.pushNamed(context, '/connexion');
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      );
    } else {
      Navigator.pushNamed(
        context,
        '/utilisateur/chat',
        arguments: {
          'idproduit': widget.produit.idproduit,
          'nomproduit': widget.produit.nomproduit,
          'isCommercial': false, // Client qui initie la discussion
        },
      );
    }
  }

  Widget _montreLesImages() {
    // Déterminer si on est sur mobile/tablet (layout scrollable)
    final isScrollableLayout = MediaQuery.of(context).size.width <= 964;

    if (_images.isEmpty) {
      return Container(
        height:
            isScrollableLayout
                ? 250
                : double.infinity, // Hauteur fixe seulement pour scrollable
        color: Colors.grey.shade100,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              "Aucune image disponible",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height:
          isScrollableLayout
              ? 300
              : double.infinity, // Hauteur fixe seulement pour scrollable
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Styles.blanc,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((255 * 0.05).round()),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _images.length,
              itemBuilder:
                  (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _appelImages(_images[index]),
                  ),
            ),
          ),
          Positioned(
            bottom: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_images.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentPage == index ? 12 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _currentPage == index
                            ? Styles.rouge
                            : Colors.white.withAlpha((255 * 0.7).round()),
                  ),
                );
              }),
            ),
          ),
          if (_images.length > 1) ...[
            if (_currentPage > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: _fleches(
                  icon: Icons.arrow_back_ios_new,
                  onPressed:
                      () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                ),
              ),
            if (_currentPage < _images.length - 1)
              Align(
                alignment: Alignment.centerRight,
                child: _fleches(
                  icon: Icons.arrow_forward_ios,
                  onPressed:
                      () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _fleches({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((255 * 0.6).round()),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  Widget _detailsContenu() {
    final produit = widget.produit;
    final constraints = MediaQuery.of(context).size.width > 1200;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          constraints ? const SizedBox(height: 50) : const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  produit.nomproduit,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      produit.enstock
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        produit.enstock
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (produit.enpromo) ...[
                Text(
                  '${produit.prix.toStringAsFixed(0)} CFA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${produit.ancientprix.toStringAsFixed(0)} CFA',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ] else
                Text(
                  '${produit.prix.toStringAsFixed(0)} CFA',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade600,
                  ),
                ),
              if (produit.vues >= 100) ...[
                const SizedBox(width: 16),
                Chip(
                  avatar: Icon(FluentIcons.star_20_regular,
                      size: 16, color: Colors.orange.shade700),
                  label: Text(
                    '${produit.vues} vues',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: Colors.orange.shade100,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Caractéristiques du produit :',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 12),
          _carteDetails(produit),
          const SizedBox(height: 24),
          _methodePaiment(produit),
          const SizedBox(height: 24),
          _boutonss(),
        ],
      ),
    );
  }

  Widget _detailsContenumob() {
    final produit = widget.produit;
    final constraints = MediaQuery.of(context).size.width > 1200;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          constraints
              ? const SizedBox(height: 150)
              : const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  produit.nomproduit,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      produit.enstock
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
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
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color:
                        produit.enstock
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (produit.enpromo) ...[
                Text(
                  '${produit.prix.toStringAsFixed(0)} CFA',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${produit.ancientprix.toStringAsFixed(0)} CFA',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ] else
                Text(
                  '${produit.prix.toStringAsFixed(0)} CFA',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade600,
                  ),
                ),
              
            ],
          ),
          if (produit.vues >= 100) ...[
                const SizedBox(width: 16),
                Chip(
                  avatar: Icon(FluentIcons.star_20_regular,
                      size: 16, color: Colors.orange.shade700),
                  label: Text(
                    '${produit.vues} vues',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: Colors.orange.shade100,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ],
          const SizedBox(height: 24),
          Text(
            'Caractéristiques du produit :',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 12),
          _carteDetails(produit),
          const SizedBox(height: 24),
          _boutonss(),
          const SizedBox(height: 24),
          Text(
            'Description Détaillée:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            produit.description.isNotEmpty
                ? produit.description
                : "Aucune description fournie pour ce produit.",
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 24),
          _methodePaiment(produit),
        ],
      ),
    );
  }

  Widget _boutonss() {
    final produit = widget.produit;

    // Si l'utilisateur est commercial, afficher un message d'information
    if (_userRole == 'commercial') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              'Mode commercial',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Boutons normaux pour les clients
    return Consumer2<SouhaitsProvider, PanierProvider>(
      builder: (context, souhaitsProvider, panierProvider, child) {
        final isWished = souhaitsProvider.isProduitInSouhaits(
          produit.idproduit,
        );
        final isInCart = panierProvider.isProduitInPanier(produit.idproduit);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Styles.rouge,
                  side: BorderSide(color: Styles.rouge, width: 1.5),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: produit.enstock ? _toggleSouhait : null,
                icon: Icon(
                  isWished
                      ? FluentIcons.heart_20_filled
                      : FluentIcons.heart_20_regular,
                  size: 20,
                ),
                label: Text(
                  isWished ? 'Souhaité' : 'Je Souhaite',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      produit.enstock ? Styles.bleu : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: produit.enstock ? _togglePanier : null,
                icon: Icon(
                  isInCart
                      ? FluentIcons.shopping_bag_tag_24_filled
                      : FluentIcons.shopping_bag_tag_24_regular,
                  size: 20,
                ),
                label: Text(
                  isInCart ? 'Ajouté !' : 'Ajouter au Panier',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _detailsTxt(Produit produit) {
    final constraints = MediaQuery.of(context).size.width > 1200;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            constraints
                ? const SizedBox(height: 150)
                : const SizedBox(height: 12),
            Text(
              'Description Détaillée:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              produit.description.isNotEmpty
                  ? produit.description
                  : "Aucune description fournie pour ce produit.",
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodePaiment(Produit produit) {
    final cash = produit.cash;
    final electro = produit.electronique;
    String methode = '';
    if (cash == true && electro == true) {
      methode = 'En Espece ou Mobile Money (MTN/ORANGE)';
    } else if (cash == true && electro == false) {
      methode = 'Espece';
    } else if (cash == false && electro == true) {
      methode = 'Mobile Money (MTN/ORANGE)';
    } else {
      methode = 'En attente de confirmation';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Méthodes de paiement acceptées :',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          methode,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _carteDetails(Produit produit) {
    return Card(
      elevation: 0,
      color: Styles.blanc,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _detailsIndividuels(
              FluentIcons.tag_24_regular,
              'Marque',
              produit.marque,
            ),
            const Divider(height: 24, color: Colors.grey),
            _detailsIndividuels(
              FluentIcons.box_24_regular,
              'Modèle',
              produit.modele,
            ),
            const Divider(height: 24, color: Colors.grey),
            _detailsIndividuels(
              FluentIcons.apps_list_detail_24_regular,
              'Type',
              produit.type,
            ),
            const Divider(height: 24, color: Colors.grey),
            _detailsIndividuels(
              FluentIcons.send_clock_20_regular,
              'Livrable',
              produit.livrable ? 'Oui' : 'Non',
            ),
            const Divider(height: 24, color: Colors.grey),
            _detailsIndividuels(
              FluentIcons.document_bullet_list_16_regular,
              'Quantité Dispo',
              produit.quantite.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailsIndividuels(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade500, size: 22),
        const SizedBox(width: 16),
        Text(
          '$label :',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _appelImages(String imageData) {
    return KanjadImage(
      imageData: imageData,
      sousCategorie: widget.produit.souscategorie,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    final produit = widget.produit;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Styles.rouge,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Retour',
        ),
        title: const Text(
          'Détails du produit',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButton:
          _userRole != 'commercial'
              ? FloatingActionButton(
                onPressed: _startDiscussion,
                backgroundColor: Styles.rouge,
                foregroundColor: Colors.white,
                tooltip: 'Discuter de ce produit',
                child: const Icon(Icons.chat_bubble_outline),
              )
              : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 1200) {
              final content = Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1500),
                  child: Row(
                    key: const Key('layout Web'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _montreLesImages()),
                      Expanded(flex: 3, child: _detailsContenu()),
                      Expanded(flex: 3, child: _detailsTxt(produit)),
                    ],
                  ),
                ),
              );
              return Stack(
                children: [
                  content,
                  Positioned(
                    top: 470,
                    left: 700,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => Navigator.of(context).pop(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_back,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Page précédente',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            if (constraints.maxWidth > 964) {
              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: SingleChildScrollView(
                    child: Column(
                      key: const Key('layout tablet'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _montreLesImages(),
                        const SizedBox(height: 16),
                        _detailsContenumob(),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  child: Column(
                    key: const Key('layout Mobile'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _montreLesImages(),
                      const SizedBox(height: 16),
                      _detailsContenumob(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
