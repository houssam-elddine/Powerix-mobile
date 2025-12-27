// lib/screens/cour_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';

class CourDetailsScreen extends StatefulWidget {
  final Map<dynamic, dynamic> cour;

  const CourDetailsScreen({super.key, required this.cour});

  @override
  State<CourDetailsScreen> createState() => _CourDetailsScreenState();
}

class _CourDetailsScreenState extends State<CourDetailsScreen> {
  int? selectedAbonnementId;

  Future<void> subscribe() async {
    if (selectedAbonnementId == null) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      await auth.apiRequest('inscription', 'POST', body: {
        'client_id': auth.userId,
        'cour_id': widget.cour['id'],
        'abonnement_id': selectedAbonnementId,
        'date_inscription': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم الاشتراك بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل الاشتراك: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cour = widget.cour;
    final salle = cour['salle'] as Map? ?? {};
    final abonnements = (cour['abonnement'] as List<dynamic>?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(cour['nom'] ?? 'دورة'),
        backgroundColor: const Color(0xFF001F3F),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF001F3F),
              Color(0xFF002244),
              Color(0xFF001122),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة الدورة
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: 'http://192.168.1.15:8000/storage/${cour['img'] ?? ''}',
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.fitness_center, color: Colors.white, size: 60),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // معلومات أساسية
              Text(
                cour['nom'] ?? 'غير معروف',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'الصالة: ${salle['nom'] ?? 'غير محدد'}',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              Text(
                'الوقت: ${cour['horaire_deb'] ?? ''} - ${cour['horaire_fin'] ?? ''}',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              Text(
                'السعة: ${cour['capacite'] ?? '?'} شخص',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),

              const SizedBox(height: 32),

              // قسم الاشتراكات
              const Text(
                'اختر نوع الاشتراك',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              if (abonnements.isEmpty)
                const Text(
                  'لا توجد اشتراكات متاحة لهذه الدورة',
                  style: TextStyle(color: Colors.orange, fontSize: 16),
                ),

              ...abonnements.map((ab) {
                final id = ab['id'];
                final nom = ab['nom'] ?? 'اشتراك';
                final prix = ab['prix'] ?? '0';
                final duree = ab['duree'] ?? 0;

                return Card(
                  color: const Color(0xFF002244),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: RadioListTile<int>(
                    title: Text(
                      '$nom • $prix د.م / $duree ${duree == 1 ? 'شهر' : 'أشهر'}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    value: id,
                    groupValue: selectedAbonnementId,
                    activeColor: Colors.greenAccent,
                    onChanged: (value) {
                      setState(() => selectedAbonnementId = value);
                    },
                  ),
                );
              }).toList(),

              const SizedBox(height: 40),

              // زر التسجيل
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: selectedAbonnementId == null ? null : subscribe,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'تأكيد الاشتراك',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 8,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}