import 'dart:convert';

import 'package:flutter/services.dart';

typedef FixtureAssetLoader = Future<String> Function(String assetPath);

/// Loads the single generated dataset used by DEV and tests.
///
/// The asset is generated offline from a fixed seed. It never contains live
/// DLU data and this data source is never wired by the production entrypoint.
class SyntheticFixtureDataSource {
  SyntheticFixtureDataSource({FixtureAssetLoader? loadAsset})
    : _loadAsset = loadAsset ?? rootBundle.loadString;

  static const assetPath = 'database/fixtures/dlu_lms_fixture.json';

  final FixtureAssetLoader _loadAsset;
  Future<SyntheticFixtureSnapshot>? _snapshot;

  Future<SyntheticFixtureSnapshot> load() => _snapshot ??= _loadSnapshot();

  Future<SyntheticFixtureSnapshot> _loadSnapshot() async {
    final decoded = jsonDecode(await _loadAsset(assetPath));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Fixture root must be a JSON object.');
    }

    final metadata = decoded['metadata'];
    final rawTables = decoded['tables'];
    if (metadata is! Map<String, dynamic> ||
        rawTables is! Map<String, dynamic>) {
      throw const FormatException(
        'Fixture must contain metadata and tables objects.',
      );
    }
    if (metadata['source_classification'] != 'SYNTHETIC_DATA') {
      throw const FormatException(
        'Only a SYNTHETIC_DATA fixture may be loaded in DEV.',
      );
    }

    final seed = _readInt(metadata, 'seed');
    final referenceTimeEpoch = _readInt(metadata, 'reference_time_epoch');
    final tables = <String, List<Map<String, Object?>>>{};
    for (final entry in rawTables.entries) {
      final rows = entry.value;
      if (rows is! List) {
        throw FormatException('Fixture table ${entry.key} must be a list.');
      }
      tables[entry.key] = rows
          .map((row) {
            if (row is! Map<String, dynamic>) {
              throw FormatException(
                'Fixture table ${entry.key} contains a non-object row.',
              );
            }
            return Map<String, Object?>.from(row);
          })
          .toList(growable: false);
    }

    return SyntheticFixtureSnapshot(
      seed: seed,
      referenceTime: DateTime.fromMillisecondsSinceEpoch(
        referenceTimeEpoch * 1000,
        isUtc: true,
      ),
      tables: Map.unmodifiable(tables),
    );
  }
}

class SyntheticFixtureSnapshot {
  const SyntheticFixtureSnapshot({
    required this.seed,
    required this.referenceTime,
    required this.tables,
  });

  final int seed;
  final DateTime referenceTime;
  final Map<String, List<Map<String, Object?>>> tables;

  List<Map<String, Object?>> table(String name) {
    final rows = tables[name];
    if (rows == null) {
      throw FormatException('Required fixture table is missing: $name');
    }
    return rows;
  }
}

int fixtureInt(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.parse(value);
  throw FormatException('Expected integer field: $key');
}

double? fixtureNullableDouble(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.parse(value);
  throw FormatException('Expected numeric field: $key');
}

String fixtureString(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is String) return value;
  throw FormatException('Expected string field: $key');
}

String? fixtureNullableString(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value == null) return null;
  if (value is String) return value;
  throw FormatException('Expected nullable string field: $key');
}

bool fixtureBool(Map<String, Object?> row, String key) =>
    fixtureInt(row, key) != 0;

int _readInt(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw FormatException('Expected integer metadata field: $key');
}
