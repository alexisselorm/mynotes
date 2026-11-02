import 'package:flutter/material.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/theme/app_colors.dart';
import 'package:mynotes/theme/app_typography.dart';
import 'package:mynotes/widgets/press_scale.dart';

/// A note in the grid. The first line is treated as the title (wider serif);
/// the rest previews as body copy. Notes are read in an "adapted" pass that
/// strips the line break after the title if there is one.
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.accent,
    required this.onTap,
    required this.onLongPress,
  });

  final CloudNote note;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (title, body) = _split(note.text);

    return PressScale(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkLine : AppColors.lightLine,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.035),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // A slim accent rule on the left edge, tinted per note, that
              // gives a stack of white cards a little rhythm.
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 3, color: accent),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isEmpty)
                      Text(
                        'Empty note',
                        style: AppType.style(
                          scheme.onSurfaceVariant,
                          15,
                          weight: FontWeight.w500,
                        ).copyWith(fontStyle: FontStyle.italic),
                      )
                    else
                      Text(
                        title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 19,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: scheme.onSurface,
                        ),
                      ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        body,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.style(
                          scheme.onSurfaceVariant,
                          13.5,
                          height: 1.55,
                        ),
                      ),
                    ],
                    const Spacer(),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          formatNoteStamp(note.createdAt),
                          style: AppType.style(
                            scheme.onSurfaceVariant,
                            11.5,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static (String, String) _split(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return ('', '');
    final newline = trimmed.indexOf('\n');
    if (newline == -1) return (trimmed, '');
    final title = trimmed.substring(0, newline).trim();
    final body = trimmed.substring(newline + 1).trim();
    return (title, body);
  }
}

/// Compact, human date label: "Today, 14:32", "Yesterday", "12 Mar" or
/// "12 Mar 2023" for older notes.
String formatNoteStamp(DateTime date) {
  final now = DateTime.now();
  final local = date.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final difference = today.difference(day).inDays;
  final time =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';

  if (difference == 0) return 'Today, $time';
  if (difference == 1) return 'Yesterday';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final month = months[local.month - 1];
  if (local.year == now.year) return '${local.day} $month';
  return '${local.day} $month ${local.year}';
}

/// Stable-ish accent colour for a note, picked from a small set of muted hues
/// keyed by document id so the same note keeps its colour across rebuilds.
const _accents = [
  Color(0xFF7FB29A),
  Color(0xFFC9B37E),
  Color(0xFF9AA7C7),
  Color(0xFFC7A2A2),
  Color(0xFFA8BE8C),
  Color(0xFFB7A5C6),
];

Color noteAccent(String id) {
  var hash = 0;
  for (final unit in id.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return _accents[hash % _accents.length];
}
