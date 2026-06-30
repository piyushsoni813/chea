import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  // ref.watch so that if secureStorageProvider is ever invalidated this
  // provider rebuilds and a fresh DioClient is created with the new storage.
  return DioClient(ref.watch(secureStorageProvider));
});

class DioClient {
  late final Dio _dio;
  final SecureStorageService _storage;
  bool _isRefreshing = false;

  /// Set by the auth layer after provider construction.
  ///
  /// Avoids a circular provider dependency: auth_provider.dart already imports
  /// dio_client.dart, so we cannot import auth_provider.dart here. Instead the
  /// auth provider sets this callback on the already-created DioClient instance.
  ///
  /// Called when token refresh fails and the session must be invalidated.
  /// Storage is already cleared by the interceptor before this fires.
  void Function()? onSessionExpired;

  DioClient(this._storage) {
    _dio = Dio(BaseOptions(
      baseUrl:        AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {
        'Content-Type': 'application/json',
        'Accept':        'application/json',
      },
    ));
    _dio.interceptors.add(
      _AuthInterceptor(
        _storage,
        _dio,
        _getRefreshing,
        _setRefreshing,
        () => onSessionExpired?.call(),
      ),
    );
  }

  bool _getRefreshing() => _isRefreshing;
  void _setRefreshing(bool v) => _isRefreshing = v;

  Dio get dio => _dio;
}

// ── Interceptor ───────────────────────────────────────────────────────────────
class _AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final Dio _dio;
  final bool Function() _isRefreshing;
  final void Function(bool) _setRefreshing;
  final void Function() _notifyExpired;

  /// Completers for requests that arrive while a refresh is already in flight.
  /// On refresh success each Completer receives the new access token so those
  /// requests can retry themselves. On refresh failure they receive an error.
  final List<Completer<String>> _tokenQueue = [];

  _AuthInterceptor(
    this._storage,
    this._dio,
    this._isRefreshing,
    this._setRefreshing,
    this._notifyExpired,
  );

  // ── onRequest ───────────────────────────────────────────────────────────────
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // The token-refresh POST must not carry an Authorization header —
    // doing so with an expired token could cause the refresh endpoint to
    // return 401 itself, triggering an infinite loop.
    if (options.extra['skipAuth'] == true) {
      handler.next(options);
      return;
    }
    try {
      final token = await _storage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e, st) {
      // flutter_secure_storage on web throws DOMException(OperationError) when
      // the Web Crypto key in localStorage is absent or corrupted. This is the
      // original exception Dio would otherwise silently wrap as
      // DioException [unknown]. Log it, then continue without an auth header —
      // the server will return 401 and the error interceptor handles the rest.
      debugPrint('[DioClient:onRequest] storage read failed — '
          '${e.runtimeType}: $e\n$st');
    }
    handler.next(options);
  }

  // ── onError ─────────────────────────────────────────────────────────────────
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // A refresh is already in flight — queue this request.
    // We await the Completer; once the first refresh resolves it, we retry.
    if (_isRefreshing()) {
      final completer = Completer<String>();
      _tokenQueue.add(completer);
      try {
        final newToken = await completer.future;
        final response = await _retry(err.requestOptions, newToken);
        handler.resolve(response);
      } catch (_) {
        handler.next(err);
      }
      return;
    }

    // No refresh token in storage → session is truly expired, nothing to do.
    // Storage read is wrapped because flutter_secure_storage on web can throw
    // DOMException(OperationError); treat that the same as "no token found".
    final String? refreshToken;
    try {
      refreshToken = await _storage.getRefreshToken();
    } catch (e) {
      debugPrint('[DioClient:onError] storage read failed — ${e.runtimeType}: $e');
      _notifyExpired();
      handler.next(err);
      return;
    }
    if (refreshToken == null) {
      _notifyExpired();
      handler.next(err);
      return;
    }

    // ── Start token refresh ──────────────────────────────────────────────────
    _setRefreshing(true);
    try {
      final resp = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        // skipAuth prevents onRequest from adding the expired token to this
        // call, which would likely make the refresh endpoint reject it.
        options: Options(extra: {'skipAuth': true}),
      );

      final newAccess  = resp.data['access_token']  as String?;
      final newRefresh = resp.data['refresh_token'] as String?;
      if (newAccess == null || newRefresh == null) {
        throw Exception('Malformed token-refresh response');
      }

      await _storage.saveTokens(
        accessToken:  newAccess,
        refreshToken: newRefresh,
      );

      // Unblock all queued requests with the new token.
      for (final c in _tokenQueue) {
        c.complete(newAccess);
      }
      _tokenQueue.clear();

      // Retry the original (triggering) request.
      final retried = await _retry(err.requestOptions, newAccess);
      handler.resolve(retried);
    } catch (_) {
      // Refresh failed — reject every queued request and invalidate session.
      for (final c in _tokenQueue) {
        c.completeError(Exception('Token refresh failed'));
      }
      _tokenQueue.clear();
      await _storage.clearAll();
      _notifyExpired(); // tells authProvider → router redirects to /login
      handler.next(err);
    } finally {
      _setRefreshing(false);
    }
  }

  // ── Retry helper ─────────────────────────────────────────────────────────────
  /// Retries [opts] with [newToken], preserving all original request settings.
  /// Using _dio.fetch preserves responseType, extra, timeouts, validateStatus,
  /// etc. — unlike manually reconstructing Options from scratch.
  Future<Response<dynamic>> _retry(RequestOptions opts, String newToken) {
    return _dio.fetch<dynamic>(
      opts.copyWith(
        headers: {
          ...opts.headers,
          'Authorization': 'Bearer $newToken',
        },
      ),
    );
  }
}
