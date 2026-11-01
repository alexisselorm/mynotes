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

  void createNewNote({
    required String ownerUserId,
    required String text,
  }) async {
    try {
      await notes.add({
        ownerUserIdFieldName: ownerUserId,
        textFieldName: text,
        createdAtFieldName: DateTime.now().toIso8601String(),
      });
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
        createdAtFieldName: DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw CouldNotUpdateNoteException();
    }
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
              (doc) => CloudNote.fromSnapshot(
                snapshot: doc.data(),
                documentId: doc.id,
              ),
            )
            .where((note) => note.ownerUserId == ownerUserId),
      );

  Future<Iterable<CloudNote>> getNotes({required String ownerUserId}) async =>
      await notes
          .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
          .get()
          .then(
            (snapshot) => snapshot.docs.map(
              (doc) => CloudNote(
                ownerUserId: doc.data()[ownerUserIdFieldName] as String,
                text: doc.data()[textFieldName] as String,
                createdAt: DateTime.parse(
                  doc.data()[createdAtFieldName] as String,
                ),
                documentId: doc.id,
              ),
            ),
          );
}
