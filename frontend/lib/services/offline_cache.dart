import 'package:shared_preferences/shared_preferences.dart';

/// V2-N11: last successful GET bodies of the summary screens, for viewing without network.
/// Keys contain the role and the request path (which already contains the user id), never the token.
abstract class OfflineStore {
  Future<void> put(String key, String body, DateTime at);
  Future<({String body, DateTime at})?> get(String key);
  Future<void> clear();
}

class SharedPrefsOfflineStore implements OfflineStore {
  static const _prefix = 'offline:';

  @override
  Future<void> put(String key, String body, DateTime at) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('$_prefix$key', body);
    await p.setInt('$_prefix$key@', at.millisecondsSinceEpoch);
  }

  @override
  Future<({String body, DateTime at})?> get(String key) async {
    final p = await SharedPreferences.getInstance();
    final body = p.getString('$_prefix$key');
    final at = p.getInt('$_prefix$key@');
    if (body == null || at == null) return null;
    return (body: body, at: DateTime.fromMillisecondsSinceEpoch(at));
  }

  @override
  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    for (final k in p.getKeys().where((k) => k.startsWith(_prefix)).toList()) {
      await p.remove(k);
    }
  }
}

class MemoryOfflineStore implements OfflineStore {
  final entries = <String, ({String body, DateTime at})>{};
  @override
  Future<void> put(String key, String body, DateTime at) async =>
      entries[key] = (body: body, at: at);
  @override
  Future<({String body, DateTime at})?> get(String key) async => entries[key];
  @override
  Future<void> clear() async => entries.clear();
}

/// GET paths whose responses are kept for offline viewing (student summary screens).
final _cacheable = RegExp(
  r'^/dev/students/\d+/(dashboard|tasks|courses|study-plan|flashcards/due'
  r'|courses/\d+/(grades|grade-forecast|flashcards))(\?.*)?$',
);

bool isOfflineCacheable(String path) => _cacheable.hasMatch(path);
