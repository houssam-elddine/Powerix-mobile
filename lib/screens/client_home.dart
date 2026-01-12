import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import 'salle_details_screen.dart';
import 'my_inscriptions_screen.dart';
import 'account_screen.dart';

class ClientHome extends StatefulWidget {
  @override
  _ClientHomeState createState() => _ClientHomeState();
}

class _ClientHomeState extends State<ClientHome> {
  int _selectedIndex = 0;

  List<dynamic> salles = [];
  List<dynamic> courses = [];

  final Color primaryColor = Color(0xFF001F3F);
  final Color accentColor = Colors.white;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final sallesRes = await auth.apiRequest('salle', 'GET');
      final coursRes = await auth.apiRequest('cour', 'GET');

      if (mounted) {
        setState(() {
          salles = sallesRes.statusCode == 200 ? json.decode(sallesRes.body)['data'] ?? [] : [];
          courses = coursRes.statusCode == 200 ? json.decode(coursRes.body)['data'] ?? [] : [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement des données'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => MyInscriptionsScreen()));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AccountScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor, Color(0xFF002244), Color(0xFF001122)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: fetchData,
            color: accentColor,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),

                  Text(
                    'Bienvenue chez POWERIX',
                    style: TextStyle(color: accentColor, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Découvrez nos salles et nos cours',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  SizedBox(height: 30),

                  Text('Salles disponibles', style: TextStyle(color: accentColor, fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: salles.length,
                      itemBuilder: (ctx, i) {
                        final salle = salles[i];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SalleDetailsScreen(salleId: salle['id'], salleName: salle['nom']),
                              ),
                            );
                          },
                          child: Container(
                            width: 300,
                            margin: EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(colors: [Color(0xFF003366), Color(0xFF002244)]),
                              boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 6))],
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: CachedNetworkImage(
                                    imageUrl: 'http://192.168.1.15:8000/storage/${salle['img']}',
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(color: Colors.grey[800]),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 16,
                                  left: 16,
                                  right: 16,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(salle['nom'], style: TextStyle(color: accentColor, fontSize: 20, fontWeight: FontWeight.bold)),
                                      SizedBox(height: 4),
                                      Text(salle['address'], style: TextStyle(color: Colors.white70, fontSize: 14)),
                                      SizedBox(height: 4),
                                      Text('Capacité : ${salle['capacite']} personnes', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.95),
          boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: accentColor,
          unselectedItemColor: Colors.white60,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Accueil'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Mes inscriptions'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outlined), label: 'Compte'),
          ],
        ),
      ),
    );
  }
}