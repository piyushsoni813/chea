import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  final _store = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
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
