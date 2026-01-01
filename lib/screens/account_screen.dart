// lib/screens/account_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'profile_edit_screen.dart'; // ✅ تأكد إن الملف موجود
import 'login_screen.dart'; // ← المسار الصحيح لشاشة تسجيل الدخول

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        backgroundColor: const Color(0xFF001F3F),
        foregroundColor: Colors.white,
        elevation: 6,
        centerTitle: true,
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
          child: Column(
            children: [
              // صورة الملف الشخصي مع تأثير glow
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF003366), Color(0xFF001F3F)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyan.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.transparent,
                        child: Icon(Icons.person, size: 60, color: Colors.white70),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.black87, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                user['name'] ?? 'غير محدد',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Text(
                user['role'] == 'client' ? 'عضو' : user['role'] ?? 'غير محدد',
                style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 40),

              // كروت المعلومات
              _buildInfoCard(Icons.email, 'البريد الإلكتروني', user['email'] ?? 'غير محدد'),
              const SizedBox(height: 16),
              _buildInfoCard(Icons.fitness_center, 'الدور', user['role'] == 'client' ? 'عميل' : 'غير محدد'),
              const SizedBox(height: 16),
              _buildInfoCard(Icons.calendar_today, 'تاريخ الانضمام', 'يناير 2026'), // يمكن تجيبه من الـ API لو موجود

              const SizedBox(height: 40),

              // زر تعديل الملف
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 24),
                  label: const Text('تعديل الملف الشخصي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF001F3F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 8,
                    shadowColor: Colors.black45,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // زر تسجيل الخروج
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF002244),
                        title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white)),
                        content: const Text('هل أنت متأكد من تسجيل الخروج؟', style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('نعم', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await auth.logout();
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) =>  LoginScreen()), // ← الحل الصحيح
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text('تسجيل الخروج', style: TextStyle(fontSize: 18, color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF003366), Color(0xFF002244)]),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 30),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}