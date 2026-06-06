import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'local_storage_service.dart';

class ApiService {
  late final Dio dio;
  final LocalStorageService _storage;

  ApiService(this._storage) {
    dio = Dio(
      BaseOptions(
        baseUrl:
            dotenv.env['API_BASE_URL'] ??
            'https://cardapio-backend-4895.onrender.com',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  String errorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data.containsKey('detail')) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        return (detail.first as Map)['msg']?.toString() ?? 'Erro desconhecido';
      }
    }
    return switch (e.response?.statusCode) {
      400 => 'Dados inválidos',
      401 => 'Credenciais inválidas',
      404 => 'Não encontrado',
      422 => 'Dados inválidos',
      500 => 'Erro no servidor',
      _ => 'Erro de conexão',
    };
  }
}
