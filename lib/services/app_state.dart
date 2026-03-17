import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AppState extends ChangeNotifier {
  final ApiService _api = ApiService();
  ApiService get api => _api;

  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> checkAdminStatus() async {
    _isAdmin = await _api.isLoggedIn;
    notifyListeners();
  }

  Future<AuthResult> loginWithPassword(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    final result = await _api.loginWithPassword(username, password);
    if (result.success) _isAdmin = true;
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<AuthResult> loginWithQR(String qrCode) async {
    final result = await _api.loginWithQR(qrCode);
    if (result.success) _isAdmin = true;
    notifyListeners();
    return result;
  }

  Future<void> logout() async {
    await _api.clearToken();
    _isAdmin = false;
    notifyListeners();
  }
}
