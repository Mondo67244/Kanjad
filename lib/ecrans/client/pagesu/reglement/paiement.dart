import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:kanjad/basicdata/commande.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/widgets/dialogueskanjad.dart';
import 'package:kanjad/basicdata/facture.dart';
import 'package:kanjad/basicdata/produit.dart';
import 'package:kanjad/services/BD/supabase.dart';
// import 'dart:math';
import 'package:cinetpay/cinetpay.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Conditional import for dart:js
import 'package:kanjad/utilitaires/js_stub.dart' if (dart.library.js) 'dart:js' as js;

class PaiementPage extends StatefulWidget {
  final Commande commande;

  const PaiementPage({super.key, required this.commande});

  @override
  State<PaiementPage> createState() => _PaiementPageState();
}

class _PaiementPageState extends State<PaiementPage>
    with SingleTickerProviderStateMixin {
  String? _selectedPaymentMethod;
  final TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;
  bool _isSuccess = false;
  bool _isAmountTooHigh = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.commande.numeropaiement.isNotEmpty) {
      _phoneController.text = widget.commande.numeropaiement;
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
    final double amount = widget.commande.prixcommande;
    if (amount > 1500000) {
      setState(() {
        _isAmountTooHigh = true;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _validateAmount(String amount) {
    try {
      double.parse(amount);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _mobilePayment() async {
    if (!_validateAmount(widget.commande.prixcommande.toString())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Montant invalide'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final String? apiKey = dotenv.env['CINETPAY_APIKEY'];
    final String? siteId = dotenv.env['CINETPAY_SITE_ID'];

    if (apiKey == null || siteId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de configuration: Clés CinetPay manquantes.'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
      return;
    }

    final String transactionId =
        'TRANS-${DateTime.now().millisecondsSinceEpoch}';

    String countryCode = _getCountryCode(
      widget.commande.utilisateur.pays ?? 'Cameroun',
    );
    String currencyCode = _getCurrencyCode(
      widget.commande.utilisateur.pays ?? 'Cameroun',
    );

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => CinetPayCheckout(
                title: 'Terminer le paiement',
                configData: {
                  "apikey": apiKey,
                  "site_id": int.parse(siteId),
                  "notify_url":
                      'https://95bace4ae419.ngrok-free.app/cinetpay/notify',
                  "return_url":
                      'https://95bace4ae419.ngrok-free.app/cinetpay/return',
                },
                paymentData: {
                  "amount": (widget.commande.prixcommande).toInt(),
                  "transaction_id": transactionId,
                  "currency": currencyCode,
                  "description":
                      'Paiement pour la commande ${widget.commande.idcommande}',
                  "customer_name":
                      widget
                                  .commande
                                  .utilisateur
                                  .prenomutilisateur
                                  ?.isNotEmpty ==
                              true
                          ? widget.commande.utilisateur.prenomutilisateur
                          : 'Utilisateur',
                  "customer_surname":
                      widget.commande.utilisateur.nomutilisateur?.isNotEmpty ==
                              true
                          ? widget.commande.utilisateur.nomutilisateur
                          : 'Kanjad',
                  "customer_email":
                      widget.commande.utilisateur.emailutilisateur.isNotEmpty
                          ? widget.commande.utilisateur.emailutilisateur
                          : 'contact@kanjad.com',
                  "customer_phone_number":
                      widget
                                  .commande
                                  .utilisateur
                                  .numeroutilisateur
                                  ?.isNotEmpty ==
                              true
                          ? widget.commande.utilisateur.numeroutilisateur
                          : '600000000',
                  "customer_address":
                      (widget.commande.utilisateur.addresse?.isNotEmpty ??
                              false)
                          ? widget.commande.utilisateur.addresse!
                          : 'Non définie',
                  "customer_city":
                      widget
                                  .commande
                                  .utilisateur
                                  .villeutilisateur
                                  ?.isNotEmpty ==
                              true
                          ? widget.commande.utilisateur.villeutilisateur
                          : 'Non définie',
                  "customer_country": countryCode,
                  "customer_state":
                      (widget.commande.utilisateur.region?.isNotEmpty ?? false)
                          ? widget.commande.utilisateur.region!
                          : (widget
                                      .commande
                                      .utilisateur
                                      .villeutilisateur
                                      ?.isNotEmpty ==
                                  true
                              ? widget.commande.utilisateur.villeutilisateur
                              : 'Non défini'),
                  "customer_zip_code":
                      (widget.commande.utilisateur.codepostal?.isNotEmpty ??
                              false)
                          ? widget.commande.utilisateur.codepostal!
                          : '00000',
                  "channels": 'ALL',
                },
                waitResponse: (response) async {
                  print("Payment response: $response");
                  await SupabaseService.instance.updateCommandePaiement(
                    widget.commande.idcommande,
                    'En attente',
                    _selectedPaymentMethod!,
                    _phoneController.text.trim(),
                  );
                  await _pollPaymentStatus(transactionId);
                },
                onError: (error) {
                  try {
                    final jsError = js.context['JSON'].callMethod('stringify', [
                      error,
                    ]);
                    print("Payment error: $jsError");
                  } catch (e) {
                    print("Payment error (raw): $error");
                  }
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur de paiement: $error'),
                      backgroundColor: Colors.red.shade600,
                    ),
                  );
                },
              ),
        ),
      );
    } catch (e) {
      print('Erreur CinetPay: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de paiement: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  void _handleCinetPayResponse(dynamic response) {
    if (!kIsWeb) return;
    try {
      final responseMap = jsonDecode(
        js.context['JSON'].callMethod('stringify', [response]),
      );
      final status = responseMap?['status'];

      if (status == 'ACCEPTED') {
        _paiementReussi();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Paiement échoué ou annulé. Statut: ${status ?? 'inconnu'}',
              ),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors du traitement de la réponse de paiement.',
            ),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Future<void> _webPaymentSeamless() async {
    if (!kIsWeb) return;
    final completer = Completer<void>();

    final String? apiKey = dotenv.env['CINETPAY_APIKEY'];
    final String? siteId = dotenv.env['CINETPAY_SITE_ID'];

    if (apiKey == null || siteId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de configuration: Clés CinetPay manquantes.'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
      return;
    }

    final String transactionId =
        'TRANS-${DateTime.now().millisecondsSinceEpoch}';
    final String notifyUrl =
        'https://95bace4ae419.ngrok-free.app/cinetpay/notify';
    final String currencyCode = _getCurrencyCode(
      widget.commande.utilisateur.pays ?? 'Cameroun',
    );

    final config = {
      'apikey': apiKey,
      'site_id': int.parse(siteId),
      'mode': 'TEST',
      'notify_url': notifyUrl,
    };

    final checkoutData = {
      'transaction_id': transactionId,
      'amount': widget.commande.prixcommande.toInt(),
      'currency': currencyCode,
      'channels': 'ALL',
      'description': 'Paiement pour la commande ${widget.commande.idcommande}',
      'customer_name':
          widget.commande.utilisateur.prenomutilisateur?.isNotEmpty == true
              ? widget.commande.utilisateur.prenomutilisateur!
              : 'Utilisateur',
      'customer_surname':
          widget.commande.utilisateur.nomutilisateur?.isNotEmpty == true
              ? widget.commande.utilisateur.nomutilisateur!
              : 'Kanjad',
      'customer_email':
          widget.commande.utilisateur.emailutilisateur.isNotEmpty
              ? widget.commande.utilisateur.emailutilisateur
              : 'contact@kanjad.com',
      'customer_phone_number':
          widget.commande.utilisateur.numeroutilisateur?.isNotEmpty == true
              ? widget.commande.utilisateur.numeroutilisateur!
              : '600000000',
      'customer_address':
          (widget.commande.utilisateur.addresse?.isNotEmpty ?? false)
              ? widget.commande.utilisateur.addresse!
              : 'Non définie',
      'customer_city':
          widget.commande.utilisateur.villeutilisateur?.isNotEmpty == true
              ? widget.commande.utilisateur.villeutilisateur!
              : 'Non définie',
      'customer_country': _getCountryCode(
        widget.commande.utilisateur.pays ?? 'Cameroun',
      ),
      'customer_state':
          (widget.commande.utilisateur.region?.isNotEmpty ?? false)
              ? widget.commande.utilisateur.region!
              : (widget.commande.utilisateur.villeutilisateur?.isNotEmpty ==
                      true
                  ? widget.commande.utilisateur.villeutilisateur!
                  : 'Non défini'),
      'customer_zip_code':
          (widget.commande.utilisateur.codepostal?.isNotEmpty ?? false)
              ? widget.commande.utilisateur.codepostal!
              : '00000',
    };

    // Attendre que window.CinetPay soit défini (timeout après ~4s)
    dynamic cp;
    int attempts = 0;
    const int maxAttempts = 20;
    while (cp == null && attempts < maxAttempts) {
      cp = js.context['CinetPay'];
      if (cp == null) {
        await Future.delayed(const Duration(milliseconds: 200));
        attempts++;
      }
    }

    if (cp == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CinetPay JS SDK non chargé ou indisponible.'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
      return;
    }

    try {
      // Configurer
      cp.callMethod('setConfig', [js.JsObject.jsify(config)]);

      // Lancer le checkout
      cp.callMethod('getCheckout', [js.JsObject.jsify(checkoutData)]);

      // Callbacks
      cp.callMethod('waitResponse', [
        js.allowInterop((data) {
          _handleCinetPayResponse(data);
          if (!completer.isCompleted) completer.complete();
        }),
      ]);

      cp.callMethod('onError', [
        js.allowInterop((error) {
          try {
            final jsError = js.context['JSON'].callMethod('stringify', [error]);
            print("CinetPay onError: $jsError");
          } catch (e) {
            print("CinetPay onError (raw): $error");
          }
        }),
      ]);
    } catch (e) {
      // Si appel de méthode JS échoue
      print('Erreur lors de l\'appel au SDK CinetPay: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'initialisation de CinetPay: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
      if (!completer.isCompleted) completer.complete();
    }

    return completer.future;
  }

  String _getCountryCode(String countryName) {
    final Map<String, String> countryCodes = {
      'Cameroun': 'CM',
      'France': 'FR',
      'Gabon': 'GA',
      'Tchad': 'TD',
      'RCA': 'CF',
      'Congo': 'CG',
      'Maroc': 'MA',
      'Senegal': 'SN',
      'Côte d\'ivoire': 'CI',
      'Mali': 'ML',
      'Guinée': 'GN',
      'Togo': 'TG',
      'Bénin': 'BJ',
      'Burkina Faso': 'BF',
      'Niger': 'NE',
      'Tunisie': 'TN',
      'Algérie': 'DZ',
      'Belgique': 'BE',
    };

    return countryCodes[countryName] ?? 'CM';
  }

  String _getCurrencyCode(String countryName) {
    final Map<String, String> countryCurrencies = {
      // XAF Zone
      'Cameroun': 'XAF',
      'Congo': 'XAF',
      'Gabon': 'XAF',
      'Tchad': 'XAF',
      'RCA': 'XAF',

      // XOF Zone
      'Côte d\'Ivoire': 'XOF',
      'Sénégal': 'XOF',
      'Mali': 'XOF',
      'Togo': 'XOF',
      'Bénin': 'XOF',
      'Burkina Faso': 'XOF',
      'Niger': 'XOF',

      // Other countries
      'Guinée': 'GNF',
      'France': 'EUR',
      'Belgique': 'EUR',
      'Allemagne': 'EUR',
      'Suisse': 'CHF',
      'Nigeria': 'NGN',
      'États-Unis': 'USD',
      'Canada': 'CAD',
      'Maroc': 'MAD',
      'Tunisie': 'TND',
      'Algérie': 'DZD',
    };

    return countryCurrencies[countryName] ?? 'XAF'; // Default to XAF
  }

  Future<void> _pollPaymentStatus(String transactionId) async {
    await Future.delayed(Duration(seconds: 5));

    try {
      await _paiementReussi();
    } catch (e) {
      print("Erreur de paiement: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la confirmation du paiement: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _paiementReussi() async {
    await SupabaseService.instance.updateCommandePaiement(
      widget.commande.idcommande,
      'Payé',
      _selectedPaymentMethod!,
      _phoneController.text.trim(),
    );
    await _genfactures();

    setState(() {
      _isProcessing = false;
      _isSuccess = true;
      _animationController.forward();
    });

    if (mounted) {
      String dialogTitle = 'Paiement Réussi !';
      String dialogContent;

      if (widget.commande.choixlivraison == 'boutique') {
        dialogContent =
            'Votre commande a été confirmée. Vous pouvez passer en boutique pour la récupérer.';
      } else {
        dialogContent =
            'Votre commande a été confirmée et sera bientôt livrée.';
      }

      await DialogService.showSuccessDialog(
        context,
        title: dialogTitle,
        content: dialogContent,
        buttonText: 'OK',
      );

      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/accueil', (Route<dynamic> route) => false);
      }
    }
  }

  Future<void> _genfactures() async {
    try {
      List<Produit> produitsFacture = [];
      int totalQuantite = 0;

      for (var produitData in widget.commande.produits) {
        produitsFacture.add(
          Produit(
            idproduit: produitData['idproduit'] ?? '',
            nomproduit: produitData['nomproduit'] ?? 'Produit inconnu',
            description: '',
            descriptioncourte: '',
            prix: (produitData['prix'] as num?)?.toDouble() ?? 0.0,
            ancientprix: 0.0,
            vues: 0,
            modele: '',
            marque: '',
            categorie: '',
            type: '',
            souscategorie: '',
            jeveut: false,
            aupanier: false,
            img1: '',
            img2: '',
            img3: '',
            cash: false,
            electronique: false,
            enstock: true,
            quantite: (produitData['quantite'] as num?)?.toInt() ?? 0,
            livrable: true,
            enpromo: false,
            methodelivraison: '',
            createdAt: DateTime.now(),
          ),
        );
        totalQuantite += (produitData['quantite'] as num?)?.toInt() ?? 0;
      }

      double prixfacture = 0;
      try {
        prixfacture = widget.commande.prixcommande;
      } catch (e) {
        print('Erreur lors du parsing du prix: $e');
        prixfacture = 0;
      }

      // const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      // final random = Random();
      // final randomStr = String.fromCharCodes(
      //   Iterable.generate(
      //     5,
      //     (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      //   ),
      // );

      final facture = Facture(
        idfacture: 'FACT - ${widget.commande.idcommande.substring(0, 5)}',
        idcommande: widget.commande.idcommande,
        datefacture: DateTime.now().toIso8601String(),
        utilisateur: widget.commande.utilisateur,
        produits: produitsFacture,
        prixfacture: prixfacture,
        quantite: totalQuantite,
      );

      await SupabaseService.instance.addFacture(facture);
      print('Facture générée et enregistrée: ${facture.idfacture}');
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

    setState(() => _isProcessing = true);

    if (kIsWeb) {
      // On web, we don't await the future to prevent the UI from freezing
      // if the user closes the payment window.
      _webPaymentSeamless();
      // As requested, we stop the loading indicator once the payment UI is launched.
      // This makes the main UI responsive again.
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    } else {
      // The mobile logic remains the same, as it uses Navigator and doesn't hang.
      try {
        await _mobilePayment();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur inattendue: ${e.toString()}'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.commande.methodepaiement != 'ELECTRONIC') {
      // Cette page ne devrait être utilisée que pour les paiements électroniques
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Méthode de paiement non valide pour cette page'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      });
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    double montantTotal;
    try {
      montantTotal = widget.commande.prixcommande;
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

    return WillPopScope(
      onWillPop: () async {
        _confRetour();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('Paiement'),
          backgroundColor: Styles.rouge,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _confRetour,
          ),
        ),
        body: _isSuccess ? _paiementFait() : _vuePaiement(montantTotal),
      ),
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
                '${widget.commande.prixcommande} CFA',
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
                        'Commande #${widget.commande.idcommande.length >= 9 ? widget.commande.idcommande.substring(0, 4).toUpperCase() : widget.commande.idcommande}',
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_isAmountTooHigh)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      child: Text(
                        'Le montant maximum\npour un paiement est de 1.500.000 CFA',
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ElevatedButton(
                  onPressed:
                      _isProcessing || _isAmountTooHigh
                          ? null
                          : _procedePaiement,
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

  Future<void> _confRetour() async {
    if (_isProcessing) {
      return; // Ne pas permettre de quitter pendant le traitement
    }

    final confirm = await DialogService.showConfirmationDialog(
      context,
      title: 'Quitter le paiement',
      content: 'Êtes-vous sûr de vouloir quitter la page de paiement?',
      confirmText: 'OUI',
      cancelText: 'NON',
    );

    if (confirm == true) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Retourner à l'écran précédent
      }
    }
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
