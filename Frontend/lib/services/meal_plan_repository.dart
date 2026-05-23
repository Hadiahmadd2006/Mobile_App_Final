import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

import '../models/plan_entry.dart';

/// Persists Meal Planner entries (date + slot → meal) on-device.
///
/// Best-effort by design — storage failures degrade to an empty plan
/// rather than throwing, so a corrupted DB can't brick the Pro hub.
class MealPlanRepository {
  static const String _table = 'plan';

  Database? _db;
  final StreamController<List<PlanEntry>> _controller =
      StreamController<List<PlanEntry>>.broadcast();

  Future<void> init() async {
    if (_db != null) {
      await _emit();
      return;
    }
    if (kIsWeb) {
      await _emit();
      return;
    }
    try {
      final DatabaseFactory factory;
      final String path;
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        ffi.sqfliteFfiInit();
        factory = ffi.databaseFactoryFfi;
        final dir = await getApplicationSupportDirectory();
        path = p.join(dir.path, 'terrabite_plan.db');
      } else {
        factory = databaseFactory;
        final dir = await getDatabasesPath();
        path = p.join(dir, 'terrabite_plan.db');
      }
      _db = await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE $_table (
                date TEXT NOT NULL,
                slot TEXT NOT NULL,
                mealId TEXT NOT NULL,
                mealName TEXT NOT NULL,
                mealImage TEXT NOT NULL,
                source TEXT NOT NULL,
                PRIMARY KEY (date, slot)
              )
            ''');
          },
        ),
      );
    } catch (_) {
      _db = null;
    }
    await _emit();
  }

  /// All planned entries for [startDate]..[endDate] inclusive (yyyy-MM-dd).
  Future<List<PlanEntry>> getRange(String startDate, String endDate) async {
    final db = _db;
    if (db == null) return const [];
    try {
      final rows = await db.query(
        _table,
        where: 'date BETWEEN ? AND ?',
        whereArgs: [startDate, endDate],
        orderBy: 'date ASC, slot ASC',
      );
      return rows.map(PlanEntry.fromMap).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// Insert or replace an entry at (date, slot).
  Future<void> upsert(PlanEntry entry) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.insert(
        _table,
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _emit();
    } catch (_) {
      // Swallow — never disrupt the app.
    }
  }

  /// Remove the entry at (date, slot) if present.
  Future<void> remove(String date, PlanSlot slot) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.delete(
        _table,
        where: 'date = ? AND slot = ?',
        whereArgs: [date, slot.name],
      );
      await _emit();
    } catch (_) {}
  }

  Stream<List<PlanEntry>> watch() => _controller.stream;

  Future<void> _emit() async {
    if (_controller.isClosed) return;
    final db = _db;
    if (db == null) {
      _controller.add(const []);
      return;
    }
    try {
      final rows = await db.query(_table, orderBy: 'date ASC, slot ASC');
      _controller.add(
        rows.map(PlanEntry.fromMap).toList(growable: false),
      );
    } catch (_) {
      _controller.add(const []);
    }
  }

  Future<void> dispose() async {
    await _controller.close();
    await _db?.close();
    _db = null;
  }
}
