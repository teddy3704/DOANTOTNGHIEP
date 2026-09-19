import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import 'auth_session.dart';

/// A non-secret student identity selected by an explicitly configured build.
///
/// In staging this represents synthetic data selection only. A future
/// DLU-backed implementation may satisfy the same contract after the official
/// authentication mechanism has been approved and verified.
class DluIdentity {
  const DluIdentity({
    required this.studentCode,
    required this.label,
    this.role = DluRole.student,
  });

  final String studentCode;
  final String label;
  final DluRole role;
  String get id => studentCode;
}

// Compatibility alias for the existing student-only API contract.
typedef StudentIdentity = DluIdentity;

abstract interface class StudentIdentityProvider {
  List<StudentIdentity> get availableIdentities;

  Future<StudentIdentity?> restore();

  Future<void> select(String studentCode);

  Future<void> clear();

  /// Emits when the selected identity is rejected by its backing service.
  Stream<void> get invalidations;

  Future<void> invalidate();
}

/// Marker for the future official identity adapter.
///
/// No implementation is provided until DLU confirms a supported mobile
/// authentication contract.
abstract interface class DluMoodleIdentityProvider
    implements StudentIdentityProvider {}

class UnavailableStudentIdentityProvider implements StudentIdentityProvider {
  const UnavailableStudentIdentityProvider();

  @override
  List<StudentIdentity> get availableIdentities => const <StudentIdentity>[];

  @override
  Future<void> clear() async {}

  @override
  Future<void> invalidate() async {}

  @override
  Stream<void> get invalidations => const Stream<void>.empty();

  @override
  Future<StudentIdentity?> restore() async => null;

  @override
  Future<void> select(String studentCode) {
    throw const ConfigurationFailure(
      'Cơ chế định danh người học chưa được cấu hình.',
      code: 'STUDENT_IDENTITY_UNCONFIGURED',
    );
  }
}

final studentIdentityProvider = Provider<StudentIdentityProvider>(
  (ref) => const UnavailableStudentIdentityProvider(),
);
