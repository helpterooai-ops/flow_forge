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
          label: 'عقدة ${_nodes.length + 1}',
          position: const Offset(200, 200),
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
            icon: const Icon(Icons.add),
            tooltip: 'إضافة عقدة',
            onPressed: _addNode,
          ),
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
            children: _nodes.map((node) => NodeWidget(node: node)).toList(),
          ),
        ),
      ),
    );
  }
}
