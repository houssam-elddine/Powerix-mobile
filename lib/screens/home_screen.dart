import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'client_home.dart';
import 'coach_home.dart';
import 'admin_home.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    Widget child;
    switch (auth.role) {
      case 'client':
        child = ClientHome();
        break;
      case 'admin':
        child = AdminHome();
        break;
      case 'coach':
        child = CoachHome();
        break;
      default:
        child = Center(child: Text('Unknown role'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Gym App'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
            },
          ),
        ],
      ),
      body: child,
    );
  }
}