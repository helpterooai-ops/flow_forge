import 'package:flutter/material.dart';

class BuilderScreen extends StatefulWidget {
  const BuilderScreen({super.key});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محرر الخريطة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'إضافة عقدة',
            onPressed: () {
              // TODO: إضافة عقدة جديدة لاحقاً
            },
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
            children: const [
              // سنضيف العقد هنا لاحقاً
            ],
          ),
        ),
      ),
    );
  }
}
