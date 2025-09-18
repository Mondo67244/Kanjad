import 'dart:collection';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/produit.dart';
import 'package:kanjad/services/BD/supabase.dart';

class ProductProvider with ChangeNotifier {
  final SupabaseService _databaseService = SupabaseService.instance;

  List<Produit> _products = [];
  bool _isLoading = false;
  bool _isLoaded = false;
  dynamic _error;

  // Use an UnmodifiableListView to prevent direct modification of the list from outside.
  UnmodifiableListView<Produit> get products => UnmodifiableListView(_products);
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  dynamic get error => _error;

  Future<void> loadProducts({bool forceRefresh = false}) async {
    // Avoid multiple simultaneous loads
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _databaseService.getProduits(
        forceRefresh: forceRefresh,
      );
      _isLoaded = true;
      _error = null;
    } on SocketException catch (e) {
      // En cas d'erreur réseau, tenter d'utiliser les données en cache
      print('Erreur réseau lors du chargement des produits: $e');
      _error = e;
      // On considère quand même que le chargement est terminé même s'il y a une erreur
      _isLoaded = true;
    } catch (e) {
      _error = e;
      // On considère quand même que le chargement est terminé même s'il y a une erreur
      _isLoaded = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
