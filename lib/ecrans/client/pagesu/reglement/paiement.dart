import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:RAS/basicdata/commande.dart';
import 'package:RAS/basicdata/style.dart';
import 'package:RAS/basicdata/facture.dart';
import 'package:RAS/basicdata/produit.dart';
import 'package:RAS/services/BD/lienbd.dart';
import 'dart:math';

class paiement extends StatefulWidget {
  final Commande commande;

  const paiement({super.key, required this.commande});

  @override
  State<paiement> createState() => _paiementState();
}

class _paiementState extends State<paiement>
    with SingleTickerProviderStateMixin {
  String? _selectedPaymentMethod;
  final TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;
  bool _isSuccess = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.commande.numeroPaiement.isNotEmpty) {
      _phoneController.text = widget.commande.numeroPaiement;
    }
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    if (_isSuccess) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _updateOrderStatus(String transactionId) async {
    try {
      await SupabaseDatabaseService().updateCommandeStatus(
        transactionId,
        'Payé',
      );
      print('Statut de la commande mis à jour avec succès.');
    } catch (e) {
      print('Erreur lors de la mise à jour du statut de la commande: $e');
    }
  }

  Future<void> _generateAndSaveInvoice() async {
    try {
      List<Produit> produitsFacture = [];
      int totalQuantite = 0;

      for (var produitData in widget.commande.produits) {
        produitsFacture.add(
          Produit(
            idProduit: produitData['idProduit'] ?? '',
            nomProduit: produitData['nomProduit'] ?? 'Produit inconnu',
            description: '',
            descriptionCourte: '',
            prix: produitData['prix'] ?? '0',
            ancientPrix: '',
            vues: '',
            modele: '',
            marque: '',
            categorie: '',
            type: '',
            sousCategorie: '',
            jeVeut: false,
            auPanier: false,
            img1: '',
            img2: '',
            img3: '',
            cash: false,
            electronique: false,
            enStock: true,
            quantite: produitData['quantite'].toString(),
            livrable: true,
            enPromo: false,
            methodeLivraison: '',
          ),
        );
        totalQuantite += (produitData['quantite'] as int?) ?? 0;
      }

      // Parse the price correctly handling decimal values
      int prixFacture = 0;
      try {
        prixFacture = (double.parse(widget.commande.prixCommande)).toInt();
      } catch (e) {
        print('Erreur lors du parsing du prix: $e');
        // Fallback to 0 if parsing fails
        prixFacture = 0;
      }

      final facture = factures(
        idFacture:
            'FACT-${widget.commande.idCommande.toUpperCase()}-${Random().nextInt(1000)}',
        // Using current date and time for the invoice (not the command date)
        dateFacture: DateTime.now().toIso8601String(),
        utilisateur: widget.commande.utilisateur,
        produits: produitsFacture,
        prixFacture: prixFacture,
        quantite: totalQuantite,
      );

      await SupabaseDatabaseService().ajouterFacture(facture);
      print(
        'factures générée et enregistrée avec succès: ${facture.idFacture}',
      );
    } catch (e) {
      print('Erreur lors de la génération de la facture: $e');
    }
  }

  void _procedePaiement() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez sélectionner une méthode de paiement'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (_selectedPaymentMethod != 'CASH' &&
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez entrer votre numéro de téléphone'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isProcessing = false;
      _isSuccess = true;
      _animationController.forward();
    });

    await _updateOrderStatus(widget.commande.idCommande);
    await _generateAndSaveInvoice();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Paiement de ${widget.commande.prixCommande} CFA effectué avec succès !',
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop('success');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double montantTotal;
    try {
      montantTotal = double.parse(widget.commande.prixCommande);
    } catch (e) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('Erreur'),
          backgroundColor: Styles.rouge,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'Le montant de la commande est invalide.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/kanjad.png',
              key: const ValueKey('logo'),
              width: 140,
              height: 50,
            ),
            Transform.translate(
              offset: const Offset(-15, 10),
              child: Text(
                'Paiement',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Styles.rouge,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: _isSuccess ? _paiementFait() : _vuePaiement(montantTotal),
    );
  }

  Widget _paiementFait() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Styles.rouge, Colors.red.shade800],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  FluentIcons.checkmark_circle_24_filled,
                  size: 72,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Paiement Réussi !',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.commande.prixCommande} CFA',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade100,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Votre commande a été confirmée',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vuePaiement(double montantTotal) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    return Center(
      child: Container(
        constraints:
            isWideScreen
                ? const BoxConstraints(maxWidth: 600)
                : const BoxConstraints(maxWidth: 400),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        FluentIcons.payment_24_filled,
                        size: 56,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Montant à payer',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${montantTotal.toStringAsFixed(0)} CFA',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Commande #${widget.commande.idCommande.substring(0, 4).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Méthode de paiement',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _optionPaiement(
                        'MTN Mobile Money',
                        FluentIcons.phone_24_filled,
                        const Color.fromARGB(221, 255, 230, 0),
                        'MTN',
                      ),
                      const SizedBox(height: 12),
                      _optionPaiement(
                        'Orange Money',
                        FluentIcons.phone_24_filled,
                        Colors.orange.shade600,
                        'ORANGE',
                      ),
                      const SizedBox(height: 12),
                      _optionPaiement(
                        'Paiement en espèces',
                        FluentIcons.money_24_filled,
                        Colors.green.shade600,
                        'CASH',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_selectedPaymentMethod != null &&
                    _selectedPaymentMethod != 'CASH')
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Numéro ${_selectedPaymentMethod == 'MTN' ? 'MTN' : 'Orange'}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: 'Ex: 672123456',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Styles.bleu,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              FluentIcons.phone_24_filled,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _procedePaiement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Styles.rouge,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child:
                      _isProcessing
                          ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Text(
                            'Payer maintenant',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionPaiement(
    String title,
    IconData icon,
    Color color,
    String value,
  ) {
    final isSelected = _selectedPaymentMethod == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = value;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? color : Colors.grey.shade800,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  FluentIcons.checkmark_circle_24_filled,
                  color: color,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
