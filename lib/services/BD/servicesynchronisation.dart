import 'package:kanjad/services/BD/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kanjad/services/panier/panierlocal.dart';
import 'package:kanjad/services/souhaits/souhaitslocal.dart';
import 'dart:developer' as developer;

class SynchronisationService {
  final PanierLocal _panierLocal = PanierLocal.instance;
  final SouhaitsLocal _souhaitsLocal = SouhaitsLocal.instance;
  final SupabaseService _databaseService = SupabaseService.instance;
  final _auth = Supabase.instance.client.auth;

  Future<void> synchroniserPanier() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      developer.log(
        'No user found, skipping cart synchronization',
        name: 'SynchronisationService.synchroniserPanier',
      );
      return;
    }

    try {
      developer.log(
        'Starting cart synchronization for user ID: ${user.id}',
        name: 'SynchronisationService.synchroniserPanier',
      );
      await _panierLocal.init();

      // Get local and remote carts
      final Map<String, int> localPanier = await _panierLocal.getQuantities();
      final Map<String, int> remotePanier = await _databaseService.getPanier(
        user.id,
      );

      // Merge carts - local takes precedence
      final Map<String, int> mergedPanier = {...remotePanier, ...localPanier};

      // Update remote and local carts
      await _databaseService.synchroniserPanier(
        user.id,
        mergedPanier,
      );
      await _panierLocal.setPanier(mergedPanier);

      developer.log(
        'Successfully synchronized cart for user ID: ${user.id}',
        name: 'SynchronisationService.synchroniserPanier',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error synchronizing cart for user ID: ${user.id}. Error: $e',
        name: 'SynchronisationService.synchroniserPanier',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur lors de la synchronisation du panier: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> synchroniserSouhaits() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      developer.log(
        'No user found, skipping wishlist synchronization',
        name: 'SynchronisationService.synchroniserSouhaits',
      );
      return;
    }

    try {
      developer.log(
        'Starting wishlist synchronization for user ID: ${user.id}',
        name: 'SynchronisationService.synchroniserSouhaits',
      );
      await _souhaitsLocal.init();
      final List<String> souhaitsLocal = await _souhaitsLocal.getSouhaits();
      final List<String> souhaitsRemote = []; // Pas de méthode pour récupérer les souhaits distants

      // Fusionner les listes - local prend la priorité
      final Set<String> mergedSouhaits = {...souhaitsRemote, ...souhaitsLocal}.toSet();

      developer.log(
        'Synchronizing ${mergedSouhaits.length} items from local wishlist to remote for user ID: ${user.id}',
        name: 'SynchronisationService.synchroniserSouhaits',
      );
      // Comme pour le panier, la liste de souhaits distante est écrasée par la locale.
      await _databaseService.synchroniserSouhaits(user.id, mergedSouhaits.toList());
      developer.log(
        'Successfully synchronized wishlist for user ID: ${user.id}',
        name: 'SynchronisationService.synchroniserSouhaits',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error synchronizing wishlist for user ID: ${user.id}. Error: $e',
        name: 'SynchronisationService.synchroniserSouhaits',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur lors de la synchronisation des souhaits: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> synchroniserTout() async {
    developer.log(
      'Starting full synchronization',
      name: 'SynchronisationService.synchroniserTout',
    );
    await synchroniserPanier();
    await synchroniserSouhaits();
    developer.log(
      'Completed full synchronization',
      name: 'SynchronisationService.synchroniserTout',
    );
  }
}