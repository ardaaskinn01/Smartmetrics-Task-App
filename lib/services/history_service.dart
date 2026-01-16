import 'package:dio/dio.dart';
import '../models/history_model.dart';
import 'api_service.dart';

class HistoryService {
  final ApiService _apiService;

  HistoryService(this._apiService);

  Future<List<History>> getHistory({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/api/v1/history',
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );
      
      if (response.statusCode == 200) {
        final dynamic body = response.data;
        
        List<dynamic> list;
        if (body is Map && body.containsKey('data')) {
          list = body['data'];
        } else if (body is List) {
          list = body;
        } else {
          return [];
        }

        return list.map((json) => History.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Geçmiş yüklenirken hata oluştu: $e');
    }
  }
}
