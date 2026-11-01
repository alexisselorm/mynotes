import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/cloud_storage_constants.dart';
import 'package:mynotes/services/cloud/cloud_storage_exceptions.dart';

class FirebaseCloudStorage {
  final notes = FirebaseFirestore.instance.collection('notes');

  static final FirebaseCloudStorage _shared =
      FirebaseCloudStorage._sharedInstance();

  FirebaseCloudStorage._sharedInstance();
  factory FirebaseCloudStorage() => _shared;

  Future<CloudNote> createNewNote({
    required String ownerUserId,
    required String text,
  }) async {
    try {
      final document = await notes.add({
        ownerUserIdFieldName: ownerUserId,
        textFieldName: text,
        createdAtFieldName: FieldValue.serverTimestamp(),
      });
      final fetchedNote = await document.get();
      return CloudNote.fromSnapshot(
        snapshot: fetchedNote.data() as Map<String, dynamic>,
        documentId: fetchedNote.id,
      );
    } catch (e) {
      throw CouldNotCreateNoteException();
    }
  }

  Future<void> updateNote({
    required String documentId,
    required String text,
  }) async {
    try {
      await notes.doc(documentId).update({
        textFieldName: text,
        createdAtFieldName: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw CouldNotUpdateNoteException();
    }
  }

  /// Rewrites any note whose [createdAtFieldName] is stored as an ISO-8601
  /// string into a Firestore [Timestamp].
  ///
  /// Older app builds and documents created from the Firebase console stored
  /// this field as a string, which made date-range queries impossible and
  /// crashed parsing. Returns the number of documents migrated.
  Future<int> migrateCreatedAtToTimestamp() async {
    final snapshot = await notes.get();
    final batch = FirebaseFirestore.instance.batch();
    var migrated = 0;

    for (final doc in snapshot.docs) {
      final value = doc.data()[createdAtFieldName];
      if (value is String) {
        final parsed = DateTime.parse(value);
        batch.update(doc.reference, {createdAtFieldName: Timestamp.fromDate(parsed)});
        migrated++;
      }
    }

    if (migrated > 0) {
      await batch.commit();
    }
    return migrated;
  }

  Future<void> deleteNote({required String documentId}) async {
    try {
      await notes.doc(documentId).delete();
    } catch (e) {
      throw CouldNotDeleteNoteException();
    }
  }

  Stream<Iterable<CloudNote>> allNotes({required String ownerUserId}) =>
      notes.snapshots().map(
        (event) => event.docs
            .map(
              (doc) => CloudNote.tryFromSnapshot(
                snapshot: doc.data(),
                documentId: doc.id,
              ),
            )
            .nonNulls
            .where((note) => note.ownerUserId == ownerUserId),
      );

  Future<Iterable<CloudNote>> getNotes({required String ownerUserId}) async =>
      await notes
          .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
          .get()
          .then(
            (snapshot) => snapshot.docs
                .map(
                  (doc) => CloudNote.tryFromSnapshot(
                    snapshot: doc.data(),
                    documentId: doc.id,
                  ),
                )
                .nonNulls,
          );
}
