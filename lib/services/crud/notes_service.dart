import 'dart:async';

import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'crud_exceptions.dart';

class NotesService {
  static final NotesService _shared = NotesService._sharedInstance();
  NotesService._sharedInstance();
  factory NotesService() => _shared;

  Stream<List<DatabaseNotes>> get allNotes => _noteStreamController.stream;

  Database? _db;
  List<DatabaseNotes> _notes = [];

  final _noteStreamController =
      StreamController<List<DatabaseNotes>>.broadcast();

  Future<DatabaseUser> getOrCreateUser({required String email}) async {
    try {
      return await getUser(email: email);
    } on CouldNotFindUserException {
      return await createUser(email: email);
    }
  }

  /// Reads all notes from the database and pushes them to [allNotes].
  Future<void> cacheNotes() async {
    _notes = (await getAllNotes()).toList();
    _emitNotes();
  }

  Future<DatabaseNotes> updateNote({
    required DatabaseNotes note,
    required String text,
  }) async {
    final db = _getDatabaseOrThrow();

    // Throws CouldNotFindNoteException if the note doesn't exist.
    await getNote(id: note.id);

    // Update the note
    final updatedCount = await db.update(
      notesTable,
      {textColumn: text},
      where: '$idColumn = ?',
      whereArgs: [note.id],
    );

    if (updatedCount != 1) {
      throw CouldNotUpdateNoteException();
    }
    _notes.removeWhere((n) => n.id == note.id);
    final updatedNote = DatabaseNotes(
      id: note.id,
      text: text,
      userId: note.userId,
      isSyncedWithCloud: note.isSyncedWithCloud,
      createdAt: note.createdAt,
    );
    _notes.add(updatedNote);
    _emitNotes();
    return updatedNote;
  }

  Future<Iterable<DatabaseNotes>> getAllNotes() async {
    final db = _getDatabaseOrThrow();
    final results = await db.query(notesTable, orderBy: createdAtColumn);
    return results.map(DatabaseNotes.fromRow);
  }

  Future<DatabaseNotes> getNote({required int id}) async {
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      notesTable,
      limit: 1,
      where: '$idColumn = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) {
      throw CouldNotFindNoteException();
    } else {
      return DatabaseNotes.fromRow(results.first);
    }
  }

  Future<int> deleteAllNotes() async {
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(notesTable);
    _notes.clear();
    _emitNotes();
    return deletedCount;
  }

  Future<void> deleteNote({required int id}) async {
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      notesTable,
      where: '$idColumn = ?',
      whereArgs: [id],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteNoteException();
    } else {
      _notes.removeWhere((note) => note.id == id);
      _emitNotes();
    }
  }

  Future<DatabaseNotes> createNote({
    required DatabaseUser owner,
    required String text,
  }) async {
    final db = _getDatabaseOrThrow();
    final dbUser = await getOrCreateUser(email: owner.email);

    if (dbUser.id != owner.id) {
      throw CouldNotFindUserException();
    }

    final createdAt = DateTime.now();
    final noteId = await db.insert(notesTable, {
      textColumn: text,
      userIdColumn: owner.id,
      isSyncedWithCloudColumn: 0,
      createdAtColumn: createdAt.toIso8601String(),
    });

    final note = DatabaseNotes(
      id: noteId,
      text: text,
      userId: owner.id,
      isSyncedWithCloud: false,
      createdAt: createdAt,
    );
    _notes.add(note);
    _emitNotes();
    return note;
  }

  void _emitNotes() => _noteStreamController.add(List.of(_notes));

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpenException();
    } else {
      return db;
    }
  }

  Future<DatabaseUser> getUser({required String email}) async {
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      usersTable,
      limit: 1,
      where: '$emailColumn = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isEmpty) {
      throw CouldNotFindUserException();
    } else {
      return DatabaseUser.fromRow(results.first);
    }
  }

  Future<DatabaseUser> createUser({required String email}) async {
    final db = _getDatabaseOrThrow();
    final normalizedEmail = email.toLowerCase();
    final results = await db.query(
      usersTable,
      limit: 1,
      where: '$emailColumn = ?',
      whereArgs: [normalizedEmail],
    );
    if (results.isNotEmpty) {
      throw UserAlreadyExistsException();
    }

    final createdUser = await db.insert(usersTable, {
      emailColumn: normalizedEmail,
    });

    return DatabaseUser(id: createdUser, email: normalizedEmail);
  }

  Future<void> deleteUser({required String email}) async {
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      usersTable,
      where: '$emailColumn = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteUserException();
    }
  }

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;

      const createUserTable =
          '''
        CREATE TABLE IF NOT EXISTS $usersTable (
          $idColumn INTEGER PRIMARY KEY AUTOINCREMENT,
          $emailColumn TEXT NOT NULL
        );
      ''';

      const createNotesTable =
          '''
        CREATE TABLE IF NOT EXISTS $notesTable (
          $idColumn INTEGER PRIMARY KEY AUTOINCREMENT,
          $textColumn TEXT NOT NULL,
          $userIdColumn INTEGER NOT NULL,
          $isSyncedWithCloudColumn INTEGER NOT NULL DEFAULT 0,
          $createdAtColumn TEXT NOT NULL,
          FOREIGN KEY ($userIdColumn) REFERENCES $usersTable($idColumn)
        );
      ''';

      await db.execute(createUserTable);
      await db.execute(createNotesTable);
      await cacheNotes();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentDirectoryException();
    } catch (_) {
      await _db?.close();
      _db = null;
      rethrow;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpenException();
    } else {
      await db.close();
      _db = null;
      _notes = [];
      _emitNotes();
    }
  }
}

class DatabaseUser {
  final int id;
  final String email;

  DatabaseUser({required this.id, required this.email});

  DatabaseUser.fromRow(Map<String, Object?> map)
    : id = map[idColumn] as int,
      email = map[emailColumn] as String;

  @override
  String toString() => 'User, ID = $id, email = $email';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is DatabaseUser && id == other.id);

  @override
  int get hashCode => id.hashCode;
}

class DatabaseNotes {
  final int id;
  final String text;
  final int userId;
  final bool isSyncedWithCloud;
  final DateTime createdAt;

  const DatabaseNotes({
    required this.id,
    required this.text,
    required this.userId,
    required this.isSyncedWithCloud,
    required this.createdAt,
  });

  DatabaseNotes.fromRow(Map<String, Object?> map)
    : id = map[idColumn] as int,
      text = map[textColumn] as String,
      userId = map[userIdColumn] as int,
      isSyncedWithCloud = (map[isSyncedWithCloudColumn] as int) == 1,
      createdAt = DateTime.parse(map[createdAtColumn] as String);

  @override
  String toString() =>
      'Note, ID = $id, text = $text, userId = $userId, '
      'isSyncedWithCloud = $isSyncedWithCloud, createdAt = $createdAt';
}

// User
const idColumn = 'id';
const emailColumn = 'email';

// Notes
const textColumn = 'text';
const userIdColumn = 'user_id';
const isSyncedWithCloudColumn = 'is_synced_with_cloud';
const createdAtColumn = 'created_at';

const dbName = 'my_notes.db';
const notesTable = 'notes';
const usersTable = 'users';
