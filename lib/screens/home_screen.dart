import 'package:flutter/material.dart';
import 'builder_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlowForge'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'إنشاء خريطة جديدة',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BuilderScreen()),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('لا توجد خرائط بعد. اضغط + للبدء.'),
      ),
    );
  }
}
