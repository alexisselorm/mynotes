import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mynotes/theme/app_typography.dart';

/// A labelled text field. The label sits above the field as quiet small caps
/// rather than floating inside it, which keeps the sheet inside unfussy.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.onSubmitted,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool enableSuggestions;
  final bool autocorrect;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            widget.label.toUpperCase(),
            style: AppType.overline(scheme.onSurfaceVariant),
          ),
        ),
        TextField(
          controller: widget.controller,
          obscureText: _hidden,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          enableSuggestions: widget.enableSuggestions && !widget.obscure,
          autocorrect: widget.autocorrect && !widget.obscure,
          onSubmitted: widget.onSubmitted,
          inputFormatters: widget.inputFormatters,
          style: AppType.style(scheme.onSurface, 15.5),
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixIcon: widget.obscure
                ? IconButton(
                    onPressed: () => setState(() => _hidden = !_hidden),
                    tooltip: _hidden ? 'Show password' : 'Hide password',
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
