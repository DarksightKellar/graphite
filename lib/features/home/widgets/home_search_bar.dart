import 'package:flutter/material.dart';

import 'package:graphite/core/design/components/graphite_search_field.dart';
import 'package:graphite/core/design/spacing.dart';

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GraphiteSpacing.pageInset,
        GraphiteSpacing.lg,
        GraphiteSpacing.pageInset,
        GraphiteSpacing.lg,
      ),
      child: GraphiteSearchField(
        controller: controller,
        query: query,
        onChanged: onChanged,
        onClear: onClear,
      ),
    );
  }
}
