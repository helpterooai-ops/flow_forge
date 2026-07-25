import 'package:flutter/material.dart';
import '../screens/saved_maps_screen.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF6366F1)),
              child: Text(
                'FlowForge',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('الخرائط المعلقة'),
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
          ],
        ),
      ),
    );
  }
}