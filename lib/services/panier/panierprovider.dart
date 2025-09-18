import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:kanjad/services/panier/panierlocal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PanierProvider with ChangeNotifier {
  final PanierLocal _panierLocal = PanierLocal.instance;
  final SupabaseService _databaseService = SupabaseService.instance;

  List<String> _idsPanier = [];
  Map<String, int> _productQuantities = {};
  bool _isInitialized = false;
  bool _isLoaded = false;

  StreamSubscription? _panierSubscription;

  // Getters
  UnmodifiableListView<String> get idsPanier =>
      UnmodifiableListView(_idsPanier);
  UnmodifiableMapView<String, int> get productQuantities =>
      UnmodifiableMapView(_productQuantities);
  bool get isInitialized => _isInitialized;
  bool get isLoaded => _isLoaded;

  PanierProvider() {
    _initialize();
    _setupAuthListener();
  }

  @override
  void dispose() {
    _stopRealTimeListening();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _panierLocal.init();
    await loadPanier();
    _isInitialized = true;
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _startRealTimeListening();
        loadPanier(); // Sync with remote on login
      } else if (event == AuthChangeEvent.signedOut) {
        _stopRealTimeListening();
        loadPanier(); // Load local data on logout
      }
    });
  }

  void _startRealTimeListening() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _stopRealTimeListening(); // Ensure no duplicate subscriptions

    _panierSubscription = _databaseService
        .getPanierStream(user.id)
        .listen((remoteData) async {
      // Convert list of maps to the provider's map format
      final remotePanier = {
        for (var item in remoteData)
          item['idproduit'] as String: item['quantite'] as int
      };

      // Update provider state
      _productQuantities = remotePanier;
      _idsPanier = remotePanier.keys.toList();

      // Sync this new state with the local cache
      await _panierLocal.setPanier(_productQuantities);

      notifyListeners();
    }, onError: (error) {
      print('Error in cart real-time subscription: $error');
      // Optionally, fall back to a full reload on error
      loadPanier();
    });
  }

  void _stopRealTimeListening() {
    _panierSubscription?.cancel();
    _panierSubscription = null;
  }

  Future<void> loadPanier() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      try {
        final remotePanier = await _databaseService.getPanier(user.id);
        final localPanier = await _panierLocal.getQuantities();

        // Merge logic: local changes take precedence
        final mergedPanier = {...remotePanier, ...localPanier};

        // Sync the merged result back to both local and remote
        await _panierLocal.setPanier(mergedPanier);
        await _databaseService.synchroniserPanier(
          user.id,
          mergedPanier,
        );

        _productQuantities = mergedPanier;
        _idsPanier = mergedPanier.keys.toList();
      } catch (e) {
        // On error, fall back to local data
        _productQuantities = await _panierLocal.getQuantities();
        _idsPanier = await _panierLocal.getPanier();
      }
    } else {
      // No user, load from local storage only
      _productQuantities = await _panierLocal.getQuantities();
      _idsPanier = await _panierLocal.getPanier();
    }

    _isLoaded = true;
    notifyListeners();
  }

  bool isProduitInPanier(String produitId) {
    return _idsPanier.contains(produitId);
  }

  int getQuantity(String produitId) {
    return _productQuantities[produitId] ?? 1;
  }

  Future<void> updateQuantity(String produitId, int quantite) async {
    try {
      // Optimistic UI update
      _productQuantities[produitId] = quantite;
      notifyListeners();
      await _panierLocal.updateQuantity(produitId, quantite);

      // Sync with remote if user is logged in
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _databaseService.updateQuantitePanier(
          user.id,
          produitId,
          quantite,
        );
      }
    } catch (e) {
      print('Error updating quantity: $e');
      await loadPanier(); // Revert on error
      rethrow;
    }
  }

  Future<Map<String, dynamic>> clicPanier(
    String produitId, {
    int quantite = 1,
  }) async {
    final isInCart = isProduitInPanier(produitId);
    String message;

    // Optimistic UI update
    if (isInCart) {
      _idsPanier.remove(produitId);
      _productQuantities.remove(produitId);
      message = 'Retiré du panier';
    } else {
      _idsPanier.add(produitId);
      _productQuantities[produitId] = quantite;
      message = 'Ajouté au panier';
    }
    notifyListeners();

    // Persist changes
    try {
      if (isInCart) {
        await _panierLocal.retirerDuPanier(produitId);
      } else {
        await _panierLocal.ajouterAuPanier(produitId, quantite: quantite);
      }
      return {'success': true, 'message': message};
    } on SocketException {
      // Revert state on network error
      await loadPanier();
      return {
        'success': false,
        'message': 'Veuillez vérifier votre connexion internet.',
      };
    } catch (e) {
      // Revert state on other errors
      await loadPanier();
      print('Error in clicPanier: $e');
      return {
        'success': false,
        'message': 'Erreur lors de la mise à jour du panier.',
      };
    }
  }

  Future<void> clearPanier() async {
    try {
      await _panierLocal.viderPanier();
      await loadPanier();
    } catch (e) {
      print('Error clearing cart: $e');
      rethrow;
    }
  }
}
