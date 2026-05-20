import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

import '../models/meal.dart';

/// Tracks the meals the user has opened, most-recent first.
///
/// Best-effort by design: any storage failure degrades to an empty history
/// rather than throwing — view history must never disrupt the app.
class RecentlyViewedRepository {
  static const String _table = 'recent';
  static const int _maxItems = 12;

  Database? _db;
  final StreamController<List<Meal>> _controller =
      StreamController<List<Meal>>.broadcast();

  Future<void> init() async {
    if (_db != null) {
      await _emit();
      return;
    }
    if (!kIsWeb) {
      try {
        final DatabaseFactory factory;
        final String path;
        if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
          ffi.sqfliteFfiInit();
          factory = ffi.databaseFactoryFfi;
          final dir = await getApplicationSupportDirectory();
          path = p.join(dir.path, 'terrabite_recent.db');
        } else {
          factory = databaseFactory;
          final dir = await getDatabasesPath();
          path = p.join(dir, 'terrabite_recent.db');
        }
        _db = await factory.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute('''
                CREATE TABLE $_table (
                  id TEXT PRIMARY KEY,
                  name TEXT NOT NULL,
                  thumbnailUrl TEXT NOT NULL,
                  viewedAt TEXT NOT NULL
                )
              ''');
            },
          ),
        );
      } catch (_) {
        _db = null;
      }
    }
    await _emit();
  }

  Future<List<Meal>> getRecent() async {
    final db = _db;
    if (db == null) return const [];
    try {
      final rows = await db.query(
        _table,
        orderBy: 'viewedAt DESC',
        limit: _maxItems,
      );
      return rows
          .map(
            (row) => Meal(
              id: row['id'] as String,
              name: row['name'] as String,
              thumbnailUrl: row['thumbnailUrl'] as String,
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> record(Meal meal) async {
    final db = _db;
    if (db == null || meal.id.isEmpty) return;
    try {
      await db.insert(
        _table,
        {
          'id': meal.id,
          'name': meal.name,
          'thumbnailUrl': meal.thumbnailUrl,
          'viewedAt': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await db.delete(
        _table,
        where: 'id NOT IN '
            '(SELECT id FROM $_table ORDER BY viewedAt DESC LIMIT ?)',
        whereArgs: [_maxItems],
      );
      await _emit();
    } catch (_) {
      // Best-effort — never disrupt the app over view history.
    }
  }

  Stream<List<Meal>> watch() => _controller.stream;

  Future<void> _emit() async {
    if (_controller.isClosed) return;
    _controller.add(await getRecent());
  }

  Future<void> dispose() async {
    await _controller.close();
    await _db?.close();
    _db = null;
  }
}
