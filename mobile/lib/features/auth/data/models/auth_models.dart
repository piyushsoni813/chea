import '../../domain/entities/user.dart';

class TokenPairModel {
  final String accessToken;
  final String refreshToken;
  final String tokenType;

  const TokenPairModel({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
  });

  factory TokenPairModel.fromJson(Map<String, dynamic> j) => TokenPairModel(
        accessToken:  j['access_token']  as String,
        refreshToken: j['refresh_token'] as String,
        tokenType:    j['token_type']    as String? ?? 'bearer',
      );
}

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.role,
    required super.isActive,
    required super.isVerified,
    super.avatarUrl,
    super.studentProfile,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) {
    final sp = j['student_profile'] as Map<String, dynamic>?;
    return UserModel(
      id:         j['id']         as String,
      email:      j['email']      as String,
      fullName:   j['full_name']  as String,
      role:       j['role']       as String,
      isActive:   j['is_active']  as bool? ?? true,
      isVerified: j['is_verified'] as bool? ?? false,
      avatarUrl:  j['avatar_url'] as String?,
      studentProfile: sp == null ? null : StudentProfile(
        rollNumber:  sp['roll_number']  as String?,
        semester:    sp['semester']     as int?,
        branch:      sp['branch']       as String?,
        phone:       sp['phone']        as String?,
        bio:         sp['bio']          as String?,
        resumeUrl:   sp['resume_url']   as String?,
        linkedinUrl: sp['linkedin_url'] as String?,
      ),
    );
  }
}
