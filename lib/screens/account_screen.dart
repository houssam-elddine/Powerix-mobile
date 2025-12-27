// lib/screens/account_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user ?? {};

    return Scaffold(
      appBar: AppBar(title: Text('حسابي')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('الاسم: ${user['name'] ?? 'غير محدد'}'),
            Text('البريد: ${user['email'] ?? 'غير محدد'}'),
            Text('الدور: ${user['role'] ?? 'غير محدد'}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await auth.logout();
                if (mounted) Navigator.pop(context);
              },
              child: Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );
  }
}