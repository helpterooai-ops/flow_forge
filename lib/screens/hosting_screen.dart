import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/python.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import '../widgets/toast_widget.dart';

class HostingScreen extends StatefulWidget {
  const HostingScreen({super.key});

  @override
  State<HostingScreen> createState() => _HostingScreenState();
}

class _HostingScreenState extends State<HostingScreen> {
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _botTokenController = TextEditingController();
  late final CodeController _codeController;

  bool _tokenVisible = false;
  bool _isDeploying = false;
  String _deployStatus = '';

  // ✅ تم تحديث الرابط إلى النفق الجديد
  String _serverUrl = 'https://daa1d2f666da19.lhr.life';

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: python,
    );
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('hosting_project');
    if (data != null) {
      final map = jsonDecode(data);
      _projectNameController.text = map['projectName'] ?? '';
      _botTokenController.text = map['botToken'] ?? '';
      _codeController.text = map['pythonCode'] ?? '';
    }
  }

  Future<void> _saveLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'projectName': _projectNameController.text.trim(),
      'botToken': _botTokenController.text.trim(),
      'pythonCode': _codeController.text,
    };
    await prefs.setString('hosting_project', jsonEncode(map));
    AppToast.show(context, 'تم الحفظ محلياً');
  }

  void _toggleTokenVisibility() {
    setState(() {
      _tokenVisible = !_tokenVisible;
    });
  }

  Future<void> _deployProject() async {
    if (_projectNameController.text.trim().isEmpty ||
        _botTokenController.text.trim().isEmpty ||
        _codeController.text.trim().isEmpty) {
      AppToast.show(context, 'جميع الحقول مطلوبة', isError: true);
      return;
    }

    setState(() {
      _isDeploying = true;
      _deployStatus = 'جاري النشر...';
    });

    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/api/v1/deploy'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'projectName': _projectNameController.text.trim(),
          'botToken': _botTokenController.text.trim(),
          'pythonCode': _codeController.text,
        }),
      );

      if (response.statusCode == 200) {
        AppToast.show(context, 'تم نشر البوت بنجاح! وهو الآن شغال على تيليجرام.');
      } else {
        final data = jsonDecode(response.body);
        AppToast.show(context, data['error'] ?? 'فشل النشر', isError: true);
      }
    } catch (e) {
      AppToast.show(context, 'خطأ في الاتصال بالخادم', isError: true);
    } finally {
      setState(() {
        _isDeploying = false;
        _deployStatus = '';
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _projectNameController.dispose();
    _botTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('استضافة البوتات'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('اسم المشروع', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _projectNameController,
              decoration: InputDecoration(
                hintText: 'بوت المساعدة',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            Text('توكن البوت', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _botTokenController,
              obscureText: !_tokenVisible,
              decoration: InputDecoration(
                hintText: 'أدخل التوكن من @BotFather',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: Icon(_tokenVisible ? Iconsax.eye_slash : Iconsax.eye),
                  onPressed: _toggleTokenVisibility,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text('كود بايثون', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              height: 300,
              child: CodeTheme(
                data: CodeThemeData(styles: atomOneDarkTheme),
                child: SingleChildScrollView(
                  child: CodeField(
                    controller: _codeController,
                    textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_isDeploying)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    LinearProgressIndicator(color: theme.colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(_deployStatus, style: TextStyle(color: theme.colorScheme.primary)),
                  ],
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isDeploying ? null : _saveLocally,
                    icon: const Icon(Iconsax.document_upload, size: 18),
                    label: const Text('حفظ محلياً'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isDeploying ? null : _deployProject,
                    icon: _isDeploying
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Iconsax.cloud_change, size: 18),
                    label: Text(_isDeploying ? 'جاري النشر...' : 'نشر الآن'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}