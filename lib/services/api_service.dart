import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String _baseUrlKey = 'base_url';
  static const String _tokenKey = 'admin_token';
  static const String _defaultBaseUrl = 'https://millesime.logistiscout.fr';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late Dio _dio;

  ApiService() {
    _dio = Dio();
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Future<String> get baseUrl async {
    return await _storage.read(key: _baseUrlKey) ?? _defaultBaseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    await _storage.write(key: _baseUrlKey, value: url.trimRight().replaceAll(RegExp(r'/$'), ''));
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> get isLoggedIn async {
    final token = await getToken();
    return token != null;
  }

  // ─── SCAN ─────────────────────────────────────────────────────────────────

  Future<ScanResult> scanTicket(String qrCode) async {
    try {
      final url = '${await baseUrl}/scan';
      final response = await _dio.post(url, data: {'qr_code': qrCode});
      return ScanResult.fromJson(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return ScanResult(
          success: false,
          message: 'Impossible de joindre le serveur. Vérifiez la connexion.',
          status: 'connection_error',
        );
      }
      return ScanResult(
        success: false,
        message: 'Erreur réseau : ${e.message}',
        status: 'error',
      );
    } catch (e) {
      return ScanResult(
        success: false,
        message: 'Erreur inattendue : $e',
        status: 'error',
      );
    }
  }

  // ─── AUTH ─────────────────────────────────────────────────────────────────

  Future<AuthResult> loginWithPassword(String username, String password) async {
    try {
      final url = '${await baseUrl}/admin/login';
      final response = await _dio.post(
        url,
        data: FormData.fromMap({'username': username, 'password': password}),
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );
      final data = response.data;
      final token = data is Map ? data['access_token'] : null;
      if (token == null) return AuthResult(success: false, message: 'Réponse invalide du serveur');
      await saveToken(token.toString());
      return AuthResult(success: true, message: 'Connexion réussie');
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map ? data['detail'] : data?.toString()) ?? 'Identifiants incorrects';
      return AuthResult(success: false, message: msg.toString());
    } catch (e) {
      return AuthResult(success: false, message: 'Erreur : $e');
    }
  }

  Future<AuthResult> loginWithQR(String qrCode) async {
    try {
      final url = '${await baseUrl}/admin/login-qr';
      final response = await _dio.post(url, data: {'qr_code': qrCode});
      final data = response.data;
      final token = data is Map ? data['access_token'] : null;
      if (token == null) return AuthResult(success: false, message: 'Réponse invalide du serveur');
      await saveToken(token.toString());
      return AuthResult(success: true, message: 'Connexion admin réussie');
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map ? data['detail'] : data?.toString()) ?? 'QR code invalide';
      return AuthResult(success: false, message: msg.toString());
    } catch (e) {
      return AuthResult(success: false, message: 'Erreur : $e');
    }
  }

  // ─── ÉVÉNEMENTS ───────────────────────────────────────────────────────────

  Future<List<EventModel>> getEvents() async {
    final url = '${await baseUrl}/admin/events';
    final response = await _dio.get(url);
    return (response.data as List).map((e) => EventModel.fromJson(e)).toList();
  }

  Future<EventModel> createEvent(Map<String, dynamic> data) async {
    final url = '${await baseUrl}/admin/events';
    final response = await _dio.post(url, data: data);
    return EventModel.fromJson(response.data);
  }

  Future<void> deleteEvent(int eventId) async {
    final url = '${await baseUrl}/admin/events/$eventId';
    await _dio.delete(url);
  }

  Future<Map<String, dynamic>> importCSV(int eventId, File file) async {
    final url = '${await baseUrl}/admin/events/$eventId/import-csv';
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
    });
    final response = await _dio.post(url, data: formData);
    return response.data;
  }

  Future<Map<String, dynamic>> getStats(int eventId) async {
    final url = '${await baseUrl}/admin/events/$eventId/stats';
    final response = await _dio.get(url);
    return response.data;
  }

  // ─── GESTION BILLETS ──────────────────────────────────────────────────────

  Future<List<dynamic>> getTickets(int eventId, {String search = ''}) async {
    final url = '${await baseUrl}/admin/events/$eventId/tickets';
    final response = await _dio.get(url, queryParameters: search.isNotEmpty ? {'search': search} : null);
    return response.data as List;
  }

  Future<Map<String, dynamic>> adjustDrinks(int ticketId, int delta) async {
    final url = '${await baseUrl}/admin/tickets/$ticketId/adjust-drinks';
    final response = await _dio.patch(url, data: {'delta': delta});
    return response.data;
  }

  Future<Map<String, dynamic>> createManualTicket(int eventId, Map<String, dynamic> data) async {
    final url = '${await baseUrl}/admin/events/$eventId/tickets';
    final response = await _dio.post(url, data: data);
    return response.data;
  }

  Future<String> getQrPngUrl(int ticketId) async {
    final token = await getToken();
    final base = await baseUrl;
    return '$base/admin/tickets/$ticketId/qr-png?token=$token';
  }

  Future<Uint8List> downloadQrPng(int ticketId) async {
    final url = await getQrPngUrl(ticketId);
    final response = await _dio.get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data);
  }
}

// ─── MODELS ───────────────────────────────────────────────────────────────

class ScanResult {
  final bool success;
  final String message;
  final String status;
  final int? drinksRemaining;
  final int? drinksTotal;
  final String? holderName;
  final String? eventName;

  ScanResult({
    required this.success,
    required this.message,
    required this.status,
    this.drinksRemaining,
    this.drinksTotal,
    this.holderName,
    this.eventName,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      status: json['status'] ?? 'error',
      drinksRemaining: json['drinks_remaining'],
      drinksTotal: json['drinks_total'],
      holderName: json['holder_name'],
      eventName: json['event_name'],
    );
  }
}

class AuthResult {
  final bool success;
  final String message;
  AuthResult({required this.success, required this.message});
}

class EventModel {
  final int id;
  final String name;
  final String dateStart;
  final String dateEnd;
  final int drinksPerTicket;
  final String? description;

  EventModel({
    required this.id,
    required this.name,
    required this.dateStart,
    required this.dateEnd,
    required this.drinksPerTicket,
    this.description,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      name: json['name'],
      dateStart: json['date_start'],
      dateEnd: json['date_end'],
      drinksPerTicket: json['drinks_per_ticket'],
      description: json['description'],
    );
  }
}