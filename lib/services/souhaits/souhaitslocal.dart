import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'dart:async';
import 'dart:developer' as developer;

// import '../local/pont_stockage.dart';

class SouhaitsLocal {
  SouhaitsLocal._internal();
  static final SouhaitsLocal _instance = SouhaitsLocal._internal();
  static SouhaitsLocal get instance => _instance;
  // final _stockage = PontStockage.instance;
  // final _key = 'souhaits';
  SharedPreferences? _prefs;
  final SupabaseService _databaseService = SupabaseService.instance;

  final StreamController<int> _wishlistCountController =
      StreamController<int>.broadcast();
  Stream<int> get wishlistCountStream => _wishlistCountController.stream;

  Future<void> init() async {
    try {
      developer.log('Initializing SouhaitsLocal', name: 'SouhaitsLocal.init');
      // await _stockage.init();
      _prefs = await SharedPreferences.getInstance();
      // Emit initial count
      final count = (await getSouhaits()).length;
      _wishlistCountController.add(count);
      developer.log(
        'Successfully initialized SouhaitsLocal with $count items',
        name: 'SouhaitsLocal.init',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error initializing SouhaitsLocal. Error: $e',
        name: 'SouhaitsLocal.init',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur d\'initialisation des souhaits: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<String>> getSouhaits() async {
    try {
      // return _stockage.getList(_key);
      final souhaits = _prefs?.getStringList('souhaits') ?? [];
      developer.log(
        'Retrieved wishlist with ${souhaits.length} items',
        name: 'SouhaitsLocal.getSouhaits',
      );
      return souhaits;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting wishlist. Error: $e',
        name: 'SouhaitsLocal.getSouhaits',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur de récupération des souhaits: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<void> ajouterAuxSouhaits(String idproduit) async {
    try {
      developer.log(
        'Adding product $idproduit to wishlist',
        name: 'SouhaitsLocal.ajouterAuxSouhaits',
      );
      // await _stockage.addToList(_key, idproduit);
      final souhait = await getSouhaits();
      if (!souhait.contains(idproduit)) {
        souhait.add(idproduit);
        await _prefs?.setStringList('souhaits', souhait);

        // Notify listeners of wishlist count change
        _wishlistCountController.add(souhait.length);
      }

      // Si l'utilisateur est connecté, synchroniser avec Supabase
      final User? user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _databaseService.ajouterAuxSouhaits(user.id, idproduit);
      }
      developer.log(
        'Successfully added product $idproduit to wishlist',
        name: 'SouhaitsLocal.ajouterAuxSouhaits',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error adding product $idproduit to wishlist. Error: $e',
        name: 'SouhaitsLocal.ajouterAuxSouhaits',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur lors de l\'ajout aux souhaits: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> retirerDesSouhaits(String idproduit) async {
    try {
      developer.log(
        'Removing product $idproduit from wishlist',
        name: 'SouhaitsLocal.retirerDesSouhaits',
      );
      // await _stockage.removeFromList(_key, idproduit);
      final souhait = await getSouhaits();
      souhait.remove(idproduit);
      await _prefs?.setStringList('souhaits', souhait);

      // Notify listeners of wishlist count change
      _wishlistCountController.add(souhait.length);

      // Si l'utilisateur est connecté, synchroniser avec Supabase
      final User? user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _databaseService.retirerDesSouhaits(user.id, idproduit);
      }
      developer.log(
        'Successfully removed product $idproduit from wishlist',
        name: 'SouhaitsLocal.retirerDesSouhaits',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error removing product $idproduit from wishlist. Error: $e',
        name: 'SouhaitsLocal.retirerDesSouhaits',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur lors du retrait des souhaits: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  void dispose() {
    developer.log('Disposing SouhaitsLocal', name: 'SouhaitsLocal.dispose');
    _wishlistCountController.close();
  }
}