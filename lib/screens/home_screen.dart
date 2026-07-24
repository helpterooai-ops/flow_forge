import 'dart:convert';
import 'package:flutter/material.dart';
import 'builder_screen.dart';
import '../widgets/side_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SideMenu _sideMenu = const SideMenu();

  void _openMap(SavedMap map) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuilderScreen(savedMap: map),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('FlowForge'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
              ),
              tooltip: 'إنشاء خريطة جديدة',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BuilderScreen()),
                );
              },
            ),
          ),
        ],
      ),
      drawer: _sideMenu,
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_tree_rounded, size: 64, color: Color(0xFFB0BEC5)),
            SizedBox(height: 16),
            Text(
              'لا توجد خرائط بعد',
              style: TextStyle(fontSize: 16, color: Color(0xFF78909C)),
            ),
            SizedBox(height: 8),
            Text(
              'اضغط + لبدء تصميم أول خريطة ذهنية',
              style: TextStyle(fontSize: 14, color: Color(0xFFB0BEC5)),
            ),
          ],
        ),
      ),
    );
  }
}