import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum NodeType { message, question, action, condition }

class FlowNode {
  final String id;
  String title;
  String subtitle;
  Offset position;
  Color color;
  NodeType type;

  FlowNode({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.position,
    this.color = const Color(0xFF6366F1),
    this.type = NodeType.message,
  });
}

class NodeWidget extends StatefulWidget {
  final FlowNode node;
  final void Function(Offset delta)? onDrag;
  final void Function(String newTitle)? onTitleChanged;
  final VoidCallback? onDelete;

  const NodeWidget({
    super.key,
    required this.node,
    this.onDrag,
    this.onTitleChanged,
    this.onDelete,
  });

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  bool _isEditing = false;
  late TextEditingController _titleController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.node.title);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      _commitEdit();
    }
  }

  void _commitEdit() {
    final newTitle = _titleController.text.trim();
    if (newTitle.isNotEmpty && newTitle != widget.node.title) {
      widget.onTitleChanged?.call(newTitle);
    }
    setState(() {
      _isEditing = false;
    });
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _titleController.text = widget.node.title;
    });
    _focusNode.requestFocus();
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
    _titleController.text = widget.node.title;
  }

  // استخدام فوسفور ديوطون – مظهر حديث جداً
  PhosphorIconData _iconForType(NodeType type) {
    switch (type) {
      case NodeType.message:
        return PhosphorIconsDuotone.chatCenteredDots; // فقاعة محادثة بنقاط
      case NodeType.question:
        return PhosphorIconsDuotone.question; // دائرة بها علامة سؤال
      case NodeType.action:
        return PhosphorIconsDuotone.gearFine; // ترس (إجراء)
      case NodeType.condition:
        return PhosphorIconsDuotone.gitFork; // تفرع (شرط)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.node.position.dx,
      top: widget.node.position.dy,
      child: GestureDetector(
        onPanStart: (_) {
          if (_isEditing) _cancelEditing();
        },
        onPanUpdate: (details) {
          widget.onDrag?.call(details.delta);
        },
        onTap: () {
          if (!_isEditing) _startEditing();
        },
        onLongPress: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('حذف العقدة'),
              content: const Text('هل تريد حذف هذه العقدة نهائياً؟'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    widget.onDelete?.call();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('حذف'),
                ),
              ],
            ),
          );
        },
        child: SizedBox(
          width: 200,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
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
                          child: PhosphorIcon(
                            _iconForType(widget.node.type),
                            size: 18,
                            color: widget.node.color,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _isEditing
                              ? TextField(
                                  controller: _titleController,
                                  focusNode: _focusNode,
                                  autofocus: true,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: widget.node.color,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onSubmitted: (_) => _commitEdit(),
                                )
                              : Text(
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
              // نقاط التوصيل
              Positioned(
                right: -6,
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