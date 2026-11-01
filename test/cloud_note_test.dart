import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/cloud_storage_constants.dart';

void main() {
  group('CloudNote.fromSnapshot', () {
    test('parses createdAt stored as an ISO-8601 string', () {
      final note = CloudNote.fromSnapshot(
        snapshot: {
          ownerUserIdFieldName: 'user-1',
          textFieldName: 'hello',
          createdAtFieldName: '2026-11-01T10:30:00.000',
        },
        documentId: 'doc-1',
      );

      expect(note.createdAt, DateTime.parse('2026-11-01T10:30:00.000'));
      expect(note.ownerUserId, 'user-1');
      expect(note.text, 'hello');
    });

    test('parses createdAt stored as a Firestore Timestamp', () {
      final date = DateTime.utc(2026, 11, 1, 10, 30);

      final note = CloudNote.fromSnapshot(
        snapshot: {
          ownerUserIdFieldName: 'user-1',
          textFieldName: 'hello',
          createdAtFieldName: Timestamp.fromDate(date),
        },
        documentId: 'doc-1',
      );

      expect(note.createdAt.isAtSameMomentAs(date), isTrue);
    });

    test('throws FormatException for unsupported createdAt values', () {
      expect(
        () => CloudNote.fromSnapshot(
          snapshot: {
            ownerUserIdFieldName: 'user-1',
            textFieldName: 'hello',
            createdAtFieldName: 12345,
          },
          documentId: 'doc-1',
        ),
        throwsFormatException,
      );
    });
  });

  group('CloudNote.tryFromSnapshot', () {
    test('parses valid documents', () {
      final note = CloudNote.tryFromSnapshot(
        snapshot: {
          ownerUserIdFieldName: 'user-1',
          textFieldName: 'hello',
          createdAtFieldName: '2026-11-01T10:30:00.000',
        },
        documentId: 'doc-1',
      );

      expect(note, isNotNull);
      expect(note!.documentId, 'doc-1');
      expect(note.text, 'hello');
    });

    test('returns null for an unparseable date string', () {
      final note = CloudNote.tryFromSnapshot(
        snapshot: {
          ownerUserIdFieldName: 'user-1',
          textFieldName: 'hello',
          createdAtFieldName: 'not-a-date',
        },
        documentId: 'doc-1',
      );

      expect(note, isNull);
    });

    test('returns null for a non-string, non-timestamp date', () {
      final note = CloudNote.tryFromSnapshot(
        snapshot: {
          ownerUserIdFieldName: 'user-1',
          textFieldName: 'hello',
          createdAtFieldName: 12345,
        },
        documentId: 'doc-1',
      );

      expect(note, isNull);
    });

    test('returns null when required fields are missing', () {
      final note = CloudNote.tryFromSnapshot(
        snapshot: {textFieldName: 'hello'},
        documentId: 'doc-1',
      );

      expect(note, isNull);
    });
  });
}
