import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'crud_exceptions.dart';

class NotesService {
  static final NotesService _shared = NotesService._sharedInstance();
  NotesService._sharedInstance();
  factory NotesService() => _shared;

  Database? _db;

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

    return DatabaseNotes(
      id: note.id,
      text: text,
      userId: note.userId,
      isSyncedWithCloud: note.isSyncedWithCloud,
      createdAt: note.createdAt,
    );
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

  Future<void> deleteAllNotes() async {
    final db = _getDatabaseOrThrow();
    await db.delete(notesTable);
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
    }
  }

  Future<DatabaseNotes> createNote({
    required DatabaseUser owner,
    required String text,
  }) async {
    final db = _getDatabaseOrThrow();
    final dbUser = await getUser(email: owner.email);

    if (dbUser.id != owner.id) {
      throw CouldNotFindUserException();
    }

    final noteId = await db.insert(notesTable, {
      textColumn: text,
      userIdColumn: owner.id,
      isSyncedWithCloudColumn: 0,
      createdAtColumn: DateTime.now().toIso8601String(),
    });

    return DatabaseNotes(
      id: noteId,
      text: text,
      userId: owner.id,
      isSyncedWithCloud: false,
      createdAt: DateTime.now(),
    );
  }

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
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentDirectoryException();
    } on DatabaseAlreadyOpenException {
      rethrow;
    } catch (_) {
      _db = null;
      throw DatabaseIsNotOpenException();
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpenException();
    } else {
      await db.close();
      _db = null;
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
