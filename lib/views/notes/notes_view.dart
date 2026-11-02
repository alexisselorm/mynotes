import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/enums/menu_action.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/theme/app_typography.dart';
import 'package:mynotes/utilities/dialogs/delete_dialog.dart';
import 'package:mynotes/utilities/dialogs/logout_dialog.dart';
import 'package:mynotes/views/notes/widgets/note_card.dart';
import 'package:mynotes/widgets/app_background.dart';
import 'package:mynotes/widgets/brand_mark.dart';
import 'package:mynotes/widgets/entrance.dart';
import 'package:mynotes/widgets/press_scale.dart';

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  late final FirebaseCloudStorage _notesService;
  final _searchController = TextEditingController();
  String _query = '';

  String get userId => AuthService.firebase().currentUser!.id;

  @override
  void initState() {
    _notesService = FirebaseCloudStorage();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEditor({CloudNote? note}) {
    Navigator.of(context).pushNamed(createUpdateNoteRoute, arguments: note);
  }

  Future<void> _confirmDelete(CloudNote note) async {
    final shouldDelete = await showDeleteDialog(context);
    if (shouldDelete) {
      await _notesService.deleteNote(documentId: note.documentId);
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showLogoutDialog(context);
    if (shouldLogout && mounted) {
      context.read<AuthBloc>().add(const AuthEventLogOut());
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.firebase().currentUser;
    final email = user?.email ?? '';
    final greeting = _greeting();

    return Scaffold(
      floatingActionButton: _NewNoteButton(onPressed: () => _openEditor()),
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<Iterable<CloudNote>>(
            stream: _notesService.allNotes(ownerUserId: userId),
            builder: (context, snapshot) {
              final loaded = snapshot.hasData;
              final allNotes = (snapshot.data ?? const <CloudNote>[])
                  .toList(growable: false);

              return LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 720;
                  final columns = constraints.maxWidth >= 1180
                      ? 4
                      : constraints.maxWidth >= 900
                      ? 3
                      : constraints.maxWidth >= 600
                      ? 2
                      : 1;
                  final filtered = _query.isEmpty
                      ? allNotes
                      : allNotes
                            .where(
                              (n) => n.text.toLowerCase().contains(
                                _query.toLowerCase(),
                              ),
                            )
                            .toList(growable: false);

                  return RefreshIndicator(
                    color: Theme.of(context).colorScheme.primary,
                    onRefresh: () async {
                      setState(() {});
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _Header(
                            greeting: greeting,
                            email: email,
                            count: allNotes.length,
                            wide: wide,
                            onLogout: _confirmLogout,
                          ),
                        ),
                        if (allNotes.length > 2)
                          SliverToBoxAdapter(
                            child: _SearchBar(
                              controller: _searchController,
                              onChanged: (v) => setState(() => _query = v),
                            ),
                          ),
                        if (!loaded)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: _LoadingNotes()),
                          )
                        else if (snapshot.hasError)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _Message(
                              icon: Icons.cloud_off_outlined,
                              title: 'Could not reach your notes',
                              body: '${snapshot.error}',
                            ),
                          )
                        else if (allNotes.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyState(
                              onCreate: () => _openEditor(),
                            ),
                          )
                        else if (filtered.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: const _Message(
                              icon: Icons.search_off_rounded,
                              title: 'No matches',
                              body: 'No note contains those words yet.',
                            ),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              4,
                              20,
                              wide ? 40 : 120,
                            ),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    mainAxisExtent:
                                        columns == 1 || columns == 2 ? 186 : 200,
                                  ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final note = filtered[index];
                                  return Entrance(
                                    key: ValueKey(note.documentId),
                                    delay: Duration(
                                      milliseconds: (index.clamp(0, 8) * 45),
                                    ),
                                    duration: const Duration(milliseconds: 380),
                                    offset: const Offset(0, 12),
                                    child: NoteCard(
                                      note: note,
                                      accent: noteAccent(note.documentId),
                                      onTap: () => _openEditor(note: note),
                                      onLongPress: () => _confirmDelete(note),
                                    ),
                                  );
                                },
                                childCount: filtered.length,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Working late';
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.email,
    required this.count,
    required this.wide,
    required this.onLogout,
  });

  final String greeting;
  final String email;
  final int count;
  final bool wide;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = email.split('@').first;
    final displayName = name.isEmpty
        ? 'there'
        : name[0].toUpperCase() + name.substring(1);
    final word = count == 1 ? 'note' : 'notes';

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting.toUpperCase(),
          style: AppType.overline(scheme.primary),
        ),
        const SizedBox(height: 6),
        Text(
          'Hello, $displayName',
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: wide ? 38 : 32,
            height: 1.1,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.6,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          count == 0
              ? 'Your notebook is waiting for its first line.'
              : '$count $word in your notebook',
          style: AppType.style(scheme.onSurfaceVariant, 14),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (wide) ...[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: BrandMark(size: 26, color: scheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(child: title),
          _AccountButton(email: email, onLogout: onLogout),
        ],
      ),
    );
  }
}

