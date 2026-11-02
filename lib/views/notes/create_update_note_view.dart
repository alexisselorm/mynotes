import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/theme/app_typography.dart';
import 'package:mynotes/utilities/dialogs/cannot_share_empty_note_dialog.dart';
import 'package:mynotes/utilities/generics/get_arguments.dart';
import 'package:mynotes/views/notes/widgets/note_card.dart';
import 'package:mynotes/widgets/app_background.dart';
import 'package:mynotes/widgets/entrance.dart';
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
  final _focusNode = FocusNode();

  Future<CloudNote>? _noteFuture;
  bool _disposed = false;

  /// Whether the local text differs from what has been confirmed written to
  /// Firestore. Drives the "Saving / Saved" indicator.
  bool _saving = false;
  Timer? _savedTimer;

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
    _savedTimer?.cancel();
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _textControllerListener() async {
    final note = _note;
    if (note == null) {
      // The note itself is created lazily on the first keystroke; make sure it
      // exists before any text is written to it.
      _noteFuture ??= _createOrGetNote(context);
      final created = await _noteFuture;
      if (created != null && _note == null) _note = created;
      return;
    }
    final text = _textController.text;
    _markSaving();
    try {
      await _notesService.updateNote(documentId: note.documentId, text: text);
      _markSaved();
    } catch (_) {
      // Offline or the note was deleted underneath us; the pop-time save is
      // the final word.
    }
  }

  void _markSaving() {
    if (!mounted) return;
    _savedTimer?.cancel();
    if (!_saving) setState(() => _saving = true);
  }

  void _markSaved() {
    if (!mounted) return;
    _savedTimer?.cancel();
    _savedTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _saving = false);
    });
  }

  void _setupTextControllerListener() {
    _textController.removeListener(_textControllerListener);
    _textController.addListener(_textControllerListener);
  }

  WordCount get _count => WordCount.of(_textController.text);

  Future<void> _share() async {
    final text = _textController.text;
    if (text.isEmpty) {
      await showCannotShareEmptyNoteDialog(context);
    } else {
      Share.share(text);
    }
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
        body: AppBackground(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  children: [
                    _EditorBar(
                      textController: _textController,
                      saving: _saving,
                      onBack: () => Navigator.of(context).maybePop(),
                      onShare: _share,
                      onDelete: () async {
                        final note = _note;
                        if (note == null) return;
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Delete this note?'),
                            content: const Text(
                              'This cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(true),
                                child: Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        if (!context.mounted) return;
                        final navigator = Navigator.of(context);
                        _textController.clear();
                        await _notesService.deleteNote(
                          documentId: note.documentId,
                        );
                        navigator.pop();
                      },
                    ),
                    Expanded(
                      child: FutureBuilder(
                        future: _noteFuture ??= _createOrGetNote(context),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text('Could not open the note.'),
                            );
                          }
                          switch (snapshot.connectionState) {
                            case ConnectionState.done:
                              _setupTextControllerListener();
                              return _EditorBody(
                                controller: _textController,
                                focusNode: _focusNode,
                                createdAt: _note?.createdAt,
                                wordCount: _count,
                              );
                            default:
                              return Center(
                                child: SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorBar extends StatelessWidget {
  const _EditorBar({
    required this.textController,
    required this.saving,
    required this.onBack,
    required this.onShare,
    required this.onDelete,
  });

  final TextEditingController textController;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 14),
      child: Row(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ],
          ),
          const SizedBox(width: 2),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: saving
                ? Row(
                    key: const ValueKey('saving'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 11,
                        height: 11,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Saving',
                        style: AppType.style(
                          scheme.onSurfaceVariant,
                          12.5,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : Row(
                    key: const ValueKey('saved'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_done_outlined,
                        size: 15,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Saved',
                        style: AppType.style(
                          scheme.onSurfaceVariant,
                          12.5,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Delete note',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
          IconButton(
            tooltip: 'Share note',
            onPressed: onShare,
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
    );
  }
}

class _EditorBody extends StatefulWidget {
  const _EditorBody({
    required this.controller,
    required this.focusNode,
    required this.createdAt,
    required this.wordCount,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final DateTime? createdAt;
  final WordCount wordCount;

  @override
  State<_EditorBody> createState() => _EditorBodyState();
}

class _EditorBodyState extends State<_EditorBody> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final empty = widget.controller.text.isEmpty;

    return Entrance(
      offset: const Offset(0, 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? scheme.surfaceContainer : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            border: Border.all(color: scheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Stack(
                    children: [
                      if (empty)
                        IgnorePointer(
                          child: Text(
                            'Start typing your note…',
                            style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 24,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                        ),
                      TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        autofocus: empty,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        cursorColor: scheme.primary,
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 20,
                          height: 1.65,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.1,
                          color: scheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _EditorFooter(
                words: widget.wordCount.words,
                characters: widget.wordCount.characters,
                createdAt: widget.createdAt,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorFooter extends StatelessWidget {
  const _EditorFooter({
    required this.words,
    required this.characters,
    required this.createdAt,
  });

  final int words;
  final int characters;
  final DateTime? createdAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final meta = [
      '$words ${words == 1 ? 'word' : 'words'}',
      '$characters ${characters == 1 ? 'character' : 'characters'}',
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: Row(
        children: [
          if (createdAt != null) ...[
            Icon(
              Icons.event_note_outlined,
              size: 14,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              formatNoteStamp(createdAt!),
              style: AppType.style(scheme.onSurfaceVariant, 12),
            ),
            const SizedBox(width: 14),
          ],
          const Spacer(),
          Text(
            meta.join('  ·  '),
            style: AppType.style(
              scheme.onSurfaceVariant,
              12,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Words and characters in a note, counted once per build.
class WordCount {
  const WordCount({required this.words, required this.characters});

  final int words;
  final int characters;

  static WordCount of(String text) {
    final trimmed = text.trim();
    final words = trimmed.isEmpty
        ? 0
        : trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    return WordCount(words: words, characters: text.runes.length);
  }
}
