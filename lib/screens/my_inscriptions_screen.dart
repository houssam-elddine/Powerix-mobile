// lib/screens/my_inscriptions_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class MyInscriptionsScreen extends StatefulWidget {
  @override
  _MyInscriptionsScreenState createState() => _MyInscriptionsScreenState();
}

class _MyInscriptionsScreenState extends State<MyInscriptionsScreen> {
  List<dynamic> inscriptions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchInscriptions();
  }

  Future<void> fetchInscriptions() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final response = await auth.apiRequest('inscription/${auth.userId}', 'GET');

    if (response.statusCode == 200) {
      setState(() {
        inscriptions = json.decode(response.body)['data'] ?? [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('اشتراكاتي')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchInscriptions,
              child: ListView.builder(
                itemCount: inscriptions.length,
                itemBuilder: (ctx, i) {
                  final ins = inscriptions[i];
                  return Card(
                    child: ListTile(
                      title: Text(ins['cour']['nom']),
                      subtitle: Text('الحالة: ${ins['etat']}'),
                    ),
                  );
                },
              ),
            ),
    );
  }
}