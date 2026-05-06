import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/favorite_meal.dart';

abstract class FavoritesRepository {
  Future<void> init();
  Future<List<FavoriteMeal>> getAllFavorites();
  Future<FavoriteMeal?> getById(String id);
  Future<bool> isFavorite(String id);
  Future<void> saveMeal(FavoriteMeal meal);
  Future<void> updateNote({
    required String id,
    required String noteTitle,
    required String noteBody,
  });
  Future<void> deleteMeal(String id);
  Stream<List<FavoriteMeal>> watchFavorites();
}

class SqfliteFavoritesRepository implements FavoritesRepository {
  static const String _table = 'favorites';
  static const int _version = 1;

  Database? _db;
  final StreamController<List<FavoriteMeal>> _controller =
      StreamController<List<FavoriteMeal>>.broadcast();

  @override
  Future<void> init() async {
    if (_db != null) return;

    DatabaseFactory factory;
    String path;

    if (kIsWeb) {
      throw UnsupportedError(
        'sqflite does not support web. Run on macOS, iOS, Android, or desktop.',
      );
    }

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      factory = databaseFactoryFfi;
      final dir = await getApplicationSupportDirectory();
      path = p.join(dir.path, 'terrabite.db');
    } else {
      factory = databaseFactory;
      final dir = await getDatabasesPath();
      path = p.join(dir, 'terrabite.db');
    }

    _db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_table (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              thumbnailUrl TEXT NOT NULL,
              category TEXT NOT NULL,
              area TEXT NOT NULL,
              noteTitle TEXT NOT NULL,
              noteBody TEXT NOT NULL,
              savedAt TEXT NOT NULL
            )
          ''');
        },
      ),
    );

    await _emitAll();
  }

  Database get _required {
    final db = _db;
    if (db == null) {
      throw StateError('FavoritesRepository was not initialized.');
    }
    return db;
  }

  @override
  Future<List<FavoriteMeal>> getAllFavorites() async {
    final rows = await _required.query(_table, orderBy: 'savedAt DESC');
    return rows.map(FavoriteMeal.fromMap).toList();
  }

  @override
  Future<FavoriteMeal?> getById(String id) async {
    final rows = await _required.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return FavoriteMeal.fromMap(rows.first);
  }

  @override
  Future<bool> isFavorite(String id) async {
    final rows = await _required.query(
      _table,
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  @override
  Future<void> saveMeal(FavoriteMeal meal) async {
    await _required.insert(
      _table,
      meal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _emitAll();
  }

  @override
  Future<void> updateNote({
    required String id,
    required String noteTitle,
    required String noteBody,
  }) async {
    await _required.update(
      _table,
      {'noteTitle': noteTitle, 'noteBody': noteBody},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _emitAll();
  }

  @override
  Future<void> deleteMeal(String id) async {
    await _required.delete(_table, where: 'id = ?', whereArgs: [id]);
    await _emitAll();
  }

  @override
  Stream<List<FavoriteMeal>> watchFavorites() => _controller.stream;

  Future<void> _emitAll() async {
    if (_controller.isClosed) return;
    final list = await getAllFavorites();
    _controller.add(list);
  }

  Future<void> dispose() async {
    await _controller.close();
    await _db?.close();
    _db = null;
  }
}
