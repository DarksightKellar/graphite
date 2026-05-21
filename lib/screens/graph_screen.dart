import 'package:flutter/material.dart';

/// TODO(post-MVP): Interactive graph with node/edge navigation.
/// Feature-gated out of MVP scope — kept as a placeholder.
/// Re-enable by adding the /graph route back to app_router.dart and
/// implementing the full interactive graph canvas.
class GraphScreen extends StatelessWidget {
  const GraphScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graph'),
      ),
      body: const Center(
        child: Text(
          'Knowledge Graph — Coming Soon',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }
}
