import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kanjad/services/panier/panierlocal.dart';
import 'package:kanjad/services/souhaits/souhaitslocal.dart';
import 'dart:async';

class NotificationService with ChangeNotifier {
  final PanierLocal _panierLocal = PanierLocal.instance;
  final SouhaitsLocal _souhaitsLocal = SouhaitsLocal.instance;

  int _cartCount = 0;
  int _wishlistCount = 0;
  int _pendingOrdersCount = 0;

  StreamSubscription<int>? _cartSubscription;
  StreamSubscription<int>? _wishlistSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _ordersSubscription;

  int _unreadMessagesCount = 0;

  int get cartCount => _cartCount;
  int get wishlistCount => _wishlistCount;
  int get pendingOrdersCount => _pendingOrdersCount;
  int get unreadMessagesCount => _unreadMessagesCount;

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
      final _ = response.session?.user;
      _updatePendingOrdersListener();
    });

    // Initialize orders listener
    _updatePendingOrdersListener();
    _setupMessageNotifications();
  }

  void _setupMessageNotifications() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Utiliser le MessageProvider pour écouter les nouveaux messages
      // Cette logique sera appelée depuis l'interface utilisateur quand nécessaire
    }
  }

  // Méthode pour afficher une popup de notification de message
  void showMessageNotification(
    BuildContext context,
    String productId,
    String productName,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nouveau message'),
          content: Text(
            'Vous avez un nouveau message concernant "$productName"',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer le dialog
                Navigator.pushNamed(
                  context,
                  '/utilisateur/chat',
                  arguments: {
                    'idproduit': productId,
                    'nomproduit': productName,
                    'isCommercial': false,
                  },
                );
              },
              child: const Text('Voir le message'),
            ),
          ],
        );
      },
    );
  }

  // Méthode appelée quand l'utilisateur ouvre l'app pour vérifier les messages en arrière-plan
  Future<void> checkMessagesOnAppStart(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('messages')
          .select('idproduit, nomproduit, statut')
          .eq('idutilisateur', user.id)
          .eq('statut', 'envoyé')
          .neq('role', 'client'); // Messages des commerciaux non lus

      if (response.isNotEmpty && context.mounted) {
        final message = response.first;
        showMessageNotification(
          context,
          message['idproduit'],
          message['nomproduit'] ?? 'Produit',
        );
      }
    } catch (e) {
      print('Erreur lors de la vérification des messages: $e');
    }
  }

  // Update unread messages count
  void updateUnreadMessagesCount(int count) {
    if (_unreadMessagesCount != count) {
      _unreadMessagesCount = count;
      notifyListeners();
    }
  }

  void _updatePendingOrdersListener() {
    // Cancel previous subscription if exists
    _ordersSubscription?.cancel();

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _ordersSubscription = Supabase.instance.client
          .from('commandes')
          .stream(primaryKey: ['idcommande'])
          .map((data) {
            return data.where((map) {
              final userId = map['idutilisateur'];
              final status = map['statutpaiement'];
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
          .eq('idutilisateur', user.id)
          .inFilter('statutpaiement', ['Attente', 'En attente']);

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
