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

class NodeWidget extends StatelessWidget {
  final FlowNode node;
  final void Function(Offset delta)? onDrag;
  final void Function(String fromId, String toId)? onConnectionCreated;

  const NodeWidget({
    super.key,
    required this.node,
    this.onDrag,
    this.onConnectionCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: node.position.dx,
      top: node.position.dy,
      child: GestureDetector(
        // السحب لتحريك العقدة يعمل على كامل العقدة
        onPanUpdate: (details) {
          onDrag?.call(details.delta);
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
                      color: node.color.withOpacity(0.4), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: node.color.withOpacity(0.15),
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
                        // الأيقونة + السحب لإنشاء اتصال
                        Draggable<String>(
                          data: node.id,
                          feedback: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: node.color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.chat_bubble_outline_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                          childWhenDragging: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.chat_bubble_outline_rounded,
                                size: 18, color: node.color.withOpacity(0.3)),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: node.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.chat_bubble_outline_rounded,
                                size: 18, color: node.color),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            node.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: node.color,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (node.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        node.subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // نقطة التوصيل اليمنى (للإفلات فقط - DragTarget)
              Positioned(
                right: -6,
                top: 0,
                bottom: 0,
                child: DragTarget<String>(
                  onAcceptWithDetails: (details) {
                    onConnectionCreated?.call(details.data, node.id);
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isHovering = candidateData.isNotEmpty;
                    return Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isHovering ? Colors.yellow : node.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: isHovering ? Colors.yellow : Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // نقطة التوصيل اليسرى (للإفلات فقط - DragTarget)
              Positioned(
                left: -6,
                top: 0,
                bottom: 0,
                child: DragTarget<String>(
                  onAcceptWithDetails: (details) {
                    onConnectionCreated?.call(details.data, node.id);
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isHovering = candidateData.isNotEmpty;
                    return Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isHovering ? Colors.yellow : node.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: isHovering ? Colors.yellow : Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}