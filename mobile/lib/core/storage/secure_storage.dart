import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  final _store = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    // flutter_secure_storage_web always encrypts via Web Crypto. If the AES-GCM
    // key stored in localStorage is corrupted from a previous session,
    // crypto.subtle.importKey() throws DOMException(OperationError). That
    // exception is NOT a Dart Exception, so _decryptValue's `on Exception catch`
    // does not catch it and it propagates to callers. The Dio interceptor now
    // wraps all _storage reads in try/catch to prevent this from killing
    // in-flight requests. See _AuthInterceptor.onRequest in dio_client.dart.
  );

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _store.write(key: AppConstants.kAccessToken,  value: accessToken),
      _store.write(key: AppConstants.kRefreshToken, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken()  => _store.read(key: AppConstants.kAccessToken);
  Future<String?> getRefreshToken() => _store.read(key: AppConstants.kRefreshToken);

  Future<void> saveRole(String role) =>
      _store.write(key: AppConstants.kUserRole, value: role);
  Future<String?> getRole() => _store.read(key: AppConstants.kUserRole);

  Future<void> saveFcmToken(String token) =>
      _store.write(key: AppConstants.kFcmToken, value: token);
  Future<String?> getFcmToken() => _store.read(key: AppConstants.kFcmToken);

  Future<void> clearAll() => _store.deleteAll();
}
