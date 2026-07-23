import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../widgets/node_widget.dart';

class BuilderScreen extends StatefulWidget {
  const BuilderScreen({super.key});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen> {
  final List<FlowNode> _nodes = [];
  final Uuid _uuid = const Uuid();

  void _addNode() {
    setState(() {
      _nodes.add(
        FlowNode(
          id: _uuid.v4(),
          title: 'نص ترحيبي',
          subtitle: 'السلام عليكم! كيف أقدر أساعدك؟',
          position: Offset(
            200 + (_nodes.length * 30) % 400,
            200 + (_nodes.length * 40) % 300,
          ),
          color: [
            const Color(0xFF5C6BC0),
            const Color(0xFF26A69A),
            const Color(0xFFEF5350),
            const Color(0xFFFFA726),
            const Color(0xFFAB47BC),
          ][_nodes.length % 5],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محرر الخريطة'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton(
              icon: const Icon(Icons.add_circle_rounded, size: 30),
              tooltip: 'إضافة عقدة',
              onPressed: _addNode,
            ),
          ),
        ],
      ),
      body: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        minScale: 0.1,
        maxScale: 2.0,
        child: Stack(
          children: [
            CustomPaint(
              size: const Size(3000, 3000),
              painter: GridPainter(),
            ),
            ..._nodes.map((node) => NodeWidget(node: node)),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1;

    const double spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
