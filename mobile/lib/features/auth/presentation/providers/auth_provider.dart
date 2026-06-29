import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/auth_models.dart';
import '../../domain/entities/user.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';

// ── Datasource ────────────────────────────────────────────────────────────────
final authDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(ref.read(dioClientProvider).dio);
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
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tokens = await _ds.login(email: email, password: password);
      await _storage.saveTokens(
          accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
      final user = await _ds.getMe();
      await _storage.saveRole(user.role);
      state = state.copyWith(
          status: AuthStatus.authenticated, user: user, isLoading: false);
      return true;
    } catch (e) {
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

  void clearError() => state = state.copyWith(clearError: true);

  String _extractMessage(Object e) {
    final str = e.toString();
    if (str.contains('detail')) {
      final match = RegExp(r'"detail"\s*:\s*"([^"]+)"').firstMatch(str);
      if (match != null) return match.group(1)!;
    }
    return 'Something went wrong. Please try again.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authDatasourceProvider),
    ref.read(secureStorageProvider),
  );
});

// Convenience selector
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});
