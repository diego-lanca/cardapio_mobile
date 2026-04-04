import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.total);

  double get deliveryFee => _items.isEmpty ? 0 : 6.0;

  double get total => subtotal + deliveryFee;

  bool get isEmpty => _items.isEmpty;

  void addItem(MenuItem product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity + 1,
      );
    } else {
      _items.add(
        CartItem(product: product, quantity: 1),
      );
    }

    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void incrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);

    if (index == -1) return;

    _items[index] = _items[index].copyWith(
      quantity: _items[index].quantity + 1,
    );

    notifyListeners();
  }

  void decrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);

    if (index == -1) return;

    final currentItem = _items[index];

    if (currentItem.quantity <= 1) {
      _items.removeAt(index);
    } else {
      _items[index] = currentItem.copyWith(
        quantity: currentItem.quantity - 1,
      );
    }

    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}