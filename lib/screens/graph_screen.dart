import 'package:flutter/material.dart';

/// GraphScreen: visualize note connections as nodes and edges.
class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen>
    with SingleTickerProviderStateMixin {
  late TabController _controller;
  double _zoomLevel = 1.0;
  Offset _offset = const Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this);
    
    // Load all notes and parse their links in background
    _loadGraphData();
  }

  Future<void> _loadGraphData() async {
    try {
      final notes = await getAllNotes();
      if (notes.isNotEmpty) {
        setState(() {
          _graphNodes = _extractAllNodes(notes);
          _graphEdges = _extractAllEdges(notes);
        });
      }
    } catch (e) {
      debugPrint('Graph data load failed: $e');
    }
  }

  /// Extract unique nodes from all notes (titles that appear in [[ ]] links)
  List<_GraphNode> _extractAllNodes(List<Map<String, dynamic>> notes) {
    final nodeSet = <String, int>{};
    
    for (final note in notes) {
      // TODO: parse each note's content to extract all [[title]] references
      // This would require reading the full BLOB content per note
    }
    
    // For demo purposes, return a few placeholder nodes
    return [
      _GraphNode(id: 'node_1', title: 'Getting Started', x: 200, y: 150),
      _GraphNode(id: 'node_2', title: 'Project Ideas', x: 450, y: 300),
      _GraphNode(id: 'node_3', title: 'Future Roadmap', x: 700, y: 100),
    ];
  }

  /// Extract edges (links) between nodes based on [[ ]] syntax
  List<_GraphEdge> _extractAllEdges(List<Map<String, dynamic>> notes) {
    final edgeSet = <String, int>{};
    
    for (final note in notes) {
      // TODO: parse content to find [[title]] references and build edges
      // Each edge gets a weight based on frequency of the link across all notes
    }
    
    return [
      _GraphEdge(fromId: 'node_1', toId: 'node_2', weight: 0.8),
      _GraphEdge(fromId: 'node_1', toId: 'node_3', weight: 0.6),
    ];
  }

  // Demo graph data (would be parsed from actual notes in production)
  List<_GraphNode> get _graphNodes => [];
  List<_GraphEdge> get _graphEdges => [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graph'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in_map),
            tooltip: 'Zoom in',
            onPressed: () => setState(() => _zoomLevel *= 1.2),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            tooltip: 'Zoom out',
            onPressed: () => setState(() => _zoomLevel /= 1.2),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search nodes...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    maxLines: 1,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filter by tags',
                  onPressed: () => _showFilterMenu(), // TODO
                ),
              ],
            ),
          ),

          // Graph canvas
          Expanded(child: _buildGraphCanvas()),
        ],
      ),
    );
  }
}

/// Canvas with zoomable graph visualization (fl_chart integration here)
class GraphCanvas extends StatefulWidget {
  final List<_GraphNode> nodes;
  final List<_GraphEdge> edges;

  const GraphCanvas({super.key, required this.nodes, required this.edges});

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas>
    with SingleTickerProviderStateMixin {
  late TabController _controller;
  Offset _offset = const Offset.zero;
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFAF9),
      child: Stack(
        children: [
          // Graph visualization layer (fl_chart)
          _buildGraphLayer(),

          // Context menu for clicking nodes/edges
          Positioned.fill(child: GestureDetector(
            onTapDown: (_) => _showNodeInfo(_hitTestNode()),
          )),

          // Legend and tooltips
          _buildLegend(),
        ],
      ),
    );
  }
}

Widget _buildGraphLayer() {
  return Container(
    color: const Color(0xFFFAFAF9),
    child: CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: GraphPainter(widget.nodes, widget.edges, _zoomLevel),
    ),
  );
}

/// Painter for the graph visualization (draws nodes as circles, edges as lines)
class GraphPainter extends CustomPainter {
  final List<_GraphNode> nodes;
  final List<_GraphEdge> edges;
  final double zoomLevel;

  GraphPainter(this.nodes, this.edges, this.zoomLevel);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw edges first (so they appear behind nodes)
    _drawEdges(canvas, size);

    // Then draw nodes on top
    _drawNodes(canvas, size);
  }

  void _drawEdges(Canvas canvas, Size size) {
    for (final edge in edges) {
      // TODO: calculate positions from node coordinates
      final fromCenter = Offset(0, 0); // placeholder
      final toCenter = Offset(size.width / 2, size.height / 2); // placeholder

      final path = Path();
      path.moveTo(fromCenter.dx, fromCenter.dy);
      path.lineTo(toCenter.dx, toCenter.dy);

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.grey[300]!
          ..strokeWidth = 2 * zoomLevel
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawNodes(Canvas canvas, Size size) {
    for (final node in nodes) {
      final center = Offset(node.x, node.y);
      final radius = 8 * zoomLevel;

      // Draw circular node
      final paint = Paint()
        ..color = Colors.blueGrey[300]!
        ..style = PaintingStyle.fill
        ..strokeWidth = 2 * zoomLevel;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GraphNode {
  final String id;
  final String title;
  final double x; // horizontal position (pixels from viewport origin)
  final double y; // vertical position (pixels)

  _GraphNode({required this.id, required this.title, required this.x, required this.y});
}

class _GraphEdge {
  final String fromId;
  final String toId;
  final double weight; // link frequency across all notes (0.0 - 1.0)

  _GraphEdge({required this.fromId, required this.toId, required this.weight});
}
