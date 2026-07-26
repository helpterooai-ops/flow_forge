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

  // الرابط الثابت لخادم FlowForge على Vercel
  final String _serverUrl = 'https://flow-forge-server.vercel.app';

  // الكود الافتراضي الجاهز الذي يعمل على Vercel (مع nest-asyncio)
  final String _defaultCode = '''import os
from flask import Flask, request
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters
import asyncio
import nest_asyncio
nest_asyncio.apply()

TOKEN = os.environ.get('BOT_TOKEN')

application = Application.builder().token(TOKEN).build()

async def start(update, context):
    await update.message.reply_text(f'أهلاً بك يا {update.effective_user.first_name}!')

async def echo(update, context):
    await update.message.reply_text(f'قلت: {update.message.text}')

application.add_handler(CommandHandler('start', start))
application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, echo))

app = Flask(__name__)

@app.route('/api/bot', methods=['POST'])
def webhook():
    data = request.get_json()
    update = Update.de_json(data, application.bot)
    asyncio.run(application.process_update(update))
    return 'OK'

@app.route('/')
def home():
    return 'Bot is running!'
''';

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: _defaultCode,
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
      if (map['pythonCode'] != null && map['pythonCode'].toString().isNotEmpty) {
        _codeController.text = map['pythonCode'];
      }
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
    if (_botTokenController.text.trim().isEmpty) {
      AppToast.show(context, 'الرجاء إدخال توكن البوت', isError: true);
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
          'projectName': _projectNameController.text.trim().isNotEmpty
              ? _projectNameController.text.trim()
              : 'my-bot',
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
            // تنبيه أن الكود جاهز
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'الكود جاهز! فقط أدخل توكن البوت واضغط نشر الآن.',
                      style: TextStyle(fontSize: 13, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),

            // اسم المشروع
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

            // توكن البوت
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

            // كود بايثون (محرر الأكواد)
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

            // حالة النشر
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

            // أزرار التحكم
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