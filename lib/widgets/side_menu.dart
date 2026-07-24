cat > lib/widgets/side_menu.dart << 'EOF'
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedMap {
  final String id;
  String name;
  final String jsonData;

  SavedMap({required this.id, required this.name, required this.jsonData});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'jsonData': jsonData,
      };

  factory SavedMap.fromJson(Map<String, dynamic> json) => SavedMap(
        id: json['id'],
        name: json['name'],
        jsonData: json['jsonData'],
      );
}

class SideMenu extends StatefulWidget {
  final VoidCallback? onLoadMap;

  const SideMenu({super.key, this.onLoadMap});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
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

  void addMap(SavedMap map) {
    setState(() {
      final index = _maps.indexWhere((m) => m.id == map.id);
      if (index != -1) {
        _maps[index] = map;
      } else {
        _maps.add(map);
      }
    });
    _saveMaps();
  }

  void deleteMap(String id) {
    setState(() {
      _maps.removeWhere((m) => m.id == id);
    });
    _saveMaps();
  }

  void renameMap(String id, String newName) {
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
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'اسم الخريطة')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () { renameMap(id, controller.text.trim()); Navigator.pop(ctx); }, child: const Text('حفظ')),
        ],
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "$name"؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () { deleteMap(id); Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('الخرائط المعلقة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            Expanded(
              child: _maps.isEmpty
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
                                widget.onLoadMap?.call();
                                Navigator.pop(context);
                              } else if (value == 'rename') {
                                _showRenameDialog(map.id, map.name);
                              } else if (value == 'delete') {
                                _confirmDelete(map.id, map.name);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'edit', child: Text('متابعة التحرير')),
                              const PopupMenuItem(value: 'rename', child: Text('إعادة تسمية')),
                              const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
EOF