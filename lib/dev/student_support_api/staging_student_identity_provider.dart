import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/errors/app_failure.dart';
import '../../features/auth/domain/student_identity_provider.dart';
import '../../features/auth/domain/auth_session.dart';

abstract interface class StagingIdentityStorage {
  Future<String?> readStudentCode();

  Future<void> writeStudentCode(String studentCode);

  Future<void> deleteStudentCode();
}

class FlutterSecureStagingIdentityStorage implements StagingIdentityStorage {
  FlutterSecureStagingIdentityStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _storageKey = 'student_support_staging_student_code_v1';

  final FlutterSecureStorage _storage;

  @override
  Future<void> deleteStudentCode() => _storage.delete(key: _storageKey);

  @override
  Future<String?> readStudentCode() => _storage.read(key: _storageKey);

  @override
  Future<void> writeStudentCode(String studentCode) =>
      _storage.write(key: _storageKey, value: studentCode);
}

/// The explicit identity selector for the verified development/staging API.
///
/// The selected value is a non-secret synthetic data scope, never an official
/// DLU account, token, or password. It is deliberately isolated from the
/// production composition root.
class StagingStudentIdentityProvider implements StudentIdentityProvider {
  StagingStudentIdentityProvider({
    StagingIdentityStorage? storage,
    this.includeTeacher = false,
  }) : _storage = storage ?? FlutterSecureStagingIdentityStorage();

  static const identities = <StudentIdentity>[
    StudentIdentity(studentCode: 'SV001', label: 'Sinh viên mẫu 01'),
    StudentIdentity(studentCode: 'SV002', label: 'Sinh viên mẫu 02'),
  ];

  final StagingIdentityStorage _storage;
  final bool includeTeacher;
  static const teacherIdentity = DluIdentity(
    studentCode: 'GV001',
    label: 'Giảng viên mẫu 01',
    role: DluRole.teacher,
  );
  final StreamController<void> _invalidations =
      StreamController<void>.broadcast();

  StudentIdentity? _selected;

  @override
  List<StudentIdentity> get availableIdentities => [
    ...identities,
    if (includeTeacher) teacherIdentity,
  ];

  @override
  Stream<void> get invalidations => _invalidations.stream;

  @override
  Future<void> clear() async {
    _selected = null;
    await _storage.deleteStudentCode();
  }

  @override
  Future<void> invalidate() async {
    await clear();
    if (!_invalidations.isClosed) _invalidations.add(null);
  }

  @override
  Future<StudentIdentity?> restore() async {
    final selected = _selected;
    if (selected != null) return selected;

    final storedCode = await _storage.readStudentCode();
    if (storedCode == null) return null;
    final identity = _identityFor(storedCode);
    if (identity == null) {
      await _storage.deleteStudentCode();
      return null;
    }
    _selected = identity;
    return identity;
  }

  @override
  Future<void> select(String studentCode) async {
    final identity = _identityFor(studentCode);
    if (identity == null) {
      throw const ConfigurationFailure(
        'Dữ liệu người học được chọn không hợp lệ.',
        code: 'STAGING_IDENTITY_SELECTION_INVALID',
      );
    }
    await _storage.writeStudentCode(identity.studentCode);
    _selected = identity;
  }

  StudentIdentity? _identityFor(String code) {
    final normalized = code.trim().toUpperCase();
    for (final identity in availableIdentities) {
      if (identity.studentCode == normalized) return identity;
    }
    return null;
  }
}

/// Used by client-only tests and by adapters constructed without an interactive
/// staging composition root. It never participates in production bootstrap.
class FixedStagingStudentIdentityProvider implements StudentIdentityProvider {
  FixedStagingStudentIdentityProvider(String studentCode)
    : _identity = _identityFor(studentCode);

  final StudentIdentity _identity;

  @override
  List<StudentIdentity> get availableIdentities => <StudentIdentity>[_identity];

  @override
  Future<void> clear() async {}

  @override
  Future<void> invalidate() async {}

  @override
  Stream<void> get invalidations => const Stream<void>.empty();

  @override
  Future<StudentIdentity?> restore() async => _identity;

  @override
  Future<void> select(String studentCode) async {
    if (studentCode.trim().toUpperCase() != _identity.studentCode) {
      throw const ConfigurationFailure(
        'Dữ liệu người học được chọn không hợp lệ.',
        code: 'STAGING_IDENTITY_SELECTION_INVALID',
      );
    }
  }

  static StudentIdentity _identityFor(String code) {
    final normalized = code.trim().toUpperCase();
    for (final identity in StagingStudentIdentityProvider.identities) {
      if (identity.studentCode == normalized) return identity;
    }
    throw const ConfigurationFailure(
      'Cấu hình dữ liệu người học không hợp lệ.',
      code: 'STAGING_STUDENT_CODE_INVALID',
    );
  }
}
