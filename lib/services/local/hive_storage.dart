import 'package:hive_flutter/hive_flutter.dart';

class HiveStorage {
  static const String _cartBoxName = 'cart_box';
  static const String _wishlistBoxName = 'wishlist_box';
  static const String _deliveryMethodKey = 'delivery_method';
  static const String _paymentMethodKey = 'payment_method';

  late Box<Map> _cartBox;
  late Box<String> _wishlistBox;

  Future<void> init() async {
    await Hive.initFlutter();
    // Adapters pour les types personnalisés si nécessaire
    _cartBox = await Hive.openBox<Map>(_cartBoxName);
    _wishlistBox = await Hive.openBox<String>(_wishlistBoxName);
  }

  // Méthodes pour le panier
  Map<String, int> getCartItems() {
    final Map<String, int> items = {};
    _cartBox.toMap().forEach((key, value) {
      items[key as String] = value['quantity'] as int;
    });
    return items;
  }

  Future<void> addToCart(String productId, {int quantity = 1}) async {
    await _cartBox.put(productId, {
      'quantity': quantity,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> removeFromCart(String productId) async {
    await _cartBox.delete(productId);
  }

  Future<void> updateCartQuantity(String productId, int quantity) async {
    final item = _cartBox.get(productId);
    if (item != null) {
      await _cartBox.put(productId, {
        ...item,
        'quantity': quantity,
      });
    }
  }

  Future<void> clearCart() async {
    await _cartBox.clear();
  }

  // Méthodes pour la liste de souhaits
  List<String> getWishlistItems() {
    return _wishlistBox.values.toList();
  }

  Future<void> addToWishlist(String productId) async {
    if (!_wishlistBox.values.contains(productId)) {
      await _wishlistBox.add(productId);
    }
  }

  Future<void> removeFromWishlist(String productId) async {
    final index = _wishlistBox.values.toList().indexOf(productId);
    if (index != -1) {
      await _wishlistBox.deleteAt(index);
    }
  }

  Future<void> clearWishlist() async {
    await _wishlistBox.clear();
  }

  // Méthodes pour les préférences utilisateur
  Future<void> saveDeliveryMethod(String method) async {
    await _cartBox.put(_deliveryMethodKey, {'method': method});
  }

  String? getDeliveryMethod() {
    final data = _cartBox.get(_deliveryMethodKey);
    return data?['method'] as String?;
  }

  Future<void> savePaymentMethod(String method) async {
    await _cartBox.put(_paymentMethodKey, {'method': method});
  }

  String? getPaymentMethod() {
    final data = _cartBox.get(_paymentMethodKey);
    return data?['method'] as String?;
  }

  // Méthode pour fermer les boxes
  Future<void> close() async {
    await _cartBox.close();
    await _wishlistBox.close();
  }
  
  // Nouvelle méthode pour obtenir le nombre total d'articles dans le panier
  Future<int> getTotalItems() async {
    int total = 0;
    for (var item in _cartBox.values) {
      total += item['quantity'] as int;
    }
    return total;
  }
  
  // Nouvelle méthode pour obtenir le nombre de produits uniques dans le panier
  int getUniqueItemsCount() {
    return _cartBox.length;
  }
}