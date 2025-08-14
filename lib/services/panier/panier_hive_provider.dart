import 'package:flutter/material.dart';
import 'package:RAS/services/local/hive_storage.dart';

class PanierHiveProvider with ChangeNotifier {
  final HiveStorage _hiveStorage = HiveStorage();
  
  Map<String, int> _quantities = {};
  bool _isInitialized = false;

  Map<String, int> get quantities => _quantities;
  bool get isInitialized => _isInitialized;

  int get count => _quantities.length;
  
  double get totalAmount {
    // Cette valeur devrait être calculée en fonction des produits réels
    // Vous devrez passer les produits pour calculer le montant total
    return 0.0;
  }

  Future<void> init() async {
    await _hiveStorage.init();
    // Récupérer les données du stockage Hive
    _quantities = _hiveStorage.getCartItems();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> ajouterAuPanier(String produitId, {int quantite = 1}) async {
    await _hiveStorage.addToCart(produitId, quantity: quantite);
    _quantities = _hiveStorage.getCartItems();
    notifyListeners();
  }

  Future<void> retirerDuPanier(String produitId) async {
    await _hiveStorage.removeFromCart(produitId);
    _quantities = _hiveStorage.getCartItems();
    notifyListeners();
  }

  Future<void> updateQuantity(String produitId, int quantite) async {
    await _hiveStorage.updateCartQuantity(produitId, quantite);
    _quantities = _hiveStorage.getCartItems();
    notifyListeners();
  }

  bool isProduitInPanier(String produitId) {
    return _quantities.containsKey(produitId);
  }

  int getQuantity(String produitId) {
    return _quantities[produitId] ?? 0;
  }

  Future<void> viderPanier() async {
    await _hiveStorage.clearCart();
    _quantities = {};
    notifyListeners();
  }
  
  int getTotalItems() {
    return _quantities.values.fold(0, (sum, quantity) => sum + quantity);
  }
}