/// Avatar menu on the right of the header; signs out via the shared dialog.
class _AccountButton extends StatelessWidget {
  const _AccountButton({required this.email, required this.onLogout});

  final String email;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = email.split('@').first;
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return PopupMenuButton<MenuAction>(
      onSelected: (value) {
        if (value == MenuAction.logout) onLogout();
        if (value == MenuAction.settings) {
          Navigator.of(context).pushNamed(settingsRoute);
        }
      },
      offset: const Offset(0, 52),
      tooltip: 'Account',
      itemBuilder: (context) => [
        PopupMenuItem<MenuAction>(
          enabled: false,
          child: Text(
            email,
            style: AppType.style(scheme.onSurfaceVariant, 12.5),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<MenuAction>(
          value: MenuAction.settings,
          child: Row(
            children: [
              Icon(Icons.tune_rounded, size: 18),
              SizedBox(width: 10),
              Text('Settings'),
            ],
          ),
        ),
        const PopupMenuItem<MenuAction>(
          value: MenuAction.logout,
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18),
              SizedBox(width: 10),
              Text('Sign out'),
            ],
          ),
        ),
      ],
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.onSurface,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.outline),
        ),
        child: Text(
          initial,
          style: AppType.style(
            scheme.surface,
            16,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          return TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            style: AppType.style(scheme.onSurface, 14.5),
            decoration: InputDecoration(
              hintText: 'Search your notes',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: 'Clear search',
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _NewNoteButton extends StatelessWidget {
  const _NewNoteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF7FC99A) : const Color(0xFF1F5C39);
    final fg = isDark ? const Color(0xFF101411) : Colors.white;
    return PressScale(
      onTap: onPressed,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: bg.withValues(alpha: 0.32),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: fg, size: 22),
            const SizedBox(width: 8),
            Text(
              'New note',
              style: AppType.style(fg, 15, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 90),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Entrance(
                child: Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    Icons.edit_note_rounded,
                    size: 46,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Entrance(
                delay: const Duration(milliseconds: 90),
                child: Text(
                  'A blank page',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Entrance(
                delay: const Duration(milliseconds: 160),
                child: Text(
                  'Start with a thought, a list, or a single line. '
                  'It saves as you type.',
                  textAlign: TextAlign.center,
                  style: AppType.style(
                    scheme.onSurfaceVariant,
                    14.5,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Entrance(
                delay: const Duration(milliseconds: 230),
                child: TextButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Write your first note'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 90),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: scheme.onSurfaceVariant),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppType.style(scheme.onSurfaceVariant, 13.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingNotes extends StatelessWidget {
  const _LoadingNotes();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 26,
      child: CircularProgressIndicator(
        strokeWidth: 2.2,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
