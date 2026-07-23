import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../widgets/node_widget.dart';

class Connection {
  final String id;
  final String fromNodeId;
  final String toNodeId;

  Connection({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
  });
}

class BuilderScreen extends StatefulWidget {
  const BuilderScreen({super.key});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen> {
  final List<FlowNode> _nodes = [];
  final List<Connection> _connections = [];
  final Uuid _uuid = const Uuid();

  // متغيرات مؤقتة لرسم خط أثناء السحب
  String? _draggingFromNodeId;
  Offset? _dragEndPosition;

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

  void _onNodeMoved(String id, Offset delta) {
    setState(() {
      final index = _nodes.indexWhere((n) => n.id == id);
      if (index != -1) {
        _nodes[index].position += delta;
      }
    });
  }

  // بدء السحب من نقطة توصيل (جهة اليمين)
  void _onConnectorDragStart(String nodeId) {
    setState(() {
      _draggingFromNodeId = nodeId;
      _dragEndPosition = _getConnectorPosition(nodeId, isRight: true);
    });
  }

  // تحديث موضع المؤشر أثناء السحب
  void _onConnectorDragUpdate(Offset delta) {
    if (_draggingFromNodeId != null) {
      setState(() {
        _dragEndPosition = _dragEndPosition! + delta;
      });
    }
  }

  // إنهاء السحب: إذا انتهى فوق نقطة توصيل يسرى لعقدة أخرى، ننشئ اتصالاً
  void _onConnectorDragEnd(String? targetNodeId) {
    if (_draggingFromNodeId != null &&
        targetNodeId != null &&
        targetNodeId != _draggingFromNodeId) {
      // تحقق من عدم وجود اتصال مكرر
      final exists = _connections.any((c) =>
          c.fromNodeId == _draggingFromNodeId && c.toNodeId == targetNodeId);
      if (!exists) {
        setState(() {
          _connections.add(Connection(
            id: _uuid.v4(),
            fromNodeId: _draggingFromNodeId!,
            toNodeId: targetNodeId,
          ));
        });
      }
    }
    setState(() {
      _draggingFromNodeId = null;
      _dragEndPosition = null;
    });
  }

  // حساب موضع نقطة توصيل معينة (يمين أو يسار العقدة)
  Offset _getConnectorPosition(String nodeId, {required bool isRight}) {
    final node = _nodes.firstWhere((n) => n.id == nodeId);
    final x = isRight ? node.position.dx + 200 : node.position.dx;
    final y = node.position.dy + 40; // نصف ارتفاع العقدة تقريباً
    return Offset(x, y);
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
              // شبكة الخلفية
              CustomPaint(
                size: const Size(3000, 3000),
                painter: GridPainter(),
              ),
              // الخطوط الموجودة
              CustomPaint(
                size: const Size(3000, 3000),
                painter: ConnectionPainter(
                  connections: _connections,
                  nodes: _nodes,
                ),
              ),
              // خط مؤقت أثناء السحب
              if (_draggingFromNodeId != null && _dragEndPosition != null)
                CustomPaint(
                  size: const Size(3000, 3000),
                  painter: TempLinePainter(
                    start: _getConnectorPosition(_draggingFromNodeId!, isRight: true),
                    end: _dragEndPosition!,
                    color: _nodes.firstWhere((n) => n.id == _draggingFromNodeId).color,
                  ),
                ),
              // العقد
              ..._nodes.map((node) => NodeWidget(
                    node: node,
                    onDrag: (delta) => _onNodeMoved(node.id, delta),
                    onConnectorDragStart: () => _onConnectorDragStart(node.id),
                    onConnectorDragUpdate: _onConnectorDragUpdate,
                    onConnectorDragEnd: (globalPosition) {
                      // نبحث عن عقدة قريبة من نقطة الإفلات
                      final target = _findNodeNear(globalPosition);
                      _onConnectorDragEnd(target?.id);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // يبحث عن عقدة يقع مركزها قريباً من نقطة معينة
  FlowNode? _findNodeNear(Offset globalPos) {
    for (final node in _nodes) {
      final center = node.position + const Offset(100, 40);
      if ((center - globalPos).distance < 50) {
        return node;
      }
    }
    return null;
  }
}

// رسام الخطوط الدائمة
class ConnectionPainter extends CustomPainter {
  final List<Connection> connections;
  final List<FlowNode> nodes;

  ConnectionPainter({required this.connections, required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final conn in connections) {
      final fromNode = nodes.firstWhere((n) => n.id == conn.fromNodeId);
      final toNode = nodes.firstWhere((n) => n.id == conn.toNodeId);
      final start = Offset(fromNode.position.dx + 200, fromNode.position.dy + 40);
      final end = Offset(toNode.position.dx, toNode.position.dy + 40);
      final paint = Paint()
        ..color = fromNode.color.withOpacity(0.6)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(start.dx + 60, start.dy, end.dx - 60, end.dy, end.dx, end.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// رسام الخط المؤقت أثناء السحب
class TempLinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;

  TempLinePainter({required this.start, required this.end, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(start.dx + 60, start.dy, end.dx - 60, end.dy, end.dx, end.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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