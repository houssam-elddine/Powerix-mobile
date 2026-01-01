// lib/screens/profile_edit_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordSection = false; // للتبديل بين تحديث البيانات وكلمة المرور

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nameController.text = auth.user?['name'] ?? '';
    _emailController.text = auth.user?['email'] ?? '';
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final response = await auth.apiRequest('profile/update', 'PUT', body: {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        auth.updateUser(data); // لو عندك دالة زي دي، أو notifyListeners()

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        final error = json.decode(response.body)['message'] ?? 'فشل التحديث';
        throw error;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمتا المرور غير متطابقتين'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final response = await auth.apiRequest('profile/password', 'PUT', body: {
        'current_password': _currentPasswordController.text,
        'new_password': _newPasswordController.text,
        'new_password_confirmation': _confirmPasswordController.text,
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح'), backgroundColor: Colors.green),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        final error = json.decode(response.body)['message'] ?? 'فشل تغيير كلمة المرور';
        throw error;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isPasswordSection ? 'تغيير كلمة المرور' : 'تعديل الملف الشخصي'),
        backgroundColor: const Color(0xFF001F3F),
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF001F3F), Color(0xFF002244), Color(0xFF001122)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // تبديل بين التحديث العادي وكلمة المرور
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTabButton('البيانات الشخصية', !_isPasswordSection),
                    const SizedBox(width: 20),
                    _buildTabButton('كلمة المرور', _isPasswordSection),
                  ],
                ),

                const SizedBox(height: 30),

                if (!_isPasswordSection) ...[
                  // تحديث الاسم والإيميل
                  _buildTextField(_nameController, 'الاسم الكامل', Icons.person),
                  const SizedBox(height: 20),
                  _buildTextField(
                    _emailController,
                    'البريد الإلكتروني',
                    Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 40),
                  _buildActionButton('حفظ التغييرات', _updateProfile),
                ] else ...[
                  // تغيير كلمة المرور
                  _buildTextField(_currentPasswordController, 'كلمة المرور الحالية', Icons.lock, obscureText: true),
                  const SizedBox(height: 20),
                  _buildTextField(_newPasswordController, 'كلمة المرور الجديدة', Icons.lock_outline, obscureText: true),
                  const SizedBox(height: 20),
                  _buildTextField(_confirmPasswordController, 'تأكيد كلمة المرور الجديدة', Icons.lock_outline, obscureText: true),
                  const SizedBox(height: 40),
                  _buildActionButton('تغيير كلمة المرور', _updatePassword),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => _isPasswordSection = !isActive),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white38),
        ),
        child: Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, bool obscureText = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white70, width: 2)),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
        if (label.contains('إلكتروني') && !value.contains('@')) return 'أدخل بريد إلكتروني صالح';
        return null;
      },
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF001F3F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 8,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Color(0xFF001F3F))
            : Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}