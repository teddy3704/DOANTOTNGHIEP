import 'package:http/http.dart' as http;
import 'package:lms_mobile_app/services/api_service.dart';
import 'package:lms_mobile_app/services/api_session.dart';

// MOCK identities are isolated to tests; runtime IDs only come from login.
const mockStudentId = 205;
const mockTeacherId = 102;
const mockApiBaseUrl = 'http://127.0.0.1:8081/api/v1';

class MockApiSession extends ApiSession {
  @override
  String get token => 'mock-test-token';

  @override
  int userIdFor(String role) =>
      role == 'STUDENT' ? mockStudentId : mockTeacherId;
}

ApiService testApi({required http.Client client}) => ApiService(
  client: client,
  baseUrl: mockApiBaseUrl,
  localDevelopment: true,
  session: MockApiSession(),
);
