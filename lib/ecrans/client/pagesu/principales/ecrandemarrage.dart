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
      // Just show the animation and navigate. Data loading is now deferred.
      setState(() {
        _loadingMessage = 'Bienvenue sur Kanjad...';
        _progress = 0.5;
      });

      // Simulate a short delay for the animation
      await Future.delayed(const Duration(milliseconds: 2500));

      setState(() {
        _loadingMessage = 'Tout est prêt !';
        _progress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          final userProfile = await SupabaseService.instance.getUtilisateur(
            currentUser.id,
          );
          if (userProfile != null) {
            navigateBasedOnRoleOnStart(context, userProfile);
          } else {
            // If profile doesn't exist for a logged-in user, go to home.
            Navigator.pushReplacementNamed(context, '/accueil');
          }
        } else {
          // If no user, go to home.
          Navigator.pushReplacementNamed(context, '/accueil');
        }
      }
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Une erreur est survenue lors du démarrage.';
      if (e is SocketException) {
        errorMessage =
            'Erreur de connexion. Veuillez vérifier votre connexion internet.';
      }
      MessagerieService.showError(context, errorMessage);
      // Fallback to connexion page on critical error
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/connexion');
      }
    }
  }

  // This function is no longer needed here, it will be handled by providers/screens.
  // Future<void> _loadAllData({bool forceRefresh = false}) async { ... }

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
