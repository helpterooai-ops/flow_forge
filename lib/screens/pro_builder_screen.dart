import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/node_widget.dart';
import '../widgets/toast_widget.dart';
import '../models/saved_map.dart';
import 'builder_screen.dart';

class ProStep {
  String id;
  NodeType type;
  String title;
  String prompt;
  String variableName;
  String condition;
  bool isExpanded;

  ProStep({
    required this.id,
    required this.type,
    this.title = '',
    this.prompt = '',
    this.variableName = '',
    this.condition = '',
    this.isExpanded = true,
  });

  bool get isComplete {
    if (title.trim().isEmpty) return false;
    if (type == NodeType.input && prompt.trim().isEmpty) return false;
    return true;
  }

  Map<String, dynamic> toNodeJson(int index) {
    final colors = [
      0xFF6366F1,
      0xFF0EA5E9,
      0xFF10B981,
      0xFFF59E0B,
      0xFFF97316,
      0xFF8B5CF6
    ];
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'subtitle': '',
      'color': 'ff${colors[index % colors.length].toRadixString(16)}',
      'x': 200.0 + (index * 250),
      'y': 300.0,
      'variableName': variableName,
      'prompt': prompt,
      'isPaused': false,
      'fallbackNodeId': null,
    };
  }
}

class ProBuilderScreen extends StatefulWidget {
  const ProBuilderScreen({super.key});

  @override
  State<ProBuilderScreen> createState() => _ProBuilderScreenState();
}

