import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

enum NodeType { message, question, action, condition, input, intent }

class FlowNode {
  final String id;
  String title;
  String subtitle;
  Offset position;
  Color color;
  NodeType type;

  // حقول إضافية
  String variableName;
  String prompt;
  bool isPaused;
  String? fallbackNodeId;

  FlowNode({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.position,
    this.color = const Color(0xFF6366F1),
    this.type = NodeType.message,
    this.variableName = '',
    this.prompt = '',
    this.isPaused = false,
    this.fallbackNodeId,
  });
}

class NodeWidget extends StatefulWidget {
  final FlowNode node;
  final void Function(Offset delta)? onDrag;
  final void Function(String newTitle)? onTitleChanged;
  final VoidCallback? onDelete;
  final VoidCallback? onPropertiesChanged;

  const NodeWidget({
    super.key,
    required this.node,
    this.onDrag,
    this.onTitleChanged,
    this.onDelete,
    this.onPropertiesChanged,
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

  void _showPropertiesDialog(BuildContext context) {
    final titleCtrl = TextEditingController(text: widget.node.title);
    final promptCtrl = TextEditingController(text: widget.node.prompt);
    final varCtrl = TextEditingController(text: widget.node.variableName);
    final isInputType = widget.node.type == NodeType.input || widget.node.type == NodeType.intent;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('خصائص العقدة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'العنوان')),
              const SizedBox(height: 12),
              TextField(controller: promptCtrl, decoration: const InputDecoration(labelText: 'النص الإرشادي (Prompt)')),
              if (isInputType) ...[
                const SizedBox(height: 12),
                TextField(controller: varCtrl, decoration: const InputDecoration(labelText: 'اسم المتغير')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete?.call();
            },
            child: const Text('حذف العقدة', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              widget.node.title = titleCtrl.text;
              widget.node.prompt = promptCtrl.text;
              if (isInputType) {
                widget.node.variableName = varCtrl.text;
              }
              widget.onPropertiesChanged?.call();
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
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
          _showPropertiesDialog(context);
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
                          child: Icon(_iconForType(widget.node.type),
                              size: 18, color: widget.node.color),
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