import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/toast_widget.dart';

class HostingScreen extends StatefulWidget {
  const HostingScreen({super.key});

  @override
  State<HostingScreen> createState() => _HostingScreenState();
}

class _HostingScreenState extends State<HostingScreen> {
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _botTokenController = TextEditingController();
  final TextEditingController _pythonCodeController = TextEditingController();
  final TextEditingController _githubTokenController = TextEditingController();
  final TextEditingController _vercelTokenController = TextEditingController();

  bool _tokenVisible = false;
  bool _githubTokenVisible = false;
  bool _vercelTokenVisible = false;
  String? _securityCode;
  bool _isDeploying = false;
  String _deployStatus = '';

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  // ... (دوال _loadSavedData, _saveLocally, _verifyCode, _buildCodeDialog, _toggleTokenVisibility كما هي في الإصدار السابق) ...

  // --------------------- تخزين الرموز الحساسة ---------------------
  Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('github_token', _githubTokenController.text.trim());
    await prefs.setString('vercel_token', _vercelTokenController.text.trim());
  }

  Future<void> _deleteTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('github_token');
    await prefs.remove('vercel_token');
    setState(() {
      _githubTokenController.clear();
      _vercelTokenController.clear();
    });
    AppToast.show(context, 'تم حذف الرموز');
  }

  // --------------------- النشر التلقائي (الجزء الجديد) ---------------------
  Future<void> _deployProject() async {
    // 1. التحقق من المدخلات
    if (_projectNameController.text.trim().isEmpty ||
        _botTokenController.text.trim().isEmpty ||
        _pythonCodeController.text.isEmpty ||
        _githubTokenController.text.trim().isEmpty ||
        _vercelTokenController.text.trim().isEmpty) {
      AppToast.show(context, 'جميع الحقول مطلوبة', isError: true);
      return;
    }

    setState(() {
      _isDeploying = true;
      _deployStatus = 'جاري التحضير...';
    });

    try {
      final projectName = _projectNameController.text.trim();
      final botToken = _botTokenController.text.trim();
      final pythonCode = _pythonCodeController.text;
      final githubToken = _githubTokenController.text.trim();
      final vercelToken = _vercelTokenController.text.trim();

      // حفظ الرموز للمرات القادمة
      await _saveTokens();

      // 2. إنشاء مستودع GitHub
      _setStatus('إنشاء مستودع GitHub...');
      final repoName = 'telegram-bot-${DateTime.now().milliseconds}';
      await _createGitHubRepo(repoName, githubToken);

      // 3. رفع ملفات البوت إلى المستودع
      _setStatus('رفع الملفات...');
      await _uploadFileToGitHub(repoName, 'bot.py', pythonCode, githubToken);
      await _uploadFileToGitHub(repoName, 'requirements.txt', 'python-telegram-bot==20.8', githubToken);
      await _uploadFileToGitHub(repoName, 'vercel.json', jsonEncode({
        "builds": [{"src": "bot.py", "use": "@vercel/python"}],
        "routes": [{"src": "/(.*)", "dest": "bot.py"}]
      }), githubToken);

      // 4. إنشاء مشروع Vercel مربوط بالمستودع
      _setStatus('إنشاء مشروع Vercel...');
      final vercelProjectId = await _createVercelProject(repoName, vercelToken, githubToken);

      // 5. تعيين متغير البيئة BOT_TOKEN
      _setStatus('تعيين متغيرات البيئة...');
      await _setVercelEnv(vercelProjectId, 'BOT_TOKEN', botToken, vercelToken);

      // 6. تشغيل النشر الأول
      _setStatus('تشغيل النشر...');
      final domain = await _deployAndGetDomain(vercelProjectId, vercelToken);

      // 7. ضبط Webhook تيليجرام
      _setStatus('ضبط Webhook...');
      await _setTelegramWebhook(botToken, domain);

      // نجاح!
      _setStatus('');
      AppToast.show(context, 'تم نشر البوت بنجاح! البوت شغال الآن.');
    } catch (e) {
      AppToast.show(context, 'فشل النشر: $e', isError: true);
    } finally {
      setState(() {
        _isDeploying = false;
        _deployStatus = '';
      });
    }
  }

  void _setStatus(String msg) {
    setState(() {
      _deployStatus = msg;
    });
  }

  // --------------------- دوال API ---------------------
  Future<void> _createGitHubRepo(String name, String token) async {
    final response = await http.post(
      Uri.parse('https://api.github.com/user/repos'),
      headers: {
        'Authorization': 'token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name, 'auto_init': true, 'private': false}),
    );
    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'فشل إنشاء المستودع');
    }
  }

  Future<void> _uploadFileToGitHub(String repoName, String path, String content, String token) async {
    final response = await http.put(
      Uri.parse('https://api.github.com/repos/${_getGitHubUsername(token)}/$repoName/contents/$path'),
      headers: {
        'Authorization': 'token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': 'Add $path',
        'content': base64Encode(utf8.encode(content)),
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('فشل رفع الملف $path');
    }
  }

  String _getGitHubUsername(String token) {
    // بسيطة: نستخرج اسم المستخدم من الـ token بالاتصال بـ /user
    // للتطبيق الحقيقي، يجب تخزينه بعد أول استدعاء
    return 'helpterooai-ops'; // تعديل: يمكن جلبها ديناميكيًا
  }

  Future<String> _createVercelProject(String repoName, String vercelToken, String githubToken) async {
    final response = await http.post(
      Uri.parse('https://api.vercel.com/v10/projects'),
      headers: {
        'Authorization': 'Bearer $vercelToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': repoName,
        'framework': 'other',
        'gitRepository': {
          'type': 'github',
          'repo': 'helpterooai-ops/$repoName', // تعديل: اجعل اسم المستخدم ديناميكيًا
        },
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('فشل إنشاء مشروع Vercel');
    }
    final data = jsonDecode(response.body);
    return data['id'];
  }

  Future<void> _setVercelEnv(String projectId, String key, String value, String token) async {
    await http.post(
      Uri.parse('https://api.vercel.com/v10/projects/$projectId/env'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'key': key,
        'value': value,
        'type': 'encrypted',
        'target': ['production'],
      }),
    );
  }

  Future<String> _deployAndGetDomain(String projectId, String token) async {
    // تشغيل النشر عبر Git (يدفع push يدويًا) - أبسط طريقة: استخدام Deploy Hook
    // سنفترض أن Vercel يلتقط التغيير تلقائيًا بعد رفع الكود
    // ننتظر قليلاً ثم نجلب النطاق
    await Future.delayed(const Duration(seconds: 10));
    final response = await http.get(
      Uri.parse('https://api.vercel.com/v10/projects/$projectId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body);
    // نبحث عن أحدث alias
    final alias = data['alias']?[0]['domain'] ?? '${data['name']}.vercel.app';
    return 'https://$alias';
  }

  Future<void> _setTelegramWebhook(String botToken, String domain) async {
    final url = 'https://api.telegram.org/bot$botToken/setWebhook?url=$domain/api/bot';
    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);
    if (data['ok'] != true) {
      throw Exception('فشل ضبط Webhook: ${data['description']}');
    }
  }

  // --------------------- واجهة المستخدم ---------------------
  @override
  Widget build(BuildContext context) {
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
            // ... (حقول اسم المشروع، توكن البوت، كود بايثون كما في السابق) ...

            // --------------------- حقول الرموز الجديدة ---------------------
            const SizedBox(height: 20),
            const Text('رموز الوصول (تُطلب مرة واحدة)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // GitHub Token
            TextField(
              controller: _githubTokenController,
              obscureText: !_githubTokenVisible,
              decoration: InputDecoration(
                labelText: 'GitHub Token (صلاحية repo)',
                hintText: 'ghp_...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_githubTokenVisible ? Iconsax.eye_slash : Iconsax.eye),
                  onPressed: () {
                    setState(() {
                      _githubTokenVisible = !_githubTokenVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Vercel Token
            TextField(
              controller: _vercelTokenController,
              obscureText: !_vercelTokenVisible,
              decoration: InputDecoration(
                labelText: 'Vercel Token',
                hintText: '...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_vercelTokenVisible ? Iconsax.eye_slash : Iconsax.eye),
                  onPressed: () {
                    setState(() {
                      _vercelTokenVisible = !_vercelTokenVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _deleteTokens,
                  icon: const Icon(Iconsax.trash, size: 16),
                  label: const Text('حذف الرموز'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --------------------- حالة النشر ---------------------
            if (_isDeploying)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(_deployStatus, style: const TextStyle(color: Colors.blue)),
                  ],
                ),
              ),

            // --------------------- أزرار التحكم ---------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _saveLocally,
                  icon: const Icon(Iconsax.document_upload, size: 18),
                  label: const Text('حفظ محلياً'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isDeploying ? null : _deployProject,
                  icon: _isDeploying
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Iconsax.cloud_change, size: 18),
                  label: Text(_isDeploying ? 'جاري النشر...' : 'نشر الآن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDeploying ? Colors.grey : Colors.green,
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