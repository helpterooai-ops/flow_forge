import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/toast_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _botToken = '';
  String _serverUrl = 'https://flow-forge-server.vercel.app';
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _botToken = prefs.getString('bot_token') ?? '';
      _serverUrl = prefs.getString('server_url') ?? 'https://flow-forge-server.vercel.app';
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  Future<void> _saveBotToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bot_token', value);
    setState(() => _botToken = value);
    AppToast.show(context, 'تم حفظ التوكن');
  }

  Future<void> _saveServerUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', value);
    setState(() => _serverUrl = value);
    AppToast.show(context, 'تم حفظ الرابط');
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() => _isDarkMode = value);
    AppToast.show(context, 'سيُطبق عند إعادة التشغيل');
  }

  Future<void> _clearAllMaps() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف جميع الخرائط المعلقة؟ لا يمكن التراجع.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_maps');
      AppToast.show(context, 'تم حذف جميع الخرائط');
    }
  }

  Future<void> _exportAllMaps() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('saved_maps');
    if (data == null) {
      AppToast.show(context, 'لا توجد خرائط لتصديرها', isError: true);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصدير جميع الخرائط'),
        content: SingleChildScrollView(
          child: SelectableText(data, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً'))],
      ),
    );
  }

  void _editBotToken() {
    final controller = TextEditingController(text: _botToken);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('توكن البوت'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Bot Token',
            hintText: 'أدخل التوكن من @BotFather',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () { _saveBotToken(controller.text.trim()); Navigator.pop(ctx); }, child: const Text('حفظ')),
        ],
      ),
    );
  }

  void _editServerUrl() {
    final controller = TextEditingController(text: _serverUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رابط الخادم'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Server URL',
            hintText: 'https://...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () { _saveServerUrl(controller.text.trim()); Navigator.pop(ctx); }, child: const Text('حفظ')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // قسم المظهر
          _SectionHeader(icon: Iconsax.brush_2, title: 'المظهر'),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              title: const Text('الوضع الداكن'),
              subtitle: const Text('تجربة مريحة للعين'),
              secondary: Icon(_isDarkMode ? Iconsax.moon : Iconsax.sun_1, color: theme.colorScheme.primary),
              value: _isDarkMode,
              onChanged: _toggleDarkMode,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          // قسم البوت
          _SectionHeader(icon: Iconsax.message_programming, title: 'إعدادات البوت'),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Iconsax.key, color: Colors.blue),
                  title: const Text('توكن البوت'),
                  subtitle: Text(_botToken.isEmpty ? 'غير مضبوط' : 'مضبوط ✓'),
                  trailing: const Icon(Iconsax.edit),
                  onTap: _editBotToken,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const Icon(Iconsax.global, color: Colors.green),
                  title: const Text('رابط الخادم'),
                  subtitle: Text(_serverUrl),
                  trailing: const Icon(Iconsax.edit),
                  onTap: _editServerUrl,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ],
            ),
          ),
          // قسم إدارة البيانات
          _SectionHeader(icon: Iconsax.folder_2, title: 'إدارة البيانات'),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Iconsax.export, color: Colors.blue),
                  title: const Text('تصدير جميع الخرائط'),
                  subtitle: const Text('حفظ كملف JSON'),
                  trailing: const Icon(Iconsax.arrow_right_3),
                  onTap: _exportAllMaps,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const Icon(Iconsax.trash, color: Colors.red),
                  title: const Text('حذف جميع الخرائط المعلقة'),
                  subtitle: const Text('لا يمكن التراجع'),
                  trailing: const Icon(Iconsax.arrow_right_3, color: Colors.red),
                  onTap: _clearAllMaps,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ],
            ),
          ),
          // قسم حول
          _SectionHeader(icon: Iconsax.info_circle, title: 'حول التطبيق'),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const ListTile(
              leading: Icon(Iconsax.code_1, color: Colors.purple),
              title: Text('FlowForge'),
              subtitle: Text('الإصدار 1.0.0'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}