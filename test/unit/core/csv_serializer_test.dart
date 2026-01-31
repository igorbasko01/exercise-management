import 'package:exercise_management/core/csv_serializer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CsvSerializer', () {
    group('toCSV', () {
      test('returns empty string for empty list', () {
        final result = CsvSerializer.toCSV([]);
        expect(result, '');
      });

      test('creates CSV with header row from map keys', () {
        final items = [
          {'id': '1', 'name': 'Test', 'value': 42},
        ];

        final result = CsvSerializer.toCSV(items);

        expect(result, contains('id,name,value'));
        expect(result, contains('1,Test,42'));
      });

      test('handles null values as empty strings', () {
        final items = [
          {'id': '1', 'name': null, 'value': 42},
        ];

        final result = CsvSerializer.toCSV(items);

        expect(result, contains('1,,42'));
      });

      test('creates multiple rows', () {
        final items = [
          {'id': '1', 'name': 'First'},
          {'id': '2', 'name': 'Second'},
        ];

        final result = CsvSerializer.toCSV(items);

        // CSV library adds \r\n between rows, header + 2 data rows
        expect(result, contains('id,name'));
        expect(result, contains('1,First'));
        expect(result, contains('2,Second'));
      });
    });

    group('fromCSV', () {
      test('returns empty list for empty string', () {
        final result = CsvSerializer.fromCSV('');
        expect(result, isEmpty);
      });

      test('returns empty list for header-only CSV', () {
        final result = CsvSerializer.fromCSV('id,name,value');
        expect(result, isEmpty);
      });

      test('parses CSV into list of maps', () {
        const csv = 'id,name,value\n1,Test,42';

        final result = CsvSerializer.fromCSV(csv);

        expect(result.length, 1);
        expect(result[0]['id'], 1);
        expect(result[0]['name'], 'Test');
        expect(result[0]['value'], 42);
      });

      test('handles empty values as null', () {
        const csv = 'id,name,value\n1,,42';

        final result = CsvSerializer.fromCSV(csv);

        expect(result[0]['name'], isNull);
      });

      test('parses multiple rows', () {
        const csv = 'id,name\n1,First\n2,Second';

        final result = CsvSerializer.fromCSV(csv);

        expect(result.length, 2);
        expect(result[0]['id'], 1);
        expect(result[0]['name'], 'First');
        expect(result[1]['id'], 2);
        expect(result[1]['name'], 'Second');
      });

      test('handles missing columns gracefully (backward compatibility)', () {
        // Simulate an older CSV format missing a column
        const csv = 'id,name\n1,Test';

        final result = CsvSerializer.fromCSV(csv);

        // Should have the columns that exist
        expect(result[0]['id'], 1);
        expect(result[0]['name'], 'Test');
        // An older file would not have a 'completed_at' column
        // The model's fromMap should handle this with null
        expect(result[0].containsKey('completed_at'), isFalse);
      });
    });

    group('round-trip', () {
      test('fromCSV(toCSV(data)) preserves data', () {
        final originalItems = [
          {'id': '1', 'name': 'Exercise 1', 'weight': 10.5},
          {'id': '2', 'name': 'Exercise 2', 'weight': 20.0},
        ];

        final csv = CsvSerializer.toCSV(originalItems);
        final parsedItems = CsvSerializer.fromCSV(csv);

        expect(parsedItems.length, 2);
        // Note: CSV library parses '1' (unquoted number) as int 1
        // The model's fromMap handles type coercion via .toString()
        expect(parsedItems[0]['id'].toString(), '1');
        expect(parsedItems[0]['name'], 'Exercise 1');
        expect(parsedItems[0]['weight'], 10.5);
        expect(parsedItems[1]['id'].toString(), '2');
        expect(parsedItems[1]['name'], 'Exercise 2');
        expect(parsedItems[1]['weight'], 20.0);
      });

      test('handles DateTime values correctly', () {
        final dateTime = DateTime(2026, 1, 31, 10, 30, 0);
        final originalItems = [
          {
            'id': '1',
            'date_time': dateTime.toIso8601String(),
            'completed_at': dateTime.toIso8601String()
          },
        ];

        final csv = CsvSerializer.toCSV(originalItems);
        final parsedItems = CsvSerializer.fromCSV(csv);

        // DateTime strings are preserved as strings
        expect(parsedItems[0]['date_time']?.toString(),
            dateTime.toIso8601String());
        expect(parsedItems[0]['completed_at']?.toString(),
            dateTime.toIso8601String());
      });

      test('handles null DateTime values correctly', () {
        final originalItems = [
          {
            'id': '1',
            'date_time': DateTime.now().toIso8601String(),
            'completed_at': null
          },
        ];

        final csv = CsvSerializer.toCSV(originalItems);
        final parsedItems = CsvSerializer.fromCSV(csv);

        expect(parsedItems[0]['completed_at'], isNull);
      });
    });
  });
}
