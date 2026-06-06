import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {
  final ApiService _api;

  OrderProvider(this._api);

  List<OrderResponse> _orders = [];
  bool _isLoading = false;
  bool _isPlacing = false;
  String? _error;

  List<OrderResponse> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  bool get isPlacing => _isPlacing;
  String? get error => _error;

  Future<OrderResponse> placeOrder({
    required int userId,
    required List<CartItem> items,
  }) async {
    _isPlacing = true;
    notifyListeners();
    try {
      final res = await _api.dio.post(
        '/orders/',
        data: {
          'user_id': userId,
          'items': items
              .map((ci) => {'item_id': ci.product.id, 'quantity': ci.quantity})
              .toList(),
        },
      );
      final order = OrderResponse.fromJson(res.data as Map<String, dynamic>);
      _orders.insert(0, order);
      notifyListeners();
      return order;
    } on DioException catch (e) {
      throw Exception(_api.errorMessage(e));
    } finally {
      _isPlacing = false;
      notifyListeners();
    }
  }

  Future<void> loadOrders({int? userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.dio.get(
        '/orders/',
        queryParameters: {'user_id': ?userId, 'limit': 100},
      );
      _orders = (res.data as List)
          .map((j) => OrderResponse.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _error = _api.errorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    try {
      final res = await _api.dio.patch(
        '/orders/$orderId',
        data: {'status': status},
      );
      final updated = OrderResponse.fromJson(res.data as Map<String, dynamic>);
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index >= 0) {
        _orders[index] = updated;
        notifyListeners();
      }
    } on DioException catch (e) {
      throw Exception(_api.errorMessage(e));
    }
  }
}
