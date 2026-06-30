import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../domain/entities/user.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';

// ── Datasource ────────────────────────────────────────────────────────────────
final authDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  // ref.watch: if dioClientProvider is ever invalidated a fresh datasource
  // is created pointing at the new Dio instance.
  return AuthRemoteDatasource(ref.watch(dioClientProvider).dio);
});

// ── Auth state ────────────────────────────────────────────────────────────────
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
    bool? isLoading,
    bool clearError = false,
    bool clearUser  = false,
  }) => AuthState(
    status:    status    ?? this.status,
    user:      clearUser ? null : user ?? this.user,
    error:     clearError ? null : error ?? this.error,
    isLoading: isLoading ?? this.isLoading,
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRemoteDatasource _ds;
  final SecureStorageService _storage;

  AuthNotifier(this._ds, this._storage) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }
      try {
        final user = await _ds.getMe();
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } catch (_) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      // FlutterSecureStorage can throw PlatformException on Android Keystore
      // failures (observed on some Android 8/9 devices and after factory reset).
      // Treat as unauthenticated so the router redirect fires instead of leaving
      // the app stuck in AuthStatus.unknown indefinitely.
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('[Auth:login] step 1 – POST /auth/login');
      final tokens = await _ds.login(email: email, password: password);
      debugPrint('[Auth:login] step 1 OK – access_token starts: ${tokens.accessToken.substring(0, 16)}…');

      debugPrint('[Auth:login] step 2 – saveTokens');
      await _storage.saveTokens(
          accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
      debugPrint('[Auth:login] step 2 OK');

      debugPrint('[Auth:login] step 3 – GET /auth/me');
      final user = await _ds.getMe();
      debugPrint('[Auth:login] step 3 OK – id=${user.id} role=${user.role}');

      debugPrint('[Auth:login] step 4 – saveRole');
      await _storage.saveRole(user.role);
      debugPrint('[Auth:login] step 4 OK');

      state = state.copyWith(
          status: AuthStatus.authenticated, user: user, isLoading: false);
      debugPrint('[Auth:login] state → authenticated');
      return true;
    } catch (e, st) {
      debugPrint('[Auth:login] FAILED – ${e.runtimeType}: $e');
      debugPrint('[Auth:login] stacktrace:\n$st');
      state = state.copyWith(
          error: _extractMessage(e), isLoading: false);
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? rollNumber,
    int? semester,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tokens = await _ds.register(
          email: email, password: password, fullName: fullName,
          rollNumber: rollNumber, semester: semester);
      await _storage.saveTokens(
          accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
      final user = await _ds.getMe();
      await _storage.saveRole(user.role);
      state = state.copyWith(
          status: AuthStatus.authenticated, user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: _extractMessage(e), isLoading: false);
      return false;
    }
  }

  Future<void> logout() async {
    try { await _ds.logout(); } catch (_) {}
    await _storage.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Called by the network interceptor when a token refresh fails.
  ///
  /// Unlike [logout] this method makes no network call — storage is already
  /// cleared by the interceptor before this is invoked. It is idempotent:
  /// if the logout request itself returns 401 and triggers a second call,
  /// the early return prevents any state change or further side-effects.
  void sessionExpired() {
    if (state.status == AuthStatus.unauthenticated) return;
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() => state = state.copyWith(clearError: true);

  String _extractMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final detail = data['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
      }
    }
    return 'Something went wrong. Please try again.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(
    ref.read(authDatasourceProvider),
    ref.read(secureStorageProvider),
  );
  // Wire session-expiry bridge: DioClient cannot import authProvider (circular
  // import), so we set the callback here. auth_provider.dart already imports
  // dio_client.dart. The callback is only ever invoked during a live network
  // request, so authProvider is guaranteed to exist by then.
  ref.read(dioClientProvider).onSessionExpired = notifier.sessionExpired;
  return notifier;
});

// Convenience selector
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});
