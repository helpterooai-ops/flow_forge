import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  }

  Future<void> _saveServerUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', value);
    setState(() => _serverUrl = value);
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() => _isDarkMode = value);
    AppToast.show(context, 'سيتم تطبيق الثيم عند إعادة التشغيل');
  }

  Future<void> _clearAllMaps() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف جميع الخرائط المعلقة؟ لا يمكن التراجع.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف الكل')),
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
    // عرض JSON كامل
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        children: [
          // قسم المظهر
          const _SectionHeader(title: 'المظهر'),
          SwitchListTile(
            title: const Text('الوضع الداكن'),
            subtitle: const Text('تجربة مريحة للعين'),
            value: _isDarkMode,
            onChanged: _toggleDarkMode,
          ),
          const Divider(),
          // قسم إعدادات البوت
          const _SectionHeader(title: 'إعدادات البوت'),
          ListTile(
            title: const Text('توكن البوت الافتراضي'),
            subtitle: Text(_botToken.isEmpty ? 'غير مضبوط' : 'مضبوط'),
            trailing: const Icon(Icons.edit),
            onTap: () => _editBotToken(),
          ),
          ListTile(
            title: const Text('رابط الخادم'),
            subtitle: Text(_serverUrl),
            trailing: const Icon(Icons.edit),
            onTap: () => _editServerUrl(),
          ),
          const Divider(),
          // قسم إدارة البيانات
          const _SectionHeader(title: 'إدارة البيانات'),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.red),
            title: const Text('حذف جميع الخرائط المعلقة'),
            subtitle: const Text('لا يمكن التراجع عن هذا الإجراء'),
            onTap: _clearAllMaps,
          ),
          ListTile(
            leading: const Icon(Icons.ios_share, color: Colors.blue),
            title: const Text('تصدير جميع الخرائط'),
            subtitle: const Text('حفظ جميع الخرائط كملف JSON'),
            onTap: _exportAllMaps,
          ),
          const Divider(),
          // قسم حول
          const _SectionHeader(title: 'حول التطبيق'),
          const ListTile(
            title: Text('FlowForge'),
            subtitle: Text('الإصدار 1.0.0'),
          ),
        ],
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
          decoration: const InputDecoration(labelText: 'Bot Token', hintText: 'أدخل التوكن من @BotFather'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () {
            _saveBotToken(controller.text.trim());
            Navigator.pop(ctx);
          }, child: const Text('حفظ')),
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
          decoration: const InputDecoration(labelText: 'Server URL', hintText: 'https://...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () {
            _saveServerUrl(controller.text.trim());
            Navigator.pop(ctx);
          }, child: const Text('حفظ')),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}