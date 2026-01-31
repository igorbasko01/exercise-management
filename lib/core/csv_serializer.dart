import 'package:csv/csv.dart';

/// A utility class for converting between CSV strings and `List<Map<String, dynamic>>`.
///
/// This class provides a bridge between CSV file format and the Map-based
/// serialization used by model classes (toMap/fromMap).
class CsvSerializer {
  /// Converts a list of maps to a CSV string.
  ///
  /// The keys from the first map are used as the CSV header row.
  /// All maps should have the same keys for consistent output.
  /// Null values are converted to empty strings in the CSV.
  static String toCSV(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return '';
    }

    final headers = items.first.keys.toList();
    final rows = <List<dynamic>>[];

    // Add header row
    rows.add(headers);

    // Add data rows
    for (final item in items) {
      final row = headers.map((header) {
        final value = item[header];
        if (value == null) {
          return '';
        }
        return value.toString();
      }).toList();
      rows.add(row);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Parses a CSV string into a list of maps.
  ///
  /// The first row is treated as headers, and subsequent rows become maps
  /// with those headers as keys.
  ///
  /// Missing columns in a row will result in null values in the map,
  /// providing backward compatibility for older export files that may
  /// not contain all current fields.
  static List<Map<String, dynamic>> fromCSV(String csvContent) {
    if (csvContent.trim().isEmpty) {
      return [];
    }

    // Detect line ending: use \r\n if present, otherwise \n
    final eol = csvContent.contains('\r\n') ? '\r\n' : '\n';
    final rows = const CsvToListConverter().convert(csvContent, eol: eol);

    if (rows.isEmpty) {
      return [];
    }

    final headers = rows.first.map((e) => e.toString()).toList();

    if (rows.length <= 1) {
      return [];
    }

    final result = <Map<String, dynamic>>[];

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final map = <String, dynamic>{};

      for (var j = 0; j < headers.length; j++) {
        final header = headers[j];
        if (j < row.length) {
          final value = row[j];
          // Convert empty strings to null for optional fields
          if (value is String && value.isEmpty) {
            map[header] = null;
          } else {
            map[header] = value;
          }
        } else {
          // Missing column in this row
          map[header] = null;
        }
      }

      result.add(map);
    }

    return result;
  }
}
