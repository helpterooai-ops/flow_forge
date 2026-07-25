import 'package:flutter/material.dart';
import '../screens/saved_maps_screen.dart';
import 'toast_widget.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6366F1).withOpacity(0.95),
              const Color(0xFF8B5CF6).withOpacity(0.95),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(-5, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.account_tree_rounded, size: 40, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'FlowForge',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'محرر تدفقات المحادثة الذكي',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildMenuItem(
                icon: Icons.folder_open_rounded,
                title: 'الخرائط المعلقة',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedMapsScreen()));
                },
              ),
              _buildMenuItem(
                icon: Icons.cloud_done_outlined,
                title: 'نشر إلى البوت',
                enabled: false,
                onTap: () {
                  Navigator.pop(context);
                  AppToast.show(context, 'قريباً...');
                },
              ),
              _buildMenuItem(
                icon: Icons.settings_outlined,
                title: 'الإعدادات',
                enabled: false,
                onTap: () {
                  Navigator.pop(context);
                  AppToast.show(context, 'قريباً...');
                },
              ),
              const Spacer(),
              const Text(
                'v1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: enabled ? Colors.transparent : Colors.white.withOpacity(0.05),
            ),
            child: Row(
              children: [
                Icon(icon, color: enabled ? Colors.white : Colors.white54, size: 24),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: enabled ? Colors.white : Colors.white38,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!enabled)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text(
                      'قريباً',
                      style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}