import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_settings.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../services/reminder_service.dart';
import 'onboarding_screen.dart';
import 'role_selection_screen.dart';
import 'student/student_main_screen.dart';
import 'teacher/teacher_main_screen.dart';

/// Device-only memory of the last login (student code / username). Never the password.
abstract class LoginMemory {
  Future<String?> read();
  Future<void> write(String? login);
}

class SharedPrefsLoginMemory implements LoginMemory {
  static const _key = 'remembered_login';
  const SharedPrefsLoginMemory();
  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);
  @override
  Future<void> write(String? login) async {
    final p = await SharedPreferences.getInstance();
    if (login == null) {
      await p.remove(_key);
    } else {
      await p.setString(_key, login);
    }
  }
}

/// Sign-in like the School's LMS: student code (MSSV) or username + password. The server decides the role.
class LoginScreen extends StatefulWidget {
  final ApiService? apiService;
  final LoginMemory memory;
  final ReminderService? reminders;
  const LoginScreen({
    super.key,
    this.apiService,
    this.memory = const SharedPrefsLoginMemory(),
    this.reminders,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final ApiService _api = widget.apiService ?? ApiService();
  final _form = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;
  bool _remember = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.memory
        .read()
        .then((v) {
          if (!mounted || v == null || _login.text.isNotEmpty) return;
          setState(() => _login.text = v);
        })
        .catchError((Object _) {});
  }

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    if (widget.apiService == null) _api.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final login = _login.text.replaceAll(RegExp(r'\s'), '');
    try {
      final role = await _api.login(login, _password.text);
      _password.clear();
      try {
        await widget.memory.write(_remember ? login : null);
      } catch (_) {}
      if (!mounted) return;
      setState(() => _busy = false);
      await _open(role);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = apiErrorMessage(e);
        });
      }
    }
  }

  Future<void> _open(String role) async {
    if (AppSettings.onboardingEnabled && !AppSettings.onboardingSeen) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      if (!mounted) return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => role == 'TEACHER'
            ? TeacherMainScreen(apiService: _api)
            : StudentMainScreen(apiService: _api, reminders: widget.reminders),
      ),
    );
    // Back here means signed out: token, offline cache and this account's phone reminders go.
    _api.signOut();
    await (widget.reminders ?? ReminderService()).clearAll();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(actions: const [ThemeModeMenu()]),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.school_rounded,
                        size: 64,
                        color: theme.colorScheme.primary,
                        semanticLabel: 'Hỗ trợ học tập LMS',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Hỗ trợ học tập LMS',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dùng tài khoản LMS của trường',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        key: const Key('login-id'),
                        controller: _login,
                        enabled: !_busy,
                        keyboardType: TextInputType.visiblePassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        maxLength: 64,
                        decoration: const InputDecoration(
                          labelText: 'Mã số sinh viên / Tên đăng nhập',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                        validator: (v) =>
                            (v ?? '').replaceAll(RegExp(r'\s'), '').isEmpty
                            ? 'Nhập mã số sinh viên hoặc tên đăng nhập'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('login-password'),
                        controller: _password,
                        enabled: !_busy,
                        obscureText: _hidden,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        maxLength: 128,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          counterText: '',
                          suffixIcon: IconButton(
                            key: const Key('login-toggle-password'),
                            tooltip: _hidden ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                            icon: Icon(
                              _hidden
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(() => _hidden = !_hidden),
                          ),
                        ),
                        validator: (v) =>
                            (v ?? '').isEmpty ? 'Nhập mật khẩu' : null,
                      ),
                      CheckboxListTile(
                        key: const Key('login-remember'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _remember,
                        onChanged: _busy
                            ? null
                            : (v) => setState(() => _remember = v ?? false),
                        title: const Text('Ghi nhớ mã số'),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _error!,
                            key: const Key('login-error'),
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      FilledButton(
                        key: const Key('login-submit'),
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Đăng nhập'),
                      ),
                      if (_api.localDevelopment) ...[
                        const SizedBox(height: 20),
                        TextButton(
                          key: const Key('login-demo-mode'),
                          onPressed: _busy
                              ? null
                              : () => Navigator.push<void>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RoleSelectionScreen(apiService: _api),
                                  ),
                                ),
                          child: const Text('Chế độ demo'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
