import 'api_service.dart';
import 'auth_service.dart';
import 'product_service.dart';
import 'history_service.dart';
import 'qr_service.dart';

class ServiceLocator {
  ServiceLocator._();
  

  static final ApiService _apiService = ApiService();

  static ApiService get apiService => _apiService;
  static AuthService get authService => AuthService(_apiService);
  static ProductService get productService => ProductService(_apiService);
  static HistoryService get historyService => HistoryService(_apiService);
  static QrService get qrService => QrService(_apiService);
}
