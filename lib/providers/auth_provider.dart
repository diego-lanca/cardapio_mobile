import 'package:flutter/material.dart';
import 'package:cardapio_mobile/services/local_storage_service.dart';

import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final LocalStorageService storageService;

  AuthProvider({
    required this.storageService,
  });

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  // Future<void> init() async {
  //   _setLoading(true);

  //   try {
  //     final token = await storageService.getAuthToken();

  //     if (token != null) {
  //       await Future.delayed(const Duration(milliseconds: 800));

  //       _currentUser = UserModel(
  //         id: 1,
  //         email: 'diego@email.com',
  //         username: 'diego',
  //         fullName: 'Diego Lança',
  //         isAdmin: false,
  //       );
  //     }
  //   } finally {
  //     _setLoading(false);
  //   }
  // }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    _setLoading(true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      if (username.isEmpty || password.isEmpty) {
        throw Exception('Usuário e senha são obrigatórios');
      }

      if (password.length < 4) {
        throw Exception('Senha inválida');
      }

      await storageService.setAuthToken('mock_token_123');

      _currentUser = UserModel(
        id: 1,
        email: '$username@email.com',
        username: username,
        fullName: 'Usuário Mock',
        isAdmin: false,
      );

      notifyListeners();
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
      await Future.delayed(const Duration(seconds: 1));

      if (email.isEmpty ||
          username.isEmpty ||
          fullName.isEmpty ||
          password.isEmpty) {
        throw Exception('Preencha todos os campos');
      }

      if (!email.contains('@')) {
        throw Exception('E-mail inválido');
      }

      if (password.length < 6) {
        throw Exception('A senha deve ter pelo menos 6 caracteres');
      }

      await storageService.setAuthToken('mock_token_123');

      _currentUser = UserModel(
        id: 1,
        email: email,
        username: username,
        fullName: fullName,
        isAdmin: isAdmin,
      );

      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUser() async {
    _setLoading(true);

    try {
      final token = await storageService.getAuthToken();

      await Future.delayed(const Duration(milliseconds: 500));

      if (token == null) {
        _currentUser = null;
      } else {
        _currentUser = UserModel(
          id: 1,
          email: 'mock@email.com',
          username: 'mockuser',
          fullName: 'Usuário Mock',
          isAdmin: false,
        );
      }

      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> validateToken() async {
    final token = await storageService.getAuthToken();

    await Future.delayed(const Duration(milliseconds: 400));

    if (token == null) {
      return false;
    }

    return true;
  }

  Future<void> logout() async {
    await storageService.clearAll();
    _currentUser = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}