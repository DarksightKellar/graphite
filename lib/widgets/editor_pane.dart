import 'package:flutter/material.dart';

/// A clean, distraction-free markdown editor.
class EditorPane extends StatelessWidget {
  const EditorPane({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Toolbar with line numbers and word count
          _buildToolbar(context),
          Expanded(
            flex: 2,
            child: _buildEditorBody(),
          ),
        ],
      ),
    );
  }
}

Widget _buildToolbar(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    color: Colors.white,
    child: Row(
      children: [
        // Line numbers placeholder (for syntax highlighting)
        SizedBox(width: 36, child: _buildLineNumbers()),

        // Word count and other metadata
        Expanded(child: Container()),

        const Text('Word count: 0'), // TODO: real counter
      ],
    ),
  );
}

Widget _buildEditorBody() {
  return Container(
    color: Colors.white,
    child: TextField(
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: false,
      ),
      maxLines: null, // unlimited scrolling
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      autofocus: true,
    ),
  );
}

Widget _buildLineNumbers() {
  return Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(100, (index) {
        return Text(
          '${index + 1}',
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        );
      }),
    ),
  );
}
