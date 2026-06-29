import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/auth_models.dart';

class AuthRemoteDatasource {
  final Dio _dio;
  AuthRemoteDatasource(this._dio);

  Future<TokenPairModel> login({
    required String email,
    required String password,
  }) async {
    final r = await _dio.post('/auth/login',
        data: {'email': email, 'password': password});
    return TokenPairModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<TokenPairModel> register({
    required String email,
    required String password,
    required String fullName,
    String? rollNumber,
    int? semester,
  }) async {
    final r = await _dio.post('/auth/register', data: {
      'email':      email,
      'password':   password,
      'full_name':  fullName,
      if (rollNumber != null) 'roll_number': rollNumber,
      if (semester   != null) 'semester':    semester,
    });
    return TokenPairModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<UserModel> getMe() async {
    final r = await _dio.get('/auth/me');
    return UserModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> logout() => _dio.post('/auth/logout');

  Future<void> registerDevice(String fcmToken) {
    // kIsWeb must be checked first — it is a compile-time constant and will
    // always be true on web regardless of defaultTargetPlatform.
    final platform = kIsWeb
        ? 'web'
        : switch (defaultTargetPlatform) {
            TargetPlatform.android => 'android',
            TargetPlatform.iOS     => 'ios',
            TargetPlatform.windows => 'windows',
            TargetPlatform.macOS   => 'macos',
            TargetPlatform.linux   => 'linux',
            _                      => 'unknown',
          };
    return _dio.post(
      '/profile/devices',
      data: {'fcm_token': fcmToken, 'platform': platform},
    );
  }
}
