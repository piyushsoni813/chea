class User {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;
  final bool isVerified;
  final String? avatarUrl;
  final StudentProfile? studentProfile;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.isVerified,
    this.avatarUrl,
    this.studentProfile,
  });

  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get isStaff => isAdmin || role == 'faculty';
}

class StudentProfile {
  final String? rollNumber;
  final int? semester;
  final String? branch;
  final String? phone;
  final String? bio;
  final String? resumeUrl;
  final String? linkedinUrl;

  const StudentProfile({
    this.rollNumber,
    this.semester,
    this.branch,
    this.phone,
    this.bio,
    this.resumeUrl,
    this.linkedinUrl,
  });
}
