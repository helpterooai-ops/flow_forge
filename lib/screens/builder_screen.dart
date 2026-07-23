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
          title: 'رسالة ترحيب',
          subtitle: 'مرحباً بك! كيف يمكنني مساعدتك اليوم؟',
          position: Offset(
            250 + (_nodes.length * 20) % 200,
            250 + (_nodes.length * 30) % 200,
          ),
          color: [
            const Color(0xFF6366F1),
            const Color(0xFF0EA5E9),
            const Color(0xFF10B981),
            const Color(0xFFF59E0B),
            const Color(0xFFEF4444),
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
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
            ),
            tooltip: 'إضافة عقدة',
            onPressed: _addNode,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        minScale: 0.1,
        maxScale: 2.0,
        child: SizedBox(
          width: 3000,
          height: 3000,
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
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 0.8;
    const spacing = 25.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
