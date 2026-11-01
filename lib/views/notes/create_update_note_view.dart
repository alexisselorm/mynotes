import 'package:flutter/material.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/utilities/dialogs/cannot_share_empty_note_dialog.dart';
import 'package:mynotes/utilities/generics/get_arguments.dart';
import 'package:share_plus/share_plus.dart';

class CreateUpdateNoteView extends StatefulWidget {
  const CreateUpdateNoteView({super.key});

  @override
  State<CreateUpdateNoteView> createState() => _CreateUpdateNoteViewState();
}

class _CreateUpdateNoteViewState extends State<CreateUpdateNoteView> {
  CloudNote? _note;

  late final FirebaseCloudStorage _notesService;
  late final TextEditingController _textController;

  Future<CloudNote>? _noteFuture;
  bool _disposed = false;

  Future<CloudNote> createNewNote() {
    if (_disposed) {
      throw StateError('Cannot create a note after the view is disposed.');
    }
    return _noteFuture ??= _createOrGetNote(context);
  }

  Future<CloudNote> _createOrGetNote(BuildContext context) async {
    final widgetNote = context.getArgument<CloudNote>();

    if (widgetNote != null) {
      _note = widgetNote;
      _textController.text = widgetNote.text;
      return widgetNote;
    }

    final existingNote = _note;
    if (existingNote != null) {
      return existingNote;
    }
    final currentUser = AuthService.firebase().currentUser;
    final email = currentUser!.id;
    final newNote = await _notesService.createNewNote(
      ownerUserId: email,
      text: _textController.text,
    );
    _note = newNote;
    return newNote;
  }

  @override
  void initState() {
    _notesService = FirebaseCloudStorage();
    _textController = TextEditingController();
    super.initState();
  }

  Future<void> _deleteNoteIfTextIsEmpty() async {
    final note = _note;
    if (_textController.text.isEmpty && note != null) {
      await _notesService.deleteNote(documentId: note.documentId);
    }
  }

  Future<void> _saveNoteIfTextNotEmpty() async {
    final note = _note;
    if (_textController.text.isNotEmpty && note != null) {
      await _notesService.updateNote(
        documentId: note.documentId,
        text: _textController.text,
      );
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
    await _notesService.updateNote(documentId: note.documentId, text: text);
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
        appBar: AppBar(
          title: const Text('New Note'),
          actions: [
            IconButton(
              onPressed: () async {
                final text = _textController.text;
                if (text.isEmpty) {
                  await showCannotShareEmptyNoteDialog(context);
                } else {
                  Share.share(text);
                }
              },
              icon: const Icon(Icons.share),
            ),
          ],
        ),
        body: Center(
          child: FutureBuilder(
            future: _noteFuture ??= _createOrGetNote(context),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Could not open the note.'));
              }
              switch (snapshot.connectionState) {
                case ConnectionState.done:
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
