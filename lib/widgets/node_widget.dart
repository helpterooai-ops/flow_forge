import 'package:flutter/material.dart';

class FlowNode {
  final String id;
  String title;
  String subtitle;
  Offset position;
  Color color;

  FlowNode({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.position,
    this.color = const Color(0xFF6366F1),
  });
}

class NodeWidget extends StatefulWidget {
  final FlowNode node;
  final void Function(Offset delta)? onDrag;
  final VoidCallback? onConnectorDragStart;
  final void Function(Offset delta)? onConnectorDragUpdate;
  final void Function(Offset globalPosition)? onConnectorDragEnd;

  const NodeWidget({
    super.key,
    required this.node,
    this.onDrag,
    this.onConnectorDragStart,
    this.onConnectorDragUpdate,
    this.onConnectorDragEnd,
  });

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  // لحفظ نقطة البداية العامة (global) عند بدء السحب من نقطة التوصيل
  Offset? _connectorStartGlobal;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.node.position.dx,
      top: widget.node.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          widget.onDrag?.call(details.delta);
        },
        child: SizedBox(
          width: 200,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // العقدة نفسها
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: widget.node.color.withOpacity(0.4), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: widget.node.color.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: widget.node.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.chat_bubble_outline_rounded,
                              size: 18, color: widget.node.color),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.node.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: widget.node.color,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (widget.node.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        widget.node.subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // نقطة التوصيل اليمنى (قابلة للسحب)
              Positioned(
                right: -6,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onPanStart: (_) {
                    widget.onConnectorDragStart?.call();
                    // نحفظ الإحداثيات العامة عند بدء السحب (لإستخدامها لاحقاً)
                    final renderBox = context.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      // نأخذ إحداثيات مركز نقطة التوصيل اليمنى بالنسبة للعالم (global)
                      final connectorCenter = renderBox.localToGlobal(
                          Offset(renderBox.size.width + 6, renderBox.size.height / 2));
                      _connectorStartGlobal = connectorCenter;
                    }
                  },
                  onPanUpdate: (details) {
                    widget.onConnectorDragUpdate?.call(details.delta);
                  },
                  onPanEnd: (_) {
                    widget.onConnectorDragEnd?.call(_connectorStartGlobal ?? Offset.zero);
                    _connectorStartGlobal = null;
                  },
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: widget.node.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                ),
              ),
              // نقطة التوصيل اليسرى (ثابتة)
              Positioned(
                left: -6,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: widget.node.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}