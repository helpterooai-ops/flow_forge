import '../models/saved_map.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'builder_screen.dart';
import '../widgets/side_menu.dart';

class SavedMapsScreen extends StatefulWidget {
  const SavedMapsScreen({super.key});

  @override
  State<SavedMapsScreen> createState() => _SavedMapsScreenState();
}

class _SavedMapsScreenState extends State<SavedMapsScreen> {
  List<SavedMap> _maps = [];

  @override
  void initState() {
    super.initState();
    _loadMaps();
  }

  Future<void> _loadMaps() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('saved_maps');
    if (data != null) {
      final List<dynamic> list = jsonDecode(data);
      setState(() {
        _maps = list.map((e) => SavedMap.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveMaps() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_maps.map((m) => m.toJson()).toList());
    await prefs.setString('saved_maps', data);
  }

  void _deleteMap(String id) {
    setState(() {
      _maps.removeWhere((m) => m.id == id);
    });
    _saveMaps();
  }

  void _renameMap(String id, String newName) {
    setState(() {
      final map = _maps.firstWhere((m) => m.id == id);
      map.name = newName;
    });
    _saveMaps();
  }

  void _showRenameDialog(String id, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعادة تسمية'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'اسم الخريطة'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              _renameMap(id, controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
            'هل أنت متأكد من حذف "$name"؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteMap(id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الخرائط المعلقة'),
      ),
      body: _maps.isEmpty
          ? const Center(child: Text('لا توجد خرائط محفوظة'))
          : ListView.builder(
              itemCount: _maps.length,
              itemBuilder: (ctx, index) {
                final map = _maps[index];
                return ListTile(
                  leading: const Icon(Icons.account_tree_outlined),
                  title: Text(map.name, overflow: TextOverflow.ellipsis),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BuilderScreen(savedMap: map),
                          ),
                        );
                      } else if (value == 'rename') {
                        _showRenameDialog(map.id, map.name);
                      } else if (value == 'delete') {
                        _confirmDelete(map.id, map.name);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('متابعة التحرير'),
                      ),
                      const PopupMenuItem(
                        value: 'rename',
                        child: Text('إعادة تسمية'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child:
                            Text('حذف', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}