import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mynotes/services/cloud/cloud_storage_constants.dart';

class CloudNote {
  final String documentId;
  final String ownerUserId;
  final String text;
  final DateTime createdAt;

  CloudNote({
    required this.documentId,
    required this.ownerUserId,
    required this.text,
    required this.createdAt,
  });

  CloudNote.fromSnapshot({
    required Map<String, dynamic> snapshot,
    required this.documentId,
  }) : ownerUserId = snapshot[ownerUserIdFieldName] as String,
       text = snapshot[textFieldName] as String,
       createdAt =
           _tryParseCreatedAt(snapshot[createdAtFieldName]) ??
           (throw FormatException(
             'Unsupported $createdAtFieldName value: '
             '${snapshot[createdAtFieldName]}',
           ));

  /// Like [CloudNote.fromSnapshot] but returns null for documents whose
  /// fields are missing or malformed, instead of throwing.
  static CloudNote? tryFromSnapshot({
    required Map<String, dynamic> snapshot,
    required String documentId,
  }) {
    final createdAt = _tryParseCreatedAt(snapshot[createdAtFieldName]);
    final ownerUserId = snapshot[ownerUserIdFieldName];
    final text = snapshot[textFieldName];

    if (createdAt == null || ownerUserId is! String || text is! String) {
      return null;
    }

    return CloudNote(
      documentId: documentId,
      ownerUserId: ownerUserId,
      text: text,
      createdAt: createdAt,
    );
  }

  /// Returns null when [createdAtFieldName] holds a value that cannot be
  /// interpreted as a date, so one corrupt document cannot tear down the
  /// snapshot stream for every other note.
  static DateTime? _tryParseCreatedAt(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
