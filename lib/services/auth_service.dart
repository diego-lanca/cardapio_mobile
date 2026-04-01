import 'dart:convert';

import 'package:cardapio_mobile/services/local_storage_service.dart';
import 'package:dio/dio.dart';

import '../models/login_response_model.dart';
import '../models/user_model.dart';

class AuthService {
  final String baseUrl;
  final LocalStorageService storageService;

  final dio = Dio(BaseOptions(baseUrl: ''));

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  AuthService({required this.baseUrl, required this.storageService});

  Future<void> init() async {
    final token = await storageService.getAuthToken();
    if (token != null) {
      await loadUser();
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final response = await dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );

    if (response.statusCode != null) {
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        final data = jsonDecode(response.data);
        final loginResponse = LoginResponseModel.fromJson(data);

        await storageService.setAuthToken(loginResponse.accessToken);
        await loadUser();
        return;
      }
    }

    throw Exception('Erro ao fazer login');
  }

  Future<void> register({
    required String email,
    required String username,
    required String fullName,
    required String password,
    bool isAdmin = false,
  }) async {
    final response = await dio.post(
      '/auth/register',
      data: {
        'email': email,
        'username': username,
        'full_name': fullName,
        'password': password,
        'is_admin': isAdmin,
      },
    );

    if (response.statusCode != null) {
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        await login(username: username, password: password);
        return;
      }
    }

    throw Exception('Erro ao cadastrar usuário');
  }

  Future<void> loadUser() async {
    final token = await storageService.getAuthToken();

    if (token == null) {
      _currentUser = null;
      return;
    }

    final response = await dio.get(
      '/auth/me',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.statusCode != null) {
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        _currentUser = UserModel.fromJson(response.data);
        return;
      }
    }

    if (response.statusCode == 401) {
      await logout();
      return;
    }

    throw Exception('Erro ao carregar usuário');
  }

  Future<bool> validateToken() async {
    final token = await storageService.getAuthToken();

    if (token == null) {
      return false;
    }

    final response = await dio.get(
      '/auth/verify-token',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.statusCode != null) {
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
      final data = response.data;

      if (data['is_active'] == true) {
        return true;
      }

      await logout();
      return false;
    }
    }
    

    await logout();
    return false;
  }

  Future<void> logout() async {
    await storageService.clearAll();
    _currentUser = null;
  }
}
