import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui/core/service/api_const.dart';
import 'dart:developer' as developer;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  String? _token;

  // Base URL - update this to your actual API base URL
  static const String baseUrl = ApiConst.baseUrl;

  // SharedPreferences keys
  static const String _tokenKey = 'auth_token';

  // ANSI color codes for console
  static const String _green = '\x1B[32m';
  static const String _red = '\x1B[31m';
  static const String _blue = '\x1B[34m';
  static const String _cyan = '\x1B[36m';
  static const String _reset = '\x1B[0m';
  static const String _bold = '\x1B[1m';

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptor for token management and logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add token to every request if available
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          _logRequest(options);
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Handle successful response
          _logResponse(response);
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          // Log error
          _logError(error);

          // Handle 401 Unauthorized - token expired (but not for refresh endpoint itself)
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('refresh')) {
            // Try to refresh token
            try {
              // Get refresh token from SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              final refreshToken = prefs.getString('refresh_token');

              if (refreshToken != null) {
                // Call refresh endpoint
                final refreshResponse = await _dio.post(
                  ApiConst.refresh,
                  data: {'refreshToken': refreshToken},
                  options: Options(
                    headers: {
                      'Content-Type': 'application/json',
                      'Accept': 'application/json',
                    },
                  ),
                );

                // Extract new access token
                final newAccessToken = refreshResponse.data['accessToken'];
                final newRefreshToken = refreshResponse.data['refreshToken'];
                final expiresIn = refreshResponse.data['expiresIn'];

                // Save new tokens
                await saveToken(newAccessToken);
                await prefs.setString('refresh_token', newRefreshToken);
                await prefs.setString(
                  'expiry_time',
                  DateTime.now()
                      .add(Duration(seconds: expiresIn))
                      .toIso8601String(),
                );

                // Retry the original request with new token
                error.requestOptions.headers['Authorization'] =
                    'Bearer $newAccessToken';
                final clonedRequest = await _dio.fetch(error.requestOptions);

                return handler.resolve(clonedRequest);
              } else {
                // No refresh token, clear and force re-login
                await clearToken();
              }
            } catch (refreshError) {
              // Refresh failed, clear token and force re-login
              await clearToken();
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  // Log API Request
  void _logRequest(RequestOptions options) {
    final uri = options.uri.toString();
    final method = options.method;

    developer.log(
      '\n'
      '╔═══════════════════════════════════════════════════════════════\n'
      '║ $_blue${_bold}API REQUEST$_reset\n'
      '╠═══════════════════════════════════════════════════════════════\n'
      '║ $_cyan${_bold}Method:$_reset $method\n'
      '║ $_cyan${_bold}URL:$_reset $uri\n'
      '║ $_cyan${_bold}Headers:$_reset ${options.headers}\n'
      '${options.data != null ? '║ $_cyan${_bold}Body:$_reset ${options.data}\n' : ''}'
      '╚═══════════════════════════════════════════════════════════════',
      name: 'API Request',
    );
  }

  // Log API Response (Success)
  void _logResponse(Response response) {
    final statusCode = response.statusCode;
    final uri = response.requestOptions.uri.toString();
    final method = response.requestOptions.method;

    developer.log(
      '\n'
      '╔═══════════════════════════════════════════════════════════════\n'
      '║ $_green${_bold}✓ API SUCCESS$_reset\n'
      '╠═══════════════════════════════════════════════════════════════\n'
      '║ $_cyan${_bold}Method:$_reset $method\n'
      '║ $_cyan${_bold}URL:$_reset $uri\n'
      '║ $_green${_bold}Status:$_reset $statusCode\n'
      '║ $_cyan${_bold}Response:$_reset ${response.data}\n'
      '╚═══════════════════════════════════════════════════════════════',
      name: 'API Success',
    );
  }

  // Log API Error (Failure)
  void _logError(DioException error) {
    final statusCode = error.response?.statusCode ?? 'Unknown';
    final uri = error.requestOptions.uri.toString();
    final method = error.requestOptions.method;
    final errorMessage = error.message ?? 'Unknown error';
    final responseData = error.response?.data ?? 'No response data';

    developer.log(
      '\n'
      '╔═══════════════════════════════════════════════════════════════\n'
      '║ $_red${_bold}✗ API ERROR$_reset\n'
      '╠═══════════════════════════════════════════════════════════════\n'
      '║ $_cyan${_bold}Method:$_reset $method\n'
      '║ $_cyan${_bold}URL:$_reset $uri\n'
      '║ $_red${_bold}Status:$_reset $statusCode\n'
      '║ $_red${_bold}Error Type:$_reset ${error.type}\n'
      '║ $_red${_bold}Message:$_reset $errorMessage\n'
      '║ $_red${_bold}Response:$_reset $responseData\n'
      '╚═══════════════════════════════════════════════════════════════',
      name: 'API Error',
    );
  }

  // Initialize token from SharedPreferences on app start
  Future<void> init() async {
    await loadToken();
  }

  // Load token from SharedPreferences
  Future<void> loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      if (_token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $_token';
      }
    } catch (e) {
      print('Error loading token: $e');
    }
  }

  // Save token to SharedPreferences
  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      _token = token;
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } catch (e) {
      print('Error saving token: $e');
      rethrow;
    }
  }

  // Clear token from SharedPreferences
  Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      _token = null;
      _dio.options.headers.remove('Authorization');
    } catch (e) {
      print('Error clearing token: $e');
    }
  }

  // Get current token
  String? get token => _token;

  // Check if user is authenticated
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Handle Dio errors
  Exception _handleError(DioException error) {
    String errorMessage;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage =
            'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        errorMessage = _handleStatusCode(error.response?.statusCode);
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Request cancelled';
        break;
      case DioExceptionType.unknown:
        if (error.message != null &&
            error.message!.contains('SocketException')) {
          errorMessage = 'No internet connection';
        } else {
          errorMessage = 'Unexpected error occurred';
        }
        break;
      default:
        errorMessage = 'Something went wrong';
    }

    return ApiException(errorMessage, error.response?.statusCode);
  }

  // Handle HTTP status codes
  String _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not found';
      case 500:
        return 'Internal server error';
      case 503:
        return 'Service unavailable';
      default:
        return 'Error occurred: $statusCode';
    }
  }

  // Upload file with progress
  Future<Response> uploadFile(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? data,
    ProgressCallback? onProgress,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        if (data != null) ...data,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onProgress,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Download file with progress
  Future<Response> downloadFile(
    String path,
    String savePath, {
    ProgressCallback? onProgress,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.download(
        path,
        savePath,
        onReceiveProgress: onProgress,
        queryParameters: queryParameters,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}

// Custom exception class
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}
