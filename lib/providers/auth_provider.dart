import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

class AuthProvider with ChangeNotifier {
  final LocalStorageService storageService;
  final ApiService _api;

  AuthProvider({required this.storageService, required ApiService apiService})
    : _api = apiService;

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final res = await _api.dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      final token = res.data['access_token'] as String;
      await storageService.setAuthToken(token);

      final meRes = await _api.dio.get('/auth/me');
      _currentUser = UserModel.fromJson(meRes.data as Map<String, dynamic>);
      notifyListeners();
    } on DioException catch (e) {
      throw Exception(_api.errorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required String email,
    required String username,
    required String fullName,
    required String password,
    bool isAdmin = false,
  }) async {
    _setLoading(true);
    try {
      await _api.dio.post(
        '/auth/register',
        data: {
          'email': email,
          'username': username,
          'full_name': fullName,
          'password': password,
          'is_admin': isAdmin,
        },
      );

      final res = await _api.dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      final token = res.data['access_token'] as String;
      await storageService.setAuthToken(token);

      final meRes = await _api.dio.get('/auth/me');
      _currentUser = UserModel.fromJson(meRes.data as Map<String, dynamic>);
      notifyListeners();
    } on DioException catch (e) {
      throw Exception(_api.errorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUser() async {
    _setLoading(true);
    try {
      final token = await storageService.getAuthToken();
      if (token == null) {
        _currentUser = null;
        notifyListeners();
        return;
      }
      final res = await _api.dio.get('/auth/me');
      _currentUser = UserModel.fromJson(res.data as Map<String, dynamic>);
      notifyListeners();
    } on DioException {
      await storageService.setAuthToken(null);
      _currentUser = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> validateToken() async {
    try {
      final token = await storageService.getAuthToken();
      if (token == null) return false;
      await _api.dio.post('/auth/verify-token');
      return true;
    } on DioException {
      await storageService.setAuthToken(null);
      return false;
    }
  }

  Future<void> logout() async {
    await storageService.clearAll();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> forgotPassword({required String email}) async {
    _setLoading(true);
    try {
      if (email.isEmpty || !email.contains('@')) {
        throw Exception('E-mail inválido');
      }
      // TODO: integrar quando endpoint estiver disponível na API
      await Future.delayed(const Duration(seconds: 1));
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
