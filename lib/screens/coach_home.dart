import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import 'profile_edit_screen.dart';

class CoachHome extends StatefulWidget {
  const CoachHome({super.key});

  @override
  State<CoachHome> createState() => _CoachHomeState();
}

class _CoachHomeState extends State<CoachHome> {
  List<dynamic> myCourses = [];
  List<dynamic> inscriptions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCoachData();
  }

  Future<void> fetchCoachData() async {
    setState(() => isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final coursRes = await auth.apiRequest('coach/cours/${auth.userId}', 'GET');
      final insRes = await auth.apiRequest('coach/inscriptions', 'GET');

      if (coursRes.statusCode == 200) {
        myCourses = json.decode(coursRes.body)['data'] ?? [];
      }
      if (insRes.statusCode == 200) {
        inscriptions = json.decode(insRes.body)['data'] ?? [];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des données : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1620) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Tableau de bord Coach'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F1620) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0D47A1),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchCoachData,
        color: const Color(0xFF26A69A),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text(
                        'Mes cours',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0D47A1),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: myCourses.isEmpty
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 60),
                              child: Center(
                                child: Text(
                                  'Aucun cours enregistré pour le moment',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => _CourseCard(course: myCourses[i]),
                              childCount: myCourses.length,
                            ),
                          ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Text(
                        'Demandes d\'inscription',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0D47A1),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: inscriptions.isEmpty
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 60),
                              child: Center(
                                child: Text(
                                  'Aucune demande d\'inscription pour le moment',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => _InscriptionCard(
                                inscription: inscriptions[i],
                              ),
                              childCount: inscriptions.length,
                            ),
                          ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;

  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final abonnements = (course['abonnement'] as List?) ?? [];
    final salle = course['salle'] ?? {};

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: isDark ? Colors.black54 : Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1A2332) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: '${auth.baseUrl}/storage/${course['img'] ?? ''}',
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey[300]),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.fitness_center_rounded,
                      size: 48,
                      color: Color(0xFF26A69A),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['nom'] ?? 'Cours sans nom',
                        style: TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Salle • ${salle['nom'] ?? 'Non spécifiée'}',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${course['horaire_deb'] ?? '--:--'} – ${course['horaire_fin'] ?? '--:--'}',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Capacité • ${course['capacite'] ?? '?'} personnes',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (abonnements.isNotEmpty) ...[
              const Divider(height: 28, thickness: 0.8),
              Text(
                'Forfaits disponibles',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                  color: isDark ? Colors.grey[300] : const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: abonnements.map<Widget>((ab) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF26A69A).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF26A69A).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${ab['nom'] ?? '?'} • ${ab['prix'] ?? '—'} DA (${ab['duree'] ?? '?'} mois)',
                      style: const TextStyle(
                        color: Color(0xFF00695C),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InscriptionCard extends StatelessWidget {
  final Map<String, dynamic> inscription;

  const _InscriptionCard({required this.inscription});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final client = inscription['client'] ?? {};
    final cour = inscription['cour'] ?? {};
    final abonnement = (cour['abonnement'] as List<dynamic>?)?.firstOrNull ?? {};

    final etat = inscription['etat'] ?? 'en attente';

    Color statusColor;
    String statusText;

    switch (etat) {
      case 'valider':
        statusColor = const Color(0xFF10B981);
        statusText = 'Accepté';
        break;
      case 'annuler':
        statusColor = const Color(0xFFEF4444);
        statusText = 'Refusé';
        break;
      case 'sans payée':
        statusColor = const Color(0xFFF59E0B);
        statusText = 'Non payé';
        break;
      default:
        statusColor = const Color(0xFFF97316);
        statusText = 'En attente';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: isDark ? Colors.black54 : Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1A2332) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: statusColor.withOpacity(0.15),
                  child: Icon(Icons.person_rounded, color: statusColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client['name'] ?? 'Utilisateur supprimé',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        cour['nom'] ?? 'Cours supprimé',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          fontSize: 14.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 28, thickness: 0.8),
            Row(
              children: [
                Icon(Icons.card_membership_rounded,
                    size: 18, color: const Color(0xFF26A69A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${abonnement['nom'] ?? '—'} • ${abonnement['prix'] ?? '—'} DA • ${abonnement['duree'] ?? '—'} mois',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[300] : const Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Date de la demande : ${inscription['date_inscription'] ?? 'Inconnue'}',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
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