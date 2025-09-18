import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:kanjad/services/souhaits/souhaitslocal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'dart:async';

class SouhaitsProvider with ChangeNotifier {
  final SouhaitsLocal _souhaitsLocal = SouhaitsLocal.instance;
  final SupabaseService _databaseService = SupabaseService.instance;
  
  List<String> _idsSouhaits = [];
  bool _isInitialized = false;
  bool _isLoaded = false;
  
  // Real-time subscription
  StreamSubscription? _wishlistSubscription;

  // Getters
  UnmodifiableListView<String> get idsSouhaits =>
      UnmodifiableListView(_idsSouhaits);
  bool get isInitialized => _isInitialized;
  bool get isLoaded => _isLoaded;

  SouhaitsProvider() {
    _initialize();
    _setupAuthListener();
  }

  Future<void> _initialize() async {
    await _souhaitsLocal.init();
    await loadSouhaits();
    _isInitialized = true;
  }
  
  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        // User signed in, start real-time listening
        _startRealTimeListening();
        // Refresh data to sync with remote
        loadSouhaits();
      } else if (data.event == AuthChangeEvent.signedOut) {
        // User signed out, stop real-time listening
        _stopRealTimeListening();
        // Reload from local storage only
        loadSouhaits();
      }
    });
  }
  
  void _startRealTimeListening() {
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    _stopRealTimeListening(); // Stop any existing subscription
    
    _wishlistSubscription = Supabase.instance.client
        .from(_databaseService.souhaitsTable)
        .stream(primaryKey: ['idutilisateur', 'idproduit'])
        .eq('idutilisateur', user.id)
        .listen((data) {
          // Process real-time changes incrementally
          _processWishlistChanges(data);
        }, onError: (error) {
          print('Error in wishlist real-time subscription: $error');
          // Fallback to full reload on error
          loadSouhaits();
        });
  }
  
  void _processWishlistChanges(List<Map<String, dynamic>> changes) {
    // Process the real-time changes without full reload
    for (var change in changes) {
      final productId = change['idproduit'] as String;
      
      // Check if item exists in our local list
      final isItemInList = _idsSouhaits.contains(productId);
      
      // Since this is a wishlist table, if it appears in changes, 
      // it means it should be in the wishlist
      if (!isItemInList) {
        _idsSouhaits.add(productId);
      }
    }
    
    // Also check for items that were removed
    final currentIds = changes.map((c) => c['idproduit'] as String).toSet();
    _idsSouhaits.removeWhere((id) => !currentIds.contains(id));
    
    notifyListeners();
  }
  
  void _stopRealTimeListening() {
    _wishlistSubscription?.cancel();
    _wishlistSubscription = null;
  }

  Future<void> loadSouhaits() async {
    final User? user = Supabase.instance.client.auth.currentUser;
    
    if (user != null) {
      // If user is authenticated, load from database
      try {
        final remoteWishlist = await _databaseService.getSouhaits(user.id);
        final localWishlist = await _souhaitsLocal.getSouhaits();
        
        // Merge remote and local wishlists (remote takes precedence)
        final mergedWishlist = [...localWishlist];
        for (String item in remoteWishlist) {
          if (!mergedWishlist.contains(item)) {
            mergedWishlist.add(item);
          }
        }
        
        // Update local storage with merged wishlist
        await _souhaitsLocal.init();
        for (String item in mergedWishlist) {
          if (!localWishlist.contains(item)) {
            await _souhaitsLocal.ajouterAuxSouhaits(item);
          }
        }
        
        _idsSouhaits = mergedWishlist;
      } catch (e) {
        // If remote loading fails, fall back to local wishlist
        _idsSouhaits = await _souhaitsLocal.getSouhaits();
      }
    } else {
      // If user is not authenticated, load from local storage only
      _idsSouhaits = await _souhaitsLocal.getSouhaits();
    }
    
    _isLoaded = true;
    notifyListeners();
  }

  bool isProduitInSouhaits(String produitId) {
    return _idsSouhaits.contains(produitId);
  }

  Future<Map<String, dynamic>> clicSouhait(String produitId) async {
    final isInWishlist = isProduitInSouhaits(produitId);
    String message;

    if (isInWishlist) {
      _idsSouhaits.remove(produitId);
      message = 'Retiré des souhaits';
    } else {
      _idsSouhaits.add(produitId);
      message = 'Ajouté aux souhaits';
    }
    notifyListeners();

    try {
      if (isInWishlist) {
        await _souhaitsLocal.retirerDesSouhaits(produitId);
      } else {
        await _souhaitsLocal.ajouterAuxSouhaits(produitId);
      }
      return {'success': true, 'message': message};
    } catch (e) {
      // Even if the remote sync fails, the local change is already reflected.
      // We can optionally show a message to the user.
      print('Error syncing with remote: $e');
      return {'success': false, 'message': 'Erreur de synchronisation.'};
    }
  }
  
  Future<void> refresh() async {
    await loadSouhaits();
  }
  
  @override
  void dispose() {
    _stopRealTimeListening();
    super.dispose();
  }
}