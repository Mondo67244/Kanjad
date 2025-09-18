import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'dart:async';

// import '../local/pont_stockage.dart';

class PanierLocal {
  PanierLocal._internal();
  static final PanierLocal _instance = PanierLocal._internal();
  static PanierLocal get instance => _instance;
  SharedPreferences? _prefs;
  final SupabaseService _databaseService = SupabaseService.instance;

  final StreamController<int> _cartCountController =
      StreamController<int>.broadcast();
  Stream<int> get cartCountStream => _cartCountController.stream;

  static const String _keyPanier = 'panier';
  static const String _keyQuantities = 'quantities';
  static const String _keyCartJustCleared = 'cart_just_cleared';

  Future<void> init() async {
    try {
      developer.log('Initializing PanierLocal', name: 'PanierLocal.init');
      _prefs = await SharedPreferences.getInstance();
      // Emit initial count
      final count = await getTotalItems();
      _cartCountController.add(count);
      developer.log(
        'Successfully initialized PanierLocal with $count items',
        name: 'PanierLocal.init',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error initializing PanierLocal. Error: $e',
        name: 'PanierLocal.init',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur d\'initialisation du PanierLocal: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<String>> getPanier() async {
    try {
      final panier = _prefs?.getStringList(_keyPanier) ?? [];
      developer.log(
        'Retrieved cart with ${panier.length} items',
        name: 'PanierLocal.getPanier',
      );
      return panier;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting cart. Error: $e',
        name: 'PanierLocal.getPanier',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur de récupération du panier: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<Map<String, int>> getQuantities() async {
    try {
      final String? quantitiesJson = _prefs?.getString(_keyQuantities);
      if (quantitiesJson != null) {
        try {
          final result = Map<String, int>.from(jsonDecode(quantitiesJson));
          developer.log(
            'Retrieved quantities for ${result.length} items',
            name: 'PanierLocal.getQuantities',
          );
          return result;
        } catch (e, stackTrace) {
          developer.log(
            'Error decoding quantities. Error: $e',
            name: 'PanierLocal.getQuantities',
            error: e,
            stackTrace: stackTrace,
          );
          print('Erreur de décodage des quantités: $e');
          print('Stack trace: $stackTrace');
          return {};
        }
      }
      developer.log(
        'No quantities found, returning empty map',
        name: 'PanierLocal.getQuantities',
      );
      return {};
    } catch (e, stackTrace) {
      developer.log(
        'Error getting quantities. Error: $e',
        name: 'PanierLocal.getQuantities',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur de récupération des quantités: $e');
      print('Stack trace: $stackTrace');
      return {};
    }
  }

  Future<void> setPanier(Map<String, int> panier) async {
    try {
      developer.log(
        'Setting cart with ${panier.length} items',
        name: 'PanierLocal.setPanier',
      );
      final List<String> ids = panier.keys.toList();
      await _prefs?.setStringList(_keyPanier, ids);
      await _prefs?.setString(_keyQuantities, jsonEncode(panier));

      // Notify listeners of cart count change
      final count = await getTotalItems();
      _cartCountController.add(count);
      developer.log('Successfully set cart', name: 'PanierLocal.setPanier');
    } catch (e, stackTrace) {
      developer.log(
        'Error setting cart. Error: $e',
        name: 'PanierLocal.setPanier',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur lors de la mise à jour du panier: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> ajouterAuPanier(String idproduit, {int quantite = 1}) async {
    try {
      developer.log(
        'Adding product $idproduit to cart with quantity $quantite',
        name: 'PanierLocal.ajouterAuPanier',
      );
      final panier = await getPanier();
      if (!panier.contains(idproduit)) {
        panier.add(idproduit);
        await _prefs?.setStringList(_keyPanier, panier);
      }
      final quantities = await getQuantities();
      quantities[idproduit] = quantite;
      await _prefs?.setString(_keyQuantities, jsonEncode(quantities));

      // Notify listeners of cart count change
      final count = await getTotalItems();
      _cartCountController.add(count);

      // Si l'utilisateur est connecté, synchroniser avec Supabase
      final User? user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _databaseService.ajouterAuPanier(user.id, idproduit, quantite);
      }
      developer.log(
        'Successfully added product $idproduit to cart',
        name: 'PanierLocal.ajouterAuPanier',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error adding product $idproduit to cart. Error: $e',
        name: 'PanierLocal.ajouterAuPanier',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur lors de l\'ajout au panier: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> retirerDuPanier(String idproduit) async {
    try {
      developer.log(
        'Removing product $idproduit from cart',
        name: 'PanierLocal.retirerDuPanier',
      );
      final panier = await getPanier();
      panier.remove(idproduit);
      await _prefs?.setStringList(_keyPanier, panier);
      final quantities = await getQuantities();
      quantities.remove(idproduit);
      await _prefs?.setString(_keyQuantities, jsonEncode(quantities));

      // Notify listeners of cart count change
      final count = await getTotalItems();
      _cartCountController.add(count);

      // Si l'utilisateur est connecté, synchroniser avec Supabase
      final User? user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _databaseService.retirerDuPanier(user.id, idproduit);
      }
      developer.log(
        'Successfully removed product $idproduit from cart',
        name: 'PanierLocal.retirerDuPanier',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error removing product $idproduit from cart. Error: $e',
        name: 'PanierLocal.retirerDuPanier',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur lors du retrait du panier: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateQuantity(String idproduit, int quantite) async {
    try {
      developer.log(
        'Updating quantity for product $idproduit to $quantite',
        name: 'PanierLocal.updateQuantity',
      );
      final quantities = await getQuantities();
      quantities[idproduit] = quantite;
      await _prefs?.setString(_keyQuantities, jsonEncode(quantities));

      // Notify listeners of cart count change
      final count = await getTotalItems();
      _cartCountController.add(count);

      developer.log(
        'Successfully updated quantity for product $idproduit',
        name: 'PanierLocal.updateQuantity',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error updating quantity for product $idproduit. Error: $e',
        name: 'PanierLocal.updateQuantity',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur lors de la mise à jour de la quantité: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> saveDeliveryMethod(String method) async {
    try {
      developer.log(
        'Saving delivery method: $method',
        name: 'PanierLocal.saveDeliveryMethod',
      );
      await _prefs?.setString('delivery_method', method);
      developer.log(
        'Successfully saved delivery method',
        name: 'PanierLocal.saveDeliveryMethod',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error saving delivery method. Error: $e',
        name: 'PanierLocal.saveDeliveryMethod',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur lors de l\'enregistrement de la méthode de livraison: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<String?> getDeliveryMethod() async {
    try {
      final method = _prefs?.getString('delivery_method');
      developer.log(
        'Retrieved delivery method: $method',
        name: 'PanierLocal.getDeliveryMethod',
      );
      return method;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting delivery method. Error: $e',
        name: 'PanierLocal.getDeliveryMethod',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur lors de la récupération de la méthode de livraison: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<void> savePaymentMethod(String method) async {
    try {
      developer.log(
        'Saving payment method: $method',
        name: 'PanierLocal.savePaymentMethod',
      );
      await _prefs?.setString('payment_method', method);
      developer.log(
        'Successfully saved payment method',
        name: 'PanierLocal.savePaymentMethod',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error saving payment method. Error: $e',
        name: 'PanierLocal.savePaymentMethod',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur lors de l\'enregistrement de la méthode de paiement: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<String?> getPaymentMethod() async {
    try {
      final method = _prefs?.getString('payment_method');
      developer.log(
        'Retrieved payment method: $method',
        name: 'PanierLocal.getPaymentMethod',
      );
      return method;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting payment method. Error: $e',
        name: 'PanierLocal.getPaymentMethod',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur lors de la récupération de la méthode de paiement: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<void> viderPanier() async {
    try {
      developer.log('Clearing cart', name: 'PanierLocal.viderPanier');
      await _prefs?.remove(_keyPanier);
      await _prefs?.remove(_keyQuantities);

      // Marquer le panier comme venant d'être vidé pour protéger la synchro
      await _prefs?.setBool(_keyCartJustCleared, true);

      // Notify listeners of cart count change
      _cartCountController.add(0);

      // Si l'utilisateur est connecté, vider aussi le panier Supabase
      final User? user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _databaseService.viderPanier(user.id);
      }
      developer.log(
        'Successfully cleared cart',
        name: 'PanierLocal.viderPanier',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error clearing cart. Error: $e',
        name: 'PanierLocal.viderPanier',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur lors du vidage du panier: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<bool> wasJustCleared() async {
    try {
      final result = _prefs?.getBool(_keyCartJustCleared) ?? false;
      developer.log(
        'Cart was just cleared: $result',
        name: 'PanierLocal.wasJustCleared',
      );
      return result;
    } catch (e, stackTrace) {
      developer.log(
        'Error checking if cart was just cleared. Error: $e',
        name: 'PanierLocal.wasJustCleared',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur lors de la vérification du vidage du panier: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  Future<void> clearJustClearedFlag() async {
    try {
      developer.log(
        'Clearing cart just cleared flag',
        name: 'PanierLocal.clearJustClearedFlag',
      );
      await _prefs?.remove(_keyCartJustCleared);
      developer.log(
        'Successfully cleared cart just cleared flag',
        name: 'PanierLocal.clearJustClearedFlag',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error clearing cart just cleared flag. Error: $e',
        name: 'PanierLocal.clearJustClearedFlag',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur lors de la suppression du flag de vidage du panier: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Nouvelle méthode pour obtenir le nombre total d\'articles dans le panier
  Future<int> getTotalItems() async {
    try {
      final quantities = await getQuantities();
      int total = 0;
      for (var quantity in quantities.values) {
        total += quantity;
      }
      developer.log(
        'Total items in cart: $total',
        name: 'PanierLocal.getTotalItems',
      );
      return total;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting total items in cart. Error: $e',
        name: 'PanierLocal.getTotalItems',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur lors du calcul du nombre total d\'articles: $e');
      print('Stack trace: $stackTrace');
      return 0;
    }
  }

  // Nouvelle méthode pour obtenir le nombre de produits uniques dans le panier
  Future<int> getUniqueItemsCount() async {
    try {
      final panier = await getPanier();
      developer.log(
        'Unique items in cart: ${panier.length}',
        name: 'PanierLocal.getUniqueItemsCount',
      );
      return panier.length;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting unique items count. Error: $e',
        name: 'PanierLocal.getUniqueItemsCount',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur lors de la récupération du nombre d\'articles uniques: $e');
      print('Stack trace: $stackTrace');
      return 0;
    }
  }

  void dispose() {
    developer.log('Disposing PanierLocal', name: 'PanierLocal.dispose');
    _cartCountController.close();
  }
}