class _ProBuilderScreenState extends State<ProBuilderScreen> {
  final List<ProStep> _steps = [];
  final Uuid _uuid = const Uuid();
  bool _showInstructions = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('pro_builder_instructions_seen') ?? false;
    if (!seen) {
      setState(() => _showInstructions = true);
      await prefs.setBool('pro_builder_instructions_seen', true);
    }
  }

  void _addStep(NodeType type) {
    setState(() {
      final step = ProStep(
        id: _uuid.v4(),
        type: type,
        title: type == NodeType.message
            ? 'رسالة جديدة'
            : (type == NodeType.input ? 'إدخال جديد' : 'تصنيف جديد'),
        prompt: type == NodeType.input ? 'أدخل السؤال هنا' : '',
        isExpanded: true,
      );
      for (final s in _steps) {
        s.isExpanded = false;
      }
      _steps.add(step);
    });
  }

  void _deleteStep(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  void _toggleExpanded(int index) {
    setState(() {
      _steps[index].isExpanded = !_steps[index].isExpanded;
    });
  }

  Map<String, dynamic> _buildFlowJson() {
    final nodes = <Map<String, dynamic>>[];
    final connections = <Map<String, dynamic>>[];

    for (int i = 0; i < _steps.length; i++) {
      final step = _steps[i];
      nodes.add(step.toNodeJson(i));

      if (i < _steps.length - 1) {
        connections.add({
          'id': _uuid.v4(),
          'from': step.id,
          'to': _steps[i + 1].id,
          if (step.type == NodeType.intent && step.condition.isNotEmpty)
            'condition': step.condition,
        });
      }
    }
    return {'nodes': nodes, 'connections': connections};
  }

  void _openInEditor() {
    if (_steps.isEmpty) {
      AppToast.show(context, 'أضف خطوة واحدة على الأقل', isError: true);
      return;
    }
    final flow = _buildFlowJson();
    final jsonData = jsonEncode(flow);
    final mapId = _uuid.v4();
    final mapName = 'خريطة Pro ${DateTime.now().millisecondsSinceEpoch}';
    final savedMap = SavedMap(id: mapId, name: mapName, jsonData: jsonData);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuilderScreen(savedMap: savedMap),
      ),
    );
  }

  void _saveToSideMenu() {
    if (_steps.length < 2) {
      AppToast.show(context, 'يجب إضافة عقدتين على الأقل للحفظ', isError: true);
      return;
    }
    final flow = _buildFlowJson();
    final jsonData = jsonEncode(flow);
    final mapId = _uuid.v4();
    final mapName = 'خريطة Pro ${DateTime.now().millisecondsSinceEpoch}';
    final savedMap = SavedMap(id: mapId, name: mapName, jsonData: jsonData);

    SharedPreferences.getInstance().then((prefs) {
      final data = prefs.getString('saved_maps');
      List<SavedMap> maps = [];
      if (data != null) {
        maps = (jsonDecode(data) as List)
            .map((e) => SavedMap.fromJson(e))
            .toList();
      }
      maps.add(savedMap);
      prefs.setString(
          'saved_maps', jsonEncode(maps.map((m) => m.toJson()).toList()));
    });
    AppToast.show(context, 'تم الحفظ في الخرائط المعلقة');
  }

  void _showJson() {
    final flow = _buildFlowJson();
    final jsonString = const JsonEncoder.withIndent('  ').convert(flow);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('JSON الخريطة'),
        content: SingleChildScrollView(
          child: SelectableText(jsonString,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('حسناً'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pro Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'عرض JSON',
            onPressed: _showJson,
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'فتح في المحرر',
            onPressed: _openInEditor,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'حفظ في الخرائط المعلقة',
            onPressed: _saveToSideMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showInstructions) _buildInstructions(),
          Expanded(
            child: _steps.isEmpty
                ? Center(
                    child: Text(
                      'اضغط + لإضافة الخطوة الأولى',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _steps.length,
                    itemBuilder: (context, index) {
                      return _buildStepItem(index);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة خطوة'),
        backgroundColor: const Color(0xFF6366F1),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('تعليمات',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue))
          ]),
          const SizedBox(height: 12),
          const Text('1. اختر نوع الخطوة (رسالة، إدخال، تصنيف).',
              style: TextStyle(fontSize: 13)),
          const Text('2. اكتب النص الذي سيقوله البوت.',
              style: TextStyle(fontSize: 13)),
          const Text('3. أضف خطوات أخرى لتكوين التدفق.',
              style: TextStyle(fontSize: 13)),
          const Text('4. اضغط "فتح في المحرر" لرؤية الخريطة.',
              style: TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: () => setState(() => _showInstructions = false),
              child: const Text('حسناً'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('نوع الخطوة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _typeOption(NodeType.message, 'رسالة', Iconsax.message,
                const Color(0xFF6366F1)),
            _typeOption(NodeType.input, 'إدخال مباشر', Iconsax.text_block,
                const Color(0xFFF97316)),
            _typeOption(NodeType.intent, 'تصنيف نية',
                Icons.psychology_rounded, const Color(0xFF8B5CF6)),
          ],
        ),
      ),
    );
  }

  Widget _typeOption(
      NodeType type, String label, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        _addStep(type);
      },
    );
  }

  Widget _buildStepItem(int index) {
    final step = _steps[index];
    final isComplete = step.isComplete;

    return Column(
      children: [
        if (index > 0) _buildArrow(isComplete: _steps[index - 1].isComplete),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Column(
              children: [
                InkWell(
                  onTap: () => _toggleExpanded(index),
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(step.isExpanded ? 16 : 16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                            isComplete
                                ? Icons.check_circle
                                : Icons.warning_amber,
                            color: isComplete ? Colors.green : Colors.red,
                            size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(
                                step.title.isEmpty ? 'بدون عنوان' : step.title,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: step.title.isEmpty
                                        ? Colors.grey
                                        : null))),
                        Text(_labelForType(step.type),
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                        const SizedBox(width: 8),
                        Icon(step.isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _deleteStep(index),
                          child: const Icon(Icons.close,
                              color: Colors.red, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                if (step.isExpanded)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        TextField(
                          decoration:
                              const InputDecoration(labelText: 'العنوان'),
                          controller: TextEditingController(text: step.title)
                            ..selection = TextSelection.collapsed(
                                offset: step.title.length),
                          onChanged: (val) =>
                              setState(() => step.title = val),
                        ),
                        const SizedBox(height: 12),
                        if (step.type == NodeType.input ||
                            step.type == NodeType.intent)
                          TextField(
                            decoration: const InputDecoration(
                                labelText: 'النص الإرشادي (Prompt)'),
                            controller: TextEditingController(text: step.prompt)
                              ..selection = TextSelection.collapsed(
                                  offset: step.prompt.length),
                            onChanged: (val) =>
                                setState(() => step.prompt = val),
                          ),
                        if (step.type == NodeType.input) ...[
                          const SizedBox(height: 12),
                          TextField(
                            decoration: const InputDecoration(
                                labelText: 'اسم المتغير'),
                            controller: TextEditingController(
                                text: step.variableName)
                              ..selection = TextSelection.collapsed(
                                  offset: step.variableName.length),
                            onChanged: (val) =>
                                setState(() => step.variableName = val),
                          ),
                        ],
                        if (step.type == NodeType.intent) ...[
                          const SizedBox(height: 12),
                          TextField(
                            decoration: const InputDecoration(
                                labelText: 'شرط الانتقال'),
                            controller: TextEditingController(
                                text: step.condition)
                              ..selection = TextSelection.collapsed(
                                  offset: step.condition.length),
                            onChanged: (val) =>
                                setState(() => step.condition = val),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArrow({required bool isComplete}) {
    return SizedBox(
      height: 30,
      child: Center(
        child: CustomPaint(
          size: const Size(2, 30),
          painter: isComplete
              ? _SolidArrowPainter(Colors.green)
              : _DashedArrowPainter(Colors.red),
        ),
      ),
    );
  }

  String _labelForType(NodeType type) {
    switch (type) {
      case NodeType.message:
        return 'رسالة';
      case NodeType.input:
        return 'إدخال';
      case NodeType.intent:
        return 'تصنيف';
      default:
        return '';
    }
  }
}

class _SolidArrowPainter extends CustomPainter {
  final Color color;
  _SolidArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(1, 0)
      ..lineTo(1, size.height - 10);
    canvas.drawPath(path, paint);
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final triangle = Path()
      ..moveTo(1, size.height)
      ..lineTo(1 - 4, size.height - 10)
      ..lineTo(1 + 4, size.height - 10)
      ..close();
    canvas.drawPath(triangle, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedArrowPainter extends CustomPainter {
  final Color color;
  _DashedArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    double startY = 0;
    while (startY < size.height - 10) {
      canvas.drawLine(Offset(1, startY), Offset(1, startY + 5), paint);
      startY += 10;
    }
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final triangle = Path()
      ..moveTo(1, size.height)
      ..lineTo(1 - 4, size.height - 10)
      ..lineTo(1 + 4, size.height - 10)
      ..close();
    canvas.drawPath(triangle, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}