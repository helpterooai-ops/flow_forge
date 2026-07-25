import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/node_widget.dart';
import '../widgets/toast_widget.dart';
import '../models/saved_map.dart';

class Connection {
  final String id;
  final String fromNodeId;
  final String toNodeId;
  String? condition;

  Connection({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    this.condition,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'from': fromNodeId,
        'to': toNodeId,
        if (condition != null) 'condition': condition,
      };

  factory Connection.fromJson(Map<String, dynamic> json) => Connection(
        id: json['id'],
        fromNodeId: json['from'],
        toNodeId: json['to'],
        condition: json['condition'],
      );
}

class BuilderScreen extends StatefulWidget {
  final SavedMap? savedMap;

  const BuilderScreen({super.key, this.savedMap});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen>
    with SingleTickerProviderStateMixin {
  final List<FlowNode> _nodes = [];
  final List<Connection> _connections = [];
  final Uuid _uuid = const Uuid();
  bool _isPublishing = false;
  bool _isLoading = true;

  Set<String> _wrongConnectionIds = {};
  Map<String, bool> _wrongNodeMap = {};

  late AnimationController _dashController;

  @override
  void initState() {
    super.initState();
    _dashController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    if (widget.savedMap != null) {
      _loadFromSavedMap();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _dashController.dispose();
    super.dispose();
  }

  // --------------------- تحميل الخرائط ---------------------
  void _loadFromSavedMap() {
    final data = jsonDecode(widget.savedMap!.jsonData);
    setState(() {
      _nodes.clear();
      _connections.clear();
      for (final n in data['nodes']) {
        _nodes.add(FlowNode(
          id: n['id'],
          title: n['title'],
          subtitle: n['subtitle'] ?? '',
          position: Offset((n['x'] ?? 0).toDouble(), (n['y'] ?? 0).toDouble()),
          color: Color(int.parse(n['color'] ?? 'ff6366f1', radix: 16)),
          type: NodeType.values.firstWhere((e) => e.name == n['type']),
          variableName: n['variableName'] ?? '',
          prompt: n['prompt'] ?? '',
          isPaused: n['isPaused'] ?? false,
          fallbackNodeId: n['fallbackNodeId'],
        ));
      }
      for (final c in data['connections']) {
        _connections.add(Connection.fromJson(c));
      }
    });
    _updateWrongConnections();
    setState(() {
      _isLoading = false;
    });
  }

  // --------------------- حفظ الخريطة في SharedPreferences ---------------------
  Future<void> _saveToSideMenu() async {
    final map = {
      'nodes': _nodes
          .map((n) => {
                'id': n.id,
                'type': n.type.name,
                'title': n.title,
                'subtitle': n.subtitle,
                'color': n.color.value.toRadixString(16),
                'x': n.position.dx,
                'y': n.position.dy,
                'variableName': n.variableName,
                'prompt': n.prompt,
                'isPaused': n.isPaused,
                'fallbackNodeId': n.fallbackNodeId,
              })
          .toList(),
      'connections': _connections.map((c) => c.toJson()).toList(),
    };
    final jsonData = jsonEncode(map);
    final mapId = widget.savedMap?.id ?? _uuid.v4();
    final mapName = widget.savedMap?.name ??
        'خريطة ${DateTime.now().millisecondsSinceEpoch}';

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('saved_maps');
    List<SavedMap> maps = [];
    if (data != null) {
      maps =
          (jsonDecode(data) as List).map((e) => SavedMap.fromJson(e)).toList();
    }

    final index = maps.indexWhere((m) => m.id == mapId);
    final newMap = SavedMap(id: mapId, name: mapName, jsonData: jsonData);
    if (index != -1) {
      maps[index] = newMap;
    } else {
      maps.add(newMap);
    }

    await prefs.setString(
        'saved_maps', jsonEncode(maps.map((m) => m.toJson()).toList()));
    if (mounted) {
      AppToast.show(context, 'تم الحفظ في الخرائط المعلقة');
    }
  }

  // --------------------- الخروج من المحرر ---------------------
  Future<bool> _onWillPop() async {
    return true;
  }

  // --------------------- حوار إضافة عقدة ---------------------
  void _showAddNodeDialog() {
    NodeType? selectedType;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اختر نوع العقدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: NodeType.values.map((type) {
            final label = _labelForType(type);
            final color = _colorForType(type);
            return ListTile(
              leading: Icon(_iconForType(type), color: color),
              title: Text(label),
              onTap: () {
                selectedType = type;
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    ).then((_) {
      if (selectedType != null) {
        _addNode(selectedType!);
      }
    });
  }

  String _labelForType(NodeType type) {
    switch (type) {
      case NodeType.message:
        return 'رسالة';
      case NodeType.question:
        return 'سؤال';
      case NodeType.action:
        return 'إجراء';
      case NodeType.condition:
        return 'شرط';
      case NodeType.input:
        return 'إدخال مباشر';
      case NodeType.intent:
        return 'تصنيف نية';
    }
  }

  Color _colorForType(NodeType type) {
    switch (type) {
      case NodeType.message:
        return const Color(0xFF6366F1);
      case NodeType.question:
        return const Color(0xFF0EA5E9);
      case NodeType.action:
        return const Color(0xFF10B981);
      case NodeType.condition:
        return const Color(0xFFF59E0B);
      case NodeType.input:
        return const Color(0xFFF97316);
      case NodeType.intent:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _iconForType(NodeType type) {
    switch (type) {
      case NodeType.message:
        return Iconsax.message;
      case NodeType.question:
        return Iconsax.message_question;
      case NodeType.action:
        return Iconsax.setting_2;
      case NodeType.condition:
        return Iconsax.arrow_3;
      case NodeType.input:
        return Iconsax.text_block;
      case NodeType.intent:
        return Icons.psychology_rounded;
    }
  }

  void _addNode(NodeType type) {
    setState(() {
      _nodes.add(FlowNode(
        id: _uuid.v4(),
        title: _labelForType(type),
        subtitle: 'انقر للكتابة...',
        position: Offset(
          250 + (_nodes.length * 20) % 200,
          250 + (_nodes.length * 30) % 200,
        ),
        color: _colorForType(type),
        type: type,
        variableName: type == NodeType.input ? 'input_${_nodes.length}' : '',
        prompt: type == NodeType.input ? 'أدخل القيمة هنا' : '',
        isPaused: false,
        fallbackNodeId: null,
      ));
    });
  }

  void _onNodeMoved(String id, Offset delta) {
    setState(() {
      final index = _nodes.indexWhere((n) => n.id == id);
      if (index != -1) {
        _nodes[index].position += delta;
      }
    });
    _updateWrongConnections();
    _checkProximity(id);
  }

  void _deleteNode(String nodeId) {
    setState(() {
      _nodes.removeWhere((n) => n.id == nodeId);
      _connections.removeWhere(
          (c) => c.fromNodeId == nodeId || c.toNodeId == nodeId);
    });
    _updateWrongConnections();
  }

  void _addConnectionWithCondition(
      String fromId, String toId, String? condition) {
    if (fromId == toId) return;
    final exists = _connections.any((c) =>
        (c.fromNodeId == fromId && c.toNodeId == toId) ||
        (c.fromNodeId == toId && c.toNodeId == fromId));
    if (!exists) {
      setState(() {
        _connections.add(Connection(
          id: _uuid.v4(),
          fromNodeId: fromId,
          toNodeId: toId,
          condition: condition,
        ));
      });
      _updateWrongConnections();
    }
  }

  void _deleteConnection(String connId) {
    setState(() {
      _connections.removeWhere((c) => c.id == connId);
    });
    _updateWrongConnections();
  }

  // --------------------- تحديث حالة التحذير (معكوس) ---------------------
  void _updateWrongConnections() {
    final wrongConnections = <String>{};
    final wrongNodes = <String, bool>{};

    for (final conn in _connections) {
      final fromNode = _nodes.firstWhere((n) => n.id == conn.fromNodeId);
      final toNode = _nodes.firstWhere((n) => n.id == conn.toNodeId);
      // ✅ الاتجاه الصحيح الآن: من اليمين إلى اليسار
      // الخطأ يحدث عندما يكون المصدر (from) على يسار الهدف (to)
      if (fromNode.position.dx < toNode.position.dx) {
        wrongConnections.add(conn.id);
        wrongNodes[conn.toNodeId] = true;
      }
    }

    if (wrongConnections.length != _wrongConnectionIds.length ||
        !wrongConnections.containsAll(_wrongConnectionIds)) {
      setState(() {
        _wrongConnectionIds = wrongConnections;
        _wrongNodeMap = wrongNodes;
      });
    }
  }

  // --------------------- النشر والتصدير ---------------------
  Future<void> _publishMap() async {
    if (_isPublishing) return;
    setState(() => _isPublishing = true);

    final map = {
      'nodes': _nodes
          .map((n) => {
                'id': n.id,
                'type': n.type.name,
                'title': n.title,
                'subtitle': n.subtitle,
                'color': n.color.value.toRadixString(16),
                'x': n.position.dx,
                'y': n.position.dy,
                'variableName': n.variableName,
                'prompt': n.prompt,
                'isPaused': n.isPaused,
                'fallbackNodeId': n.fallbackNodeId,
              })
          .toList(),
      'connections': _connections.map((c) => c.toJson()).toList(),
    };

    try {
      final response = await http.post(
        Uri.parse('https://flow-forge-server.vercel.app/api/v1/maps/test'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(map),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        AppToast.show(context, 'تم نشر الخريطة بنجاح');
      } else {
        AppToast.show(context, 'فشل النشر (${response.statusCode})', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, 'خطأ في الاتصال', isError: true);
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  void _exportJSON() {
    final map = {
      'nodes': _nodes
          .map((n) => {
                'id': n.id,
                'type': n.type.name,
                'title': n.title,
                'subtitle': n.subtitle,
                'color': n.color.value.toRadixString(16),
                'x': n.position.dx,
                'y': n.position.dy,
                'variableName': n.variableName,
                'prompt': n.prompt,
                'isPaused': n.isPaused,
                'fallbackNodeId': n.fallbackNodeId,
              })
          .toList(),
      'connections': _connections.map((c) => c.toJson()).toList(),
    };
    final jsonString = const JsonEncoder.withIndent('  ').convert(map);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصدير الخريطة'),
        content: SingleChildScrollView(
          child: SelectableText(
            jsonString,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  // --------------------- فحص القرب (التوصيل التلقائي معكوس) ---------------------
  void _checkProximity(String nodeId) {
    final movedNode = _nodes.firstWhere((n) => n.id == nodeId);
    final movedCenter =
        Offset(movedNode.position.dx + 100, movedNode.position.dy + 40);

    FlowNode? closestNode;
    double minDist = double.infinity;

    for (final other in _nodes) {
      if (other.id == nodeId) continue;
      final otherCenter =
          Offset(other.position.dx + 100, other.position.dy + 40);
      final dist = (movedCenter - otherCenter).distance;

      if (dist < 150 && dist < minDist) {
        final alreadyConnected = _connections.any((c) =>
            (c.fromNodeId == movedNode.id && c.toNodeId == other.id) ||
            (c.fromNodeId == other.id && c.toNodeId == movedNode.id));
        if (!alreadyConnected) {
          minDist = dist;
          closestNode = other;
        }
      }
    }

    if (closestNode != null) {
      final leftNode = movedNode.position.dx < closestNode.position.dx
          ? movedNode
          : closestNode;
      final rightNode = movedNode.position.dx < closestNode.position.dx
          ? closestNode
          : movedNode;

      // ✅ نجعل العقدة اليمنى هي المصدر (from) واليسرى هي الهدف (to)
      if (rightNode.type == NodeType.intent) {
        _showConditionDialog(rightNode.id, leftNode.id);
      } else {
        _addConnectionWithCondition(rightNode.id, leftNode.id, null);
      }
      _updateWrongConnections();
    }
  }

  void _showConditionDialog(String fromId, String toId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('شرط الانتقال'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'مثلاً: طلب مساعدة، شكوى...',
            labelText: 'الكلمة أو العبارة المطلوبة',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final condition = controller.text.trim();
              _addConnectionWithCondition(
                  fromId, toId, condition.isNotEmpty ? condition : null);
              Navigator.pop(ctx);
            },
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  // --------------------- واجهة المستخدم ---------------------
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('محرر الخريطة'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.save, color: Colors.white, size: 24),
              ),
              tooltip: 'حفظ في الخرائط المعلقة',
              onPressed: _saveToSideMenu,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isPublishing ? Colors.grey : const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isPublishing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cloud_upload_rounded,
                        color: Colors.white, size: 24),
              ),
              tooltip: 'نشر إلى البوت',
              onPressed: _isPublishing ? null : _publishMap,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.save_alt_rounded,
                    color: Colors.white, size: 24),
              ),
              tooltip: 'تصدير JSON',
              onPressed: _exportJSON,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 24),
              ),
              tooltip: 'إضافة عقدة',
              onPressed: _showAddNodeDialog,
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListenableBuilder(
                listenable: _dashController,
                builder: (context, child) {
                  return InteractiveViewer(
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
                          CustomPaint(
                            size: const Size(3000, 3000),
                            painter: ConnectionPainter(
                              connections: _connections,
                              nodes: _nodes,
                              wrongConnectionIds: _wrongConnectionIds,
                              dashPhase: _dashController.value * 20,
                            ),
                          ),
                          ..._connections.map((conn) {
                            final from = _nodes
                                .firstWhere((n) => n.id == conn.fromNodeId);
                            final to = _nodes
                                .firstWhere((n) => n.id == conn.toNodeId);
                            return ConnectionDeleteButton(
                              connection: conn,
                              fromNode: from,
                              toNode: to,
                              onDelete: () => _deleteConnection(conn.id),
                            );
                          }),
                          ..._nodes.map((node) => NodeWidget(
                                node: node,
                                onDrag: (delta) =>
                                    _onNodeMoved(node.id, delta),
                                onTitleChanged: (newTitle) {
                                  setState(() {
                                    node.title = newTitle;
                                  });
                                },
                                onDelete: () => _deleteNode(node.id),
                                onPropertiesChanged: () {
                                  setState(() {});
                                },
                                isWrongDirection:
                                    _wrongNodeMap[node.id] ?? false,
                                wrongHint: 'اسحب لليسار ←',
                              )),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// --------------------- ConnectionPainter ---------------------
class ConnectionPainter extends CustomPainter {
  final List<Connection> connections;
  final List<FlowNode> nodes;
  final Set<String> wrongConnectionIds;
  final double dashPhase;

  ConnectionPainter({
    required this.connections,
    required this.nodes,
    required this.wrongConnectionIds,
    this.dashPhase = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final conn in connections) {
      final fromNode = nodes.firstWhere((n) => n.id == conn.fromNodeId);
      final toNode = nodes.firstWhere((n) => n.id == conn.toNodeId);

      final start =
          Offset(fromNode.position.dx + 200, fromNode.position.dy + 40);
      final end = Offset(toNode.position.dx, toNode.position.dy + 40);

      final isWrong = wrongConnectionIds.contains(conn.id);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
            start.dx + 60, start.dy, end.dx - 60, end.dy, end.dx, end.dy);

      if (isWrong) {
        paint
          ..color = Colors.red
          ..strokeWidth = 2.5;
        final dashedPath = _createDashedPath(path, dashPhase, 10, 8);
        canvas.drawPath(dashedPath, paint);
        _drawArrow(canvas, start, end, Colors.red);
      } else {
        paint
          ..color = fromNode.color.withOpacity(0.6)
          ..strokeWidth = 2.5;
        canvas.drawPath(path, paint);
      }
    }
  }

  Path _createDashedPath(
      Path source, double dashPhase, double dashLength, double gapLength) {
    final metrics = source.computeMetrics();
    final result = Path();
    for (final metric in metrics) {
      double distance = dashPhase % (dashLength + gapLength);
      while (distance < metric.length) {
        final start = metric.getTangentForOffset(distance)!.position;
        final end = metric
            .getTangentForOffset(
                (distance + dashLength).clamp(0, metric.length))!
            .position;
        result.moveTo(start.dx, start.dy);
        result.lineTo(end.dx, end.dy);
        distance += dashLength + gapLength;
      }
    }
    return result;
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final direction = end - start;
    final length = direction.distance;
    final unit = direction / length;
    final arrowHead = end - unit * 15;
    final perpendicular = Offset(-unit.dy, unit.dx) * 6;
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowHead.dx - perpendicular.dx,
          arrowHead.dy - perpendicular.dy)
      ..lineTo(arrowHead.dx + perpendicular.dx,
          arrowHead.dy + perpendicular.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) => true;
}

// --------------------- ConnectionDeleteButton ---------------------
class ConnectionDeleteButton extends StatelessWidget {
  final Connection connection;
  final FlowNode fromNode;
  final FlowNode toNode;
  final VoidCallback onDelete;

  const ConnectionDeleteButton({
    super.key,
    required this.connection,
    required this.fromNode,
    required this.toNode,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final start =
        Offset(fromNode.position.dx + 200, fromNode.position.dy + 40);
    final end = Offset(toNode.position.dx, toNode.position.dy + 40);
    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

    return Positioned(
      left: mid.dx - 15,
      top: mid.dy - 15,
      child: GestureDetector(
        onTap: onDelete,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.close, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

// --------------------- GridPainter ---------------------
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