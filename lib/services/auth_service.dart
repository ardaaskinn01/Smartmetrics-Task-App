import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;

  AuthService(this._apiService);

  Future<void> login(String identifier, String password) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/auth/login',
        data: {
          'identifier': identifier,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];
        if (token != null) {
          await _apiService.setToken(token);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _apiService.dio.post(
        '/api/v1/auth/register',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> updateProfile({
    required String name,
    required String email,
    required String? phone,
  }) async {
    try {
      final response = await _apiService.dio.put(
        '/api/v1/profile',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
        },
      );

      if (response.statusCode == 200) {
        final body = response.data;
        if (body != null && body is Map<String, dynamic>) {
          final userData = body.containsKey('user') ? body['user'] : body;
          if (userData is Map<String, dynamic>) {
            return User.fromJson(userData);
          }
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      final response = await _apiService.dio.put(
        '/api/v1/profile/password',
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPasswordConfirmation,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final newToken = response.data['token'];
        if (newToken != null) {
          await _apiService.setToken(newToken);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> getMe() async {
    try {
      final response = await _apiService.dio.get('/api/v1/me');
      
      if (response.statusCode == 200) {
        final body = response.data;
        if (body != null && body is Map<String, dynamic>) {
          final userData = body.containsKey('user') ? body['user'] : body;
          if (userData is Map<String, dynamic>) {
            return User.fromJson(userData);
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.dio.post('/api/v1/auth/logout');
    } catch (e) {
    } finally {
      await _apiService.clearToken();
    }
  }

  Future<void> deactivateAccount(String password) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/auth/deactivate',
        data: {'password': password},
      );
      
      if (response.statusCode == 200) {
        await _apiService.clearToken();
      }
    } catch (e) {
      rethrow;
    }
  }
}
