// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:kanjad/services/panier/panierprovider.dart';
import 'package:kanjad/services/souhaits/souhaitsprovider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kanjad/services/providers/produitprovider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kanjad/widgets/animationdemarrage.dart';
import 'package:kanjad/utilitaires/servicemessagerie.dart';
import 'package:kanjad/utilitaires/redirigeur.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kanjad/services/BD/supabase.dart';

class EcranDemarrage extends StatefulWidget {
  const EcranDemarrage({super.key});

  @override
  State<EcranDemarrage> createState() => _EcranDemarrageState();
}

class _EcranDemarrageState extends State<EcranDemarrage> {
  String _loadingMessage = 'Préparation de l\'application...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    // Start initialization after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndNavigate();
    });
  }

  Future<void> _initializeAndNavigate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

      // Load all data, forcing a refresh only on the first launch
      await _loadAllData(forceRefresh: isFirstLaunch);

      // Mark first launch as complete
      if (isFirstLaunch) {
        await prefs.setBool('is_first_launch', false);
      }

      setState(() {
        _loadingMessage = 'Tout est prêt !  sur Kanjad.';
        _progress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 2300));

      if (mounted) {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          final userProfile = await SupabaseService.instance.getUtilisateur(
            currentUser.id,
          );
          if (userProfile != null) {
            navigateBasedOnRoleOnStart(context, userProfile);
          } else {
            Navigator.pushReplacementNamed(context, '/accueil');
          }
        } else {
          Navigator.pushReplacementNamed(context, '/accueil');
        }
      }
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Une erreur est survenue lors du chargement.';
      if (e is SocketException) {
        errorMessage =
            'Erreur de connexion. Veuillez vérifier votre connexion internet et réessayer.';
      }
      MessagerieService.showError(context, errorMessage);
      // Optionally, navigate to an error screen or allow retry
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/connexion');
      }
    }
  }

  Future<void> _loadAllData({bool forceRefresh = false}) async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final panierProvider = Provider.of<PanierProvider>(context, listen: false);
    final souhaitsProvider = Provider.of<SouhaitsProvider>(
      context,
      listen: false,
    );

    // Step 1: Load products
    setState(() {
      _loadingMessage = 'Chargement des produits...';
      _progress = 0.1;
    });
    await productProvider.loadProducts(forceRefresh: forceRefresh);

    // Step 2: Load cart
    setState(() {
      _loadingMessage = 'Synchronisation du panier...';
      _progress = 0.5;
    });
    await panierProvider.loadPanier();

    // Step 3: Load wishlist
    setState(() {
      _loadingMessage = 'Synchronisation des souhaits...';
      _progress = 0.8;
    });
    await souhaitsProvider.loadSouhaits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 163, 14, 3),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 100,
              child: Image.asset('assets/images/kanjad.png'),
            ),
            const SizedBox(height: 40),
            AnimatedLoadingBar(progress: _progress),
            const SizedBox(height: 20),
            Text(
              _loadingMessage,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
