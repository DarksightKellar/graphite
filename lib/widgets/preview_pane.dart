import 'package:flutter/material.dart';

/// Renders markdown content in a modern, readable format.
class PreviewPane extends StatelessWidget {
  const PreviewPane({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F6FA), // subtle off-white for reading
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlaceholder(context),
            
            const SizedBox(height: 24),

            // Heading placeholder (H1)
            Text(
              '# Heading',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            
            const SizedBox(height: 16),

            // Paragraph placeholder
            Text(
              'This is a paragraph. Graphite uses clean, modern typography for reading comfort.',
              style: TextStyle(color: Colors.grey[700], height: 1.6),
            ),

            const SizedBox(height: 8),

            // List placeholder
            Text('• Item one', style: TextStyle(color: Colors.grey[700] ),
              child: ListTile(
                title: Text('Item one'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.article, size: 64, color: Colors.blueGrey[300]),
          const SizedBox(height: 16),
          Text(
            'Markdown Preview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
