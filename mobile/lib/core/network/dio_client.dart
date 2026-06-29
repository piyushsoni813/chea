import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.read(secureStorageProvider);
  return DioClient(storage);
});

class DioClient {
  late final Dio _dio;
  final SecureStorageService _storage;
  bool _isRefreshing = false;

  DioClient(this._storage) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    _dio.interceptors.add(_AuthInterceptor(_storage, _dio, _getRefreshing, _setRefreshing));
  }

  bool _getRefreshing() => _isRefreshing;
  void _setRefreshing(bool v) => _isRefreshing = v;

  Dio get dio => _dio;
}

class _AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final Dio _dio;
  final bool Function() _isRefreshing;
  final void Function(bool) _setRefreshing;
  final List<RequestOptions> _pending = [];

  _AuthInterceptor(this._storage, this._dio, this._isRefreshing, this._setRefreshing);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing()) {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        handler.next(err);
        return;
      }
      _setRefreshing(true);
      try {
        final resp = await _dio.post('/auth/refresh',
            data: {'refresh_token': refreshToken});
        final newAccess  = resp.data['access_token']  as String;
        final newRefresh = resp.data['refresh_token'] as String;
        await _storage.saveTokens(
            accessToken: newAccess, refreshToken: newRefresh);

        // Replay the failed request with the new token.
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccess';
        final retried = await _dio.request(opts.path,
            options: Options(method: opts.method, headers: opts.headers),
            data: opts.data,
            queryParameters: opts.queryParameters);
        handler.resolve(retried);
      } catch (_) {
        await _storage.clearAll();
        handler.next(err);
      } finally {
        _setRefreshing(false);
      }
    } else {
      handler.next(err);
    }
  }
}
