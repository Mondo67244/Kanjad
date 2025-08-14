import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:RAS/services/panier/panier_local.dart';
import 'package:RAS/services/souhaits/souhaits_local.dart';
import 'dart:async';

class NotificationService with ChangeNotifier {
  final PanierLocal _panierLocal = PanierLocal();
  final SouhaitsLocal _souhaitsLocal = SouhaitsLocal();

  int _cartCount = 0;
  int _wishlistCount = 0;
  int _pendingOrdersCount = 0;

  StreamSubscription<int>? _cartSubscription;
  StreamSubscription<int>? _wishlistSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _ordersSubscription;

  int get cartCount => _cartCount;
  int get wishlistCount => _wishlistCount;
  int get pendingOrdersCount => _pendingOrdersCount;

  NotificationService() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _panierLocal.init();
    await _souhaitsLocal.init();

    // Listen to cart changes
    _cartSubscription = _panierLocal.cartCountStream.listen((count) {
      _cartCount = count;
      notifyListeners();
    });

    // Listen to wishlist changes
    _wishlistSubscription = _souhaitsLocal.wishlistCountStream.listen((count) {
      _wishlistCount = count;
      notifyListeners();
    });

    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((
      AuthState response,
    ) {
      final user = response.session?.user;
      _updatePendingOrdersListener();
    });

    // Initialize orders listener
    _updatePendingOrdersListener();
  }

  void _updatePendingOrdersListener() {
    // Cancel previous subscription if exists
    _ordersSubscription?.cancel();

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _ordersSubscription = Supabase.instance.client
          .from('commandes')
          .stream(primaryKey: ['id'])
          .map((data) {
            return data.where((map) {
              final userId = map['utilisateur']?['idUtilisateur'];
              final status = map['statutPaiement'];
              return userId == user.id &&
                  (status == 'Attente' || status == 'En attente');
            }).toList();
          })
          .listen((List<Map<String, dynamic>> data) {
            if (_pendingOrdersCount != data.length) {
              _pendingOrdersCount = data.length;
              notifyListeners();
            }
          });
    } else {
      if (_pendingOrdersCount != 0) {
        _pendingOrdersCount = 0;
        notifyListeners();
      }
    }
  }

  // Public methods to manually refresh counts
  Future<void> refreshCartCount() async {
    final totalItems = await _panierLocal.getTotalItems();
    if (_cartCount != totalItems) {
      _cartCount = totalItems;
      notifyListeners();
    }
  }

  Future<void> refreshWishlistCount() async {
    final wishlistItems = await _souhaitsLocal.getSouhaits();
    if (_wishlistCount != wishlistItems.length) {
      _wishlistCount = wishlistItems.length;
      notifyListeners();
    }
  }

  Future<void> refreshPendingOrdersCount() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final data = await Supabase.instance.client
          .from('commandes')
          .select()
          .eq('utilisateur->idUtilisateur', user.id)
          .inFilter('statutPaiement', ['Attente', 'En attente']);

      if (_pendingOrdersCount != data.length) {
        _pendingOrdersCount = data.length;
        notifyListeners();
      }
    } else {
      if (_pendingOrdersCount != 0) {
        _pendingOrdersCount = 0;
        notifyListeners();
      }
    }
  }

  Future<void> refreshAllCounts() async {
    await refreshCartCount();
    await refreshWishlistCount();
    await refreshPendingOrdersCount();
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    _wishlistSubscription?.cancel();
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
