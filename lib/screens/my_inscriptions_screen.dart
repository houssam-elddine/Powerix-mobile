import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';

class MyInscriptionsScreen extends StatefulWidget {
  const MyInscriptionsScreen({super.key});

  @override
  State<MyInscriptionsScreen> createState() => _MyInscriptionsScreenState();
}

class _MyInscriptionsScreenState extends State<MyInscriptionsScreen> {
  List<dynamic> inscriptions = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchInscriptions();
  }

  Future<void> fetchInscriptions() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final response = await auth.apiRequest('inscription/${auth.userId}', 'GET');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] ?? [];
        setState(() {
          inscriptions = data;
          isLoading = false;
        });
      } else {
        throw Exception('Échec du chargement des inscriptions');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Échec du chargement des inscriptions';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage!), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes inscriptions'),
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                        const SizedBox(height: 16),
                        Text(errorMessage!, style: const TextStyle(color: Colors.white70, fontSize: 18)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: fetchInscriptions, child: const Text('Réessayer')),
                      ],
                    ),
                  )
                : inscriptions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fitness_center, color: Colors.white38, size: 80),
                            SizedBox(height: 20),
                            Text('Aucune inscription pour le moment', style: TextStyle(color: Colors.white70, fontSize: 20)),
                            Text('Commencez votre parcours sportif maintenant !', style: TextStyle(color: Colors.white54, fontSize: 16)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchInscriptions,
                        color: Colors.white,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: inscriptions.length,
                          itemBuilder: (context, i) {
                            final ins = inscriptions[i];
                            final cour = ins['cour'];
                            final abonnement = ins['abonnement'];

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(colors: [Color(0xFF003366), Color(0xFF002244)]),
                                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 8))],
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: CachedNetworkImage(
                                      imageUrl: 'http://192.168.1.15:8000/storage/${cour['img']}',
                                      height: 220,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      color: Colors.black.withOpacity(0.4),
                                      colorBlendMode: BlendMode.darken,
                                      placeholder: (_, __) => Container(color: Colors.grey[800]),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cour['nom'],
                                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${cour['horaire_deb']} - ${cour['horaire_fin']}',
                                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Abonnement : ${abonnement['nom']} • ${abonnement['prix']} DA',
                                            style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                ins['etat'] == 'valider' ? Icons.check_circle : Icons.pending,
                                                color: ins['etat'] == 'valider' ? Colors.greenAccent : Colors.orangeAccent,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Statut : ${ins['etat'] == 'valider' ? 'Confirmé' : 'En attente'}',
                                                style: TextStyle(color: ins['etat'] == 'valider' ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}