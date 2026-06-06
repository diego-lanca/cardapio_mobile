import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/menu_item.dart';
import '../services/api_service.dart';

class MenuProvider with ChangeNotifier {
  final ApiService _api;

  MenuProvider(this._api);

  List<MenuItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<MenuItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<MenuItem> createItem({
    required String name,
    required String category,
    required double price,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final res = await _api.dio.post(
        '/items/',
        data: {
          'name': name,
          'category': category,
          'price': price,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
        },
      );
      final item = MenuItem.fromJson(res.data as Map<String, dynamic>);
      _items.add(item);
      notifyListeners();
      return item;
    } on DioException catch (e) {
      throw Exception(_api.errorMessage(e));
    }
  }

  Future<MenuItem> updateItem(
    int id, {
    required String name,
    required String category,
    required double price,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final res = await _api.dio.patch(
        '/items/$id',
        data: {
          'name': name,
          'category': category,
          'price': price,
          'description': description ?? '',
          'image_url': ?imageUrl,
        },
      );
      final item = MenuItem.fromJson(res.data as Map<String, dynamic>);
      final idx = _items.indexWhere((i) => i.id == id);
      if (idx >= 0) {
        _items[idx] = item;
        notifyListeners();
      }
      return item;
    } on DioException catch (e) {
      throw Exception(_api.errorMessage(e));
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      await _api.dio.delete('/items/$id');
      _items.removeWhere((i) => i.id == id);
      notifyListeners();
    } on DioException catch (e) {
      throw Exception(_api.errorMessage(e));
    }
  }

  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.dio.get('/items/');
      _items = (res.data as List)
          .map((json) => MenuItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _error = _api.errorMessage(e);
    } catch (_) {
      _error = 'Erro ao carregar o cardápio';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
