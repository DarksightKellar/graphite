import 'package:flutter/material.dart';

/// Search bar used on the HomeScreen.
class HomeSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const HomeSearchBar({
    super.key,
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search notes',
          hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6)),
          prefixIcon: Icon(Icons.search, color: scheme.onSurface.withValues(alpha: 0.6)),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: scheme.onSurface.withValues(alpha: 0.6)),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: scheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
