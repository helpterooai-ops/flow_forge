import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  String? _lastError;
  bool _hasAttemptedDeploy = false;

  // رابط الخادم الثابت (يمكن تغييره من الإعدادات لاحقاً)
  String _serverUrl = 'https://flow-forge-server.vercel.app';

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',   // ✅ فارغ تماماً
      language: python,
    );
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _botTokenController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _toggleTokenVisibility() {
    setState(() {
      _tokenVisible = !_tokenVisible;
    });
  }

  Future<void> _deployProject() async {
    if (_botTokenController.text.trim().isEmpty) {
      AppToast.show(context, 'الرجاء إدخال توكن البوت', isError: true);
      return;
    }
    if (_codeController.text.trim().isEmpty) {
      AppToast.show(context, 'الرجاء كتابة كود البوت', isError: true);
      return;
    }

    setState(() {
      _isDeploying = true;
      _lastError = null;
      _hasAttemptedDeploy = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/api/v1/deploy'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'projectName': _projectNameController.text.trim().isNotEmpty
              ? _projectNameController.text.trim()
              : 'my-bot',
          'botToken': _botTokenController.text.trim(),
          'pythonCode': _codeController.text,
        }),
      );

      if (response.statusCode == 200) {
        AppToast.show(context, 'تم نشر البوت بنجاح! وهو الآن شغال على تيليجرام.');
        setState(() {
          _lastError = null;
          _hasAttemptedDeploy = false;
        });
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _lastError = data['error'] ?? 'خطأ غير معروف من الخادم';
        });
      }
    } catch (e) {
      setState(() {
        _lastError = 'تعذر الاتصال بالخادم. تأكد من اتصالك بالإنترنت.';
      });
    } finally {
      setState(() {
        _isDeploying = false;
      });
    }
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
            // اسم المشروع
            Text('اسم المشروع (اختياري)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _projectNameController,
              decoration: InputDecoration(
                hintText: 'مثلاً: بوت المساعدة',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // توكن البوت
            Text('توكن البوت *', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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

            // كود بايثون
            Text('كود بايثون *', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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

            // حالة النشر
            if (_isDeploying)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    LinearProgressIndicator(color: theme.colorScheme.primary),
                    const SizedBox(height: 8),
                    Text('جاري النشر...', style: TextStyle(color: theme.colorScheme.primary)),
                  ],
                ),
              ),

            // رسالة الخطأ وزر إعادة المحاولة
            if (_hasAttemptedDeploy && _lastError != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _lastError!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _deployProject,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('إعادة المحاولة'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),

            // زر النشر
            if (!_isDeploying)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _deployProject,
                  icon: const Icon(Iconsax.cloud_change, size: 20),
                  label: const Text('نشر الآن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}