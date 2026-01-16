import 'package:dio/dio.dart';
import 'api_service.dart';

class QrService {
  final ApiService _apiService;

  QrService(this._apiService);

  Future<Map<String, dynamic>> verifyQr(String code) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/qr/verify',
        data: {'code': code},
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'statusCode': e.response?.statusCode,
          'message': e.response?.data['message'] ?? 'Bir hata oluştu',
          'data': e.response?.data,
        };
      }
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Beklenmedik bir hata: $e',
      };
    }
  }
}
