import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

class SyncService {
  final Database _database;
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger();

  final List<String> _tables = [
    'exercise_templates',
    'exercise_sets',
    'exercise_programs',
    'exercise_program_sessions',
    'session_exercises',
  ];

  SyncService(this._database);

  Future<void> sync() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _logger.i('User not logged in, skipping sync.');
      return;
    }

    try {
      await _pushPendingChanges(user.id);
      await _pullRemoteChanges(user.id);
    } catch (e) {
      _logger.e('Error during sync', error: e);
    }
  }

  Future<void> _pushPendingChanges(String userId) async {
    for (var table in _tables) {
      final pendingRecords = await _database.query(
        table,
        where: 'sync_status != ?',
        whereArgs: ['synced'],
      );

      for (var record in pendingRecords) {
        final mutableRecord = Map<String, dynamic>.from(record);
        mutableRecord['user_id'] = userId;
        final syncStatus = mutableRecord.remove('sync_status');

        try {
          if (syncStatus == 'pending_delete') {
            if (table == 'session_exercises') {
              await _supabase.from(table).update(mutableRecord).eq('session_id', mutableRecord['session_id']).eq('ordering', mutableRecord['ordering']);
            } else {
              await _supabase.from(table).update(mutableRecord).eq('id', mutableRecord['id']);
            }
          } else {
            await _supabase.from(table).upsert(mutableRecord);
          }

          if (table == 'session_exercises') {
            await _database.update(
              table,
              {'sync_status': 'synced'},
              where: 'session_id = ? AND ordering = ?',
              whereArgs: [record['session_id'], record['ordering']],
            );
          } else {
            await _database.update(
              table,
              {'sync_status': 'synced'},
              where: 'id = ?',
              whereArgs: [record['id']],
            );
          }
        } catch (e) {
          _logger.e('Failed to push record \$record to \$table', error: e);
        }
      }
    }
  }

  Future<void> _pullRemoteChanges(String userId) async {
    for (var table in _tables) {
      final localLatest = await _database.rawQuery('''
        SELECT MAX(last_updated_at) as max_date FROM $table
      ''');

      String? lastSyncDate = localLatest.first['max_date'] as String?;

      var query = _supabase.from(table).select().eq('user_id', userId);

      if (lastSyncDate != null) {
        query = query.gt('last_updated_at', lastSyncDate);
      }

      final remoteRecords = await query;

      for (var record in remoteRecords) {
        final mutableRecord = Map<String, dynamic>.from(record);
        mutableRecord['sync_status'] = 'synced';

        await _database.insert(
          table,
          mutableRecord,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }
}
