import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:RAS/services/BD/lienbd.dart';
import 'dart:async';

// import '../local/pont_stockage.dart';

class PanierLocal {
  SharedPreferences? _prefs;
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  
  final StreamController<int> _cartCountController = StreamController<int>.broadcast();
  Stream<int> get cartCountStream => _cartCountController.stream;

  static const String _keyPanier = 'panier';
  static const String _keyQuantities = 'quantities';
  static const String _keyCartJustCleared = 'cart_just_cleared';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Emit initial count
    final count = await getTotalItems();
    _cartCountController.add(count);
  }

  Future<List<String>> getPanier() async {
    return _prefs?.getStringList(_keyPanier) ?? [];
  }

  Future<Map<String, int>> getQuantities() async {
    final String? quantitiesJson = _prefs?.getString(_keyQuantities);
    if (quantitiesJson != null) {
      try {
        return Map<String, int>.from(jsonDecode(quantitiesJson));
      } catch (e) {
        print('Erreur de décodage des quantités: $e');
        return {};
      }
    }
    return {};
  }

  Future<void> ajouterAuPanier(String idProduit, {int quantite = 1}) async {
    final panier = await getPanier();
    if (!panier.contains(idProduit)) {
      panier.add(idProduit);
      await _prefs?.setStringList(_keyPanier, panier);
    }
    final quantities = await getQuantities();
    quantities[idProduit] = quantite;
    await _prefs?.setString(_keyQuantities, jsonEncode(quantities));
    
    // Notify listeners of cart count change
    final count = await getTotalItems();
    _cartCountController.add(count);

    // Si l'utilisateur est connecté, synchroniser avec Supabase
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await _databaseService.ajouterAuPanier(
        user.id,
        idProduit,
        quantite,
      );
    }
  }

  Future<void> retirerDuPanier(String idProduit) async {
    final panier = await getPanier();
    panier.remove(idProduit);
    await _prefs?.setStringList(_keyPanier, panier);
    final quantities = await getQuantities();
    quantities.remove(idProduit);
    await _prefs?.setString(_keyQuantities, jsonEncode(quantities));
    
    // Notify listeners of cart count change
    final count = await getTotalItems();
    _cartCountController.add(count);

    // Si l'utilisateur est connecté, synchroniser avec Supabase
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await _databaseService.retirerDuPanier(user.id, idProduit);
    }
  }

  Future<void> updateQuantity(String idProduit, int quantite) async {
    final quantities = await getQuantities();
    quantities[idProduit] = quantite;
    await _prefs?.setString(_keyQuantities, jsonEncode(quantities));
    
    // Notify listeners of cart count change
    final count = await getTotalItems();
    _cartCountController.add(count);

    // Si l'utilisateur est connecté, synchroniser avec Supabase
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await _databaseService.updateQuantitePanier(
        user.id,
        idProduit,
        quantite,
      );
    }
  }

  Future<void> saveDeliveryMethod(String method) async {
    await _prefs?.setString('delivery_method', method);
  }

  Future<String?> getDeliveryMethod() async {
    return _prefs?.getString('delivery_method');
  }

  Future<void> savePaymentMethod(String method) async {
    await _prefs?.setString('payment_method', method);
  }

  Future<String?> getPaymentMethod() async {
    return _prefs?.getString('payment_method');
  }

  Future<void> viderPanier() async {
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
  }

  Future<bool> wasJustCleared() async {
    return _prefs?.getBool(_keyCartJustCleared) ?? false;
  }

  Future<void> clearJustClearedFlag() async {
    await _prefs?.remove(_keyCartJustCleared);
  }

  // Nouvelle méthode pour obtenir le nombre total d'articles dans le panier
  Future<int> getTotalItems() async {
    final quantities = await getQuantities();
    int total = 0;
    for (var quantity in quantities.values) {
      total += quantity;
    }
    return total;
  }

  // Nouvelle méthode pour obtenir le nombre de produits uniques dans le panier
  Future<int> getUniqueItemsCount() async {
    final panier = await getPanier();
    return panier.length;
  }
  
  void dispose() {
    _cartCountController.close();
  }
}