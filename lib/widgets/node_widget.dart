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
    this.color = const Color(0xFF5C6BC0), // لون أزرق أنيق
  });
}

class NodeWidget extends StatelessWidget {
  final FlowNode node;

  const NodeWidget({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: node.position.dx,
      top: node.position.dy,
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: node.color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: node.color.withOpacity(0.6), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: node.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.chat_bubble_outline, size: 18, color: node.color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: node.color,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (node.subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                node.subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
