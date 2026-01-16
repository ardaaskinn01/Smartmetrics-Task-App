import '../models/product_model.dart';
import 'api_service.dart';

class ProductService {
  final ApiService _apiService;

  ProductService(this._apiService);

  Future<List<Product>> getProducts({
    String? query,
    bool? inStock,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'per_page': perPage,
      };

      if (page > 1) {
        queryParams['page'] = page;
      }

      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }

      if (inStock != null) {
        queryParams['in_stock'] = inStock ? 1 : 0;
      }

      final response = await _apiService.dio.get(
        '/api/v1/products',
        queryParameters: queryParams,
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

        final productList = list.map((json) => Product.fromJson(json)).toList();
        
        if (inStock == true) {
          return productList.where((p) => p.inStock).toList();
        }
        
        return productList;
      }
      return [];
    } catch (e) {
      throw Exception('Ürünler yüklenirken hata oluştu: $e');
    }
  }
}
