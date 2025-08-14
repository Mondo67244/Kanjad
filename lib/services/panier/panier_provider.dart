import 'package:flutter/material.dart';
import 'package:RAS/services/panier/panier_local.dart';

class PanierProvider with ChangeNotifier {
  final PanierLocal _panierLocal = PanierLocal();
  Map<String, int> _quantities = {};
  List<String> _produitIds = [];

  Map<String, int> get quantities => _quantities;
  List<String> get produitIds => _produitIds;

  int get count => _produitIds.length;

  double get totalAmount {
    // Cette valeur devrait être calculée en fonction des produits réels
    // Vous devrez passer les produits pour calculer le montant total
    return 0.0;
  }

  Future<void> init() async {
    await _panierLocal.init();
    _produitIds = await _panierLocal.getPanier();
    _quantities = await _panierLocal.getQuantities();
    notifyListeners();
  }

  Future<void> ajouterAuPanier(String produitId, {int quantite = 1}) async {
    await _panierLocal.ajouterAuPanier(produitId, quantite: quantite);
    _produitIds = await _panierLocal.getPanier();
    _quantities = await _panierLocal.getQuantities();
    notifyListeners();
  }

  Future<void> retirerDuPanier(String produitId) async {
    await _panierLocal.retirerDuPanier(produitId);
    _produitIds = await _panierLocal.getPanier();
    _quantities = await _panierLocal.getQuantities();
    notifyListeners();
  }

  Future<void> updateQuantity(String produitId, int quantite) async {
    await _panierLocal.updateQuantity(produitId, quantite);
    _quantities = await _panierLocal.getQuantities();
    notifyListeners();
  }

  bool isProduitInPanier(String produitId) {
    return _produitIds.contains(produitId);
  }

  int getQuantity(String produitId) {
    return _quantities[produitId] ?? 0;
  }

  Future<void> viderPanier() async {
    await _panierLocal.viderPanier();
    _produitIds = [];
    _quantities = {};
    notifyListeners();
  }
}