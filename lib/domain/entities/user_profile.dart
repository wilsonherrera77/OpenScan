/// User Profile Entity
/// Contains user information including role and metadata
class UserProfile {
  final int id;
  final int userId;
  final String username;
  final String email;
  final UserRole role;
  final String? phoneNumber;
  final String? organization;
  final int documentsDigitized;
  final DateTime lastActive;
  final bool isActive;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.organization,
    required this.documentsDigitized,
    required this.lastActive,
    required this.isActive,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // 🔍 DIAGNOSTIC LOGGING (2025-11-09 - Issue: Admin sees Viewer dashboard)
    print('═══════════════════════════════════════════════════════════');
    print('🔍 USER PROFILE DEBUG - Backend Response');
    print('═══════════════════════════════════════════════════════════');
    print('📄 Full JSON: ${json.toString()}');
    print('👤 Username: ${json['username']}');
    print('🎭 Role (raw from backend): "${json['role']}"');
    print('📧 Email: ${json['email']}');
    print('🔢 User ID: ${json['id']}');
    print('═══════════════════════════════════════════════════════════');

    return UserProfile(
      id: json['id'],
      userId: json['user'] ?? json['id'],
      username: json['username'],
      email: json['email'] ?? '',
      role: UserRole.fromString(json['role'], json['username']),
      phoneNumber: json['phone_number'],
      organization: json['organization'],
      documentsDigitized: json['documents_digitized'] ?? 0,
      lastActive: DateTime.parse(json['last_active'] ?? DateTime.now().toIso8601String()),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'username': username,
      'email': email,
      'role': role.value,
      'phone_number': phoneNumber,
      'organization': organization,
      'documents_digitized': documentsDigitized,
      'last_active': lastActive.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if user is digitizer
  bool get isDigitizer => role == UserRole.digitalizador;

  /// Check if user is reviewer
  bool get isReviewer => role == UserRole.revisor;

  /// Check if user is viewer
  bool get isViewer => role == UserRole.viewer;

  /// Check if user can digitize
  bool get canDigitize => isAdmin || isDigitizer;

  /// Check if user can review
  bool get canReview => isAdmin || isReviewer;

  /// Check if user can manage assignments
  bool get canManageAssignments => isAdmin;
}

/// User Role Enum
enum UserRole {
  admin,
  digitalizador,
  revisor,
  viewer;

  String get value {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.digitalizador:
        return 'DIGITALIZADOR';
      case UserRole.revisor:
        return 'REVISOR';
      case UserRole.viewer:
        return 'VIEWER';
    }
  }

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.digitalizador:
        return 'Digitalizador';
      case UserRole.revisor:
        return 'Revisor';
      case UserRole.viewer:
        return 'Visualizador';
    }
  }

  static UserRole fromString(String? value, [String? username]) {
    // 🩹 WORKAROUND (2025-11-09): Force admin role if username is "admin"
    // Root cause: Backend returns incorrect role for admin user
    // TODO: Remove this workaround once backend is fixed
    if (username?.toLowerCase() == 'admin') {
      print('⚠️  WORKAROUND APPLIED: Forcing admin role for username="$username"');
      print('   Backend returned role: "$value" (ignored)');
      print('   Frontend forcing role: ADMIN');
      return UserRole.admin;
    }

    // Normal role parsing
    final parsedRole = switch (value?.toUpperCase()) {
      'ADMIN' => UserRole.admin,
      'DIGITALIZADOR' => UserRole.digitalizador,
      'REVISOR' => UserRole.revisor,
      'VIEWER' => UserRole.viewer,
      _ => UserRole.viewer, // Default to most restrictive role
    };

    print('✅ Role parsed: ${parsedRole.name} (from backend value: "$value")');
    return parsedRole;
  }
}
