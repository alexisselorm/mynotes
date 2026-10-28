import 'package:flutter/material.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/crud/notes_service.dart';

class NewNoteView extends StatefulWidget {
  const NewNoteView({super.key});

  @override
  State<NewNoteView> createState() => _NewNoteViewState();
}

class _NewNoteViewState extends State<NewNoteView> {
  DatabaseNotes? _note;

  late final NotesService _notesService;
  late final TextEditingController _textController;

  Future<DatabaseNotes>? _noteFuture;
  bool _disposed = false;

  Future<DatabaseNotes> createNewNote() {
    if (_disposed) {
      throw StateError('Cannot create a note after the view is disposed.');
    }
    return _noteFuture ??= _createOrGetNote();
  }

  Future<DatabaseNotes> _createOrGetNote() async {
    final existingNote = _note;
    if (existingNote != null) {
      return existingNote;
    }
    final currentUser = AuthService.firebase().currentUser;
    final email = currentUser!.email;
    final owner = await _notesService.getUser(email: email);
    final newNote = await _notesService.createNote(
      owner: owner,
      text: _textController.text,
    );
    _note = newNote;
    return newNote;
  }

  @override
  void initState() {
    _notesService = NotesService();
    _textController = TextEditingController();
    super.initState();
  }

  Future<void> _deleteNoteIfTextIsEmpty() async {
    final note = _note;
    if (_textController.text.isEmpty && note != null) {
      await _notesService.deleteNote(id: note.id);
    }
  }

  Future<void> _saveNoteIfTextNotEmpty() async {
    final note = _note;
    if (_textController.text.isNotEmpty && note != null) {
      await _notesService.updateNote(note: note, text: _textController.text);
    }
  }

  /// Deletes the note when it was left empty, otherwise saves the latest text.
  /// Must complete before the view is popped, since the service is shared with
  /// the notes list and must not be closed while still in use.
  Future<void> _persistNote() async {
    _textController.removeListener(_textControllerListener);
    try {
      await _deleteNoteIfTextIsEmpty();
      await _saveNoteIfTextNotEmpty();
    } catch (_) {
      // The note may already be gone (e.g. deleted from the list); nothing
      // left to persist in that case.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _textController.dispose();
    super.dispose();
  }

  void _textControllerListener() async {
    final note = _note;
    if (note == null) {
      return;
    }
    final text = _textController.text;
    await _notesService.updateNote(note: note, text: text);
  }

  void _setupTextControllerListener() {
    _textController.removeListener(_textControllerListener);
    _textController.addListener(_textControllerListener);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        await _persistNote();
        if (!mounted) return;
        navigator.pop(result);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('New Note')),
        body: Center(
          child: FutureBuilder(
            future: _noteFuture ??= _createOrGetNote(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Could not open the note.'));
              }
              switch (snapshot.connectionState) {
                case ConnectionState.done:
                  _note = snapshot.data as DatabaseNotes;
                  _setupTextControllerListener();
                  return TextField(
                    controller: _textController,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Start typing your note...',
                    ),
                  );
                default:
                  return const CircularProgressIndicator();
              }
            },
          ),
        ),
      ),
    );
  }
}
