import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/staging_student_identity_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'persists and restores only an allowlisted development identity',
    () async {
      final storage = _MemoryStagingIdentityStorage();
      final provider = StagingStudentIdentityProvider(storage: storage);

      await provider.select('sv002');

      final restored = await StagingStudentIdentityProvider(
        storage: storage,
      ).restore();
      expect(restored?.studentCode, 'SV002');
      expect(restored?.label, 'Sinh viên mẫu 02');
    },
  );

  test(
    'rejects unknown selections and removes an invalid stored value',
    () async {
      final storage = _MemoryStagingIdentityStorage(value: 'SV999');
      final provider = StagingStudentIdentityProvider(storage: storage);

      expect(await provider.restore(), isNull);
      expect(storage.value, isNull);
      await expectLater(
        provider.select('teacher'),
        throwsA(
          isA<ConfigurationFailure>().having(
            (failure) => failure.code,
            'code',
            'STAGING_IDENTITY_SELECTION_INVALID',
          ),
        ),
      );
    },
  );

  test(
    'clears the selected identity and emits when staging rejects it',
    () async {
      final storage = _MemoryStagingIdentityStorage();
      final provider = StagingStudentIdentityProvider(storage: storage);
      await provider.select('SV001');

      final invalidation = expectLater(provider.invalidations, emits(isNull));
      await provider.invalidate();

      await invalidation;
      expect(await provider.restore(), isNull);
      expect(storage.value, isNull);
    },
  );
}

class _MemoryStagingIdentityStorage implements StagingIdentityStorage {
  _MemoryStagingIdentityStorage({this.value});

  String? value;

  @override
  Future<void> deleteStudentCode() async => value = null;

  @override
  Future<String?> readStudentCode() async => value;

  @override
  Future<void> writeStudentCode(String studentCode) async {
    value = studentCode;
  }
}
