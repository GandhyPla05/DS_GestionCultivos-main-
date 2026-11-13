import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as mobile;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' as web;

import '../models/crop_record.dart';

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  Database? _database;
  bool _ffiInitialized = false;

  Future<void> initialize() async {
    await database;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (!kIsWeb && Platform.isWindows && !_ffiInitialized) {
      sqfliteFfiInit();
      _ffiInitialized = true;
    }

    final String databasePath;
    if (kIsWeb) {
      databasePath = 'gestion_cultivos.sqlite';
    } else {
      final directory = await getApplicationSupportDirectory();
      await directory.create(recursive: true);
      databasePath =
          '${directory.path}${Platform.pathSeparator}gestion_cultivos.sqlite';
    }
    final factory = kIsWeb
        ? web.databaseFactoryFfiWeb
        : Platform.isWindows
        ? databaseFactoryFfi
        : mobile.databaseFactory;
    final openedDatabase = await factory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE crops (
              id TEXT PRIMARY KEY,
              crop TEXT NOT NULL,
              variety TEXT NOT NULL DEFAULT '',
              parcel TEXT NOT NULL DEFAULT '',
              sowing_date TEXT,
              irrigation TEXT NOT NULL DEFAULT '',
              fertilization TEXT NOT NULL DEFAULT '',
              pests TEXT NOT NULL DEFAULT '',
              harvest_date TEXT,
              status TEXT NOT NULL DEFAULT 'active',
              notes TEXT NOT NULL DEFAULT '',
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE attachments (
              id TEXT PRIMARY KEY,
              crop_id TEXT,
              name TEXT NOT NULL,
              path TEXT NOT NULL,
              extension TEXT NOT NULL,
              size INTEGER NOT NULL,
              added_at TEXT NOT NULL,
              extracted_text TEXT NOT NULL DEFAULT '',
              content BLOB,
              FOREIGN KEY (crop_id) REFERENCES crops(id) ON DELETE SET NULL
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('ALTER TABLE attachments ADD COLUMN content BLOB');
          }
        },
      ),
    );
    _database = openedDatabase;
    return openedDatabase;
  }

  Future<List<CropRecord>> getCrops({String search = ''}) async {
    final rows = await (await database).query(
      'crops',
      where: search.trim().isEmpty
          ? null
          : 'crop LIKE ? OR variety LIKE ? OR parcel LIKE ?',
      whereArgs: search.trim().isEmpty
          ? null
          : List.filled(3, '%${search.trim()}%'),
      orderBy: 'created_at DESC',
    );
    return rows.map(CropRecord.fromMap).toList();
  }

  Future<void> saveCrop(CropRecord crop) async {
    final db = await database;
    await db.transaction((transaction) async {
      final values = crop.toMap()..remove('id');
      final updated = await transaction.update(
        'crops',
        values,
        where: 'id = ?',
        whereArgs: [crop.id],
      );
      if (updated == 0) {
        await transaction.insert('crops', crop.toMap());
      }
    });
  }

  Future<void> deleteCrop(String id) async {
    final db = await database;
    await db.transaction((transaction) async {
      await transaction.update(
        'attachments',
        {'crop_id': null},
        where: 'crop_id = ?',
        whereArgs: [id],
      );
      await transaction.delete('crops', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<CropAttachment>> getAttachments({String? cropId}) async {
    final rows = await (await database).query(
      'attachments',
      where: cropId == null ? null : 'crop_id = ?',
      whereArgs: cropId == null ? null : [cropId],
      orderBy: 'added_at DESC',
    );
    return rows.map(CropAttachment.fromMap).toList();
  }

  Future<void> saveAttachment(CropAttachment attachment) async {
    await (await database).insert(
      'attachments',
      attachment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAttachment(String id) async {
    await (await database).delete(
      'attachments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
