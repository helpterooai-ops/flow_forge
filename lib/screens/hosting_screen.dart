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

  bool _tokenVisible = false;
  bool _isDeploying = false;
  String _deployStatus = '';

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('hosting_project');
    if (data != null) {
      final map = jsonDecode(data);
      _projectNameController.text = map['projectName'] ?? '';
      _botTokenController.text = map['botToken'] ?? '';
      _pythonCodeController.text = map['pythonCode'] ?? '';
    }
  }

  Future<void> _saveLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'projectName': _projectNameController.text.trim(),
      'botToken': _botTokenController.text.trim(),
      'pythonCode': _pythonCodeController.text,
    };
    await prefs.setString('hosting_project', jsonEncode(map));
  }

  void _toggleTokenVisibility() {
    setState(() {
      _tokenVisible = !_tokenVisible;
    });
  }

  Future<void> _deployProject() async {
    if (_projectNameController.text.trim().isEmpty ||
        _botTokenController.text.trim().isEmpty ||
        _pythonCodeController.text.isEmpty) {
      AppToast.show(context, 'جميع الحقول مطلوبة', isError: true);
      return;
    }

    setState(() {
      _isDeploying = true;
      _deployStatus = 'جاري النشر...';
    });

    try {
      final response = await http.post(
        Uri.parse('https://flow-forge-server.vercel.app/api/v1/deploy'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'projectName': _projectNameController.text.trim(),
          'botToken': _botTokenController.text.trim(),
          'pythonCode': _pythonCodeController.text,
        }),
      );

      if (response.statusCode == 200) {
        AppToast.show(context, 'تم نشر البوت بنجاح! وهو الآن شغال على تيليجرام.');
      } else {
        final data = jsonDecode(response.body);
        AppToast.show(context, data['error'] ?? 'فشل النشر', isError: true);
      }
    } catch (e) {
      AppToast.show(context, 'خطأ في الاتصال', isError: true);
    } finally {
      setState(() {
        _isDeploying = false;
        _deployStatus = '';
      });
    }
  }

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
            // اسم المشروع
            const Text('اسم المشروع', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _projectNameController,
              decoration: const InputDecoration(
                hintText: 'مثلاً: بوت المساعدة الخاص بي',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // توكن البوت
            const Text('توكن البوت', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _botTokenController,
              obscureText: !_tokenVisible,
              decoration: InputDecoration(
                hintText: 'أدخل التوكن من @BotFather',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_tokenVisible ? Iconsax.eye_slash : Iconsax.eye),
                  onPressed: _toggleTokenVisibility,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '⚠️ التوكن سري، لا تشاركه مع أحد.',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
            const SizedBox(height: 20),

            // كود بايثون
            const Text('كود بايثون', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _pythonCodeController,
              maxLines: 15,
              decoration: const InputDecoration(
                hintText: 'اكتب كود البوت هنا...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // حالة النشر
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

            // أزرار التحكم
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
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
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