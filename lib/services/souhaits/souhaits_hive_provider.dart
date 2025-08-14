import 'package:flutter/material.dart';
import 'package:RAS/services/local/hive_storage.dart';

class SouhaitsHiveProvider with ChangeNotifier {
  final HiveStorage _hiveStorage = HiveStorage();
  
  List<String> _produitIds = [];
  bool _isInitialized = false;

  List<String> get produitIds => _produitIds;
  bool get isInitialized => _isInitialized;

  int get count => _produitIds.length;

  Future<void> init() async {
    await _hiveStorage.init();
    // Récupérer les données du stockage Hive
    _produitIds = _hiveStorage.getWishlistItems();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> ajouterAuxSouhaits(String produitId) async {
    await _hiveStorage.addToWishlist(produitId);
    _produitIds = _hiveStorage.getWishlistItems();
    notifyListeners();
  }

  Future<void> retirerDesSouhaits(String produitId) async {
    await _hiveStorage.removeFromWishlist(produitId);
    _produitIds = _hiveStorage.getWishlistItems();
    notifyListeners();
  }

  bool isProduitInSouhaits(String produitId) {
    return _produitIds.contains(produitId);
  }

  Future<void> viderSouhaits() async {
    await _hiveStorage.clearWishlist();
    _produitIds = [];
    notifyListeners();
  }
}