import 'package:flutter/material.dart';
import '../models/saved_map.dart';
import '../screens/saved_maps_screen.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.account_tree, size: 48, color: Colors.white),
              const SizedBox(height: 8),
              const Text(
                'FlowForge',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white38, thickness: 1),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.folder_open_rounded, color: Colors.white, size: 28),
                title: const Text(
                  'الخرائط المعلقة',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SavedMapsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              // يمكن إضافة أزرار أخرى هنا مستقبلاً
              const Spacer(),
              const Text(
                'v1.0',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}