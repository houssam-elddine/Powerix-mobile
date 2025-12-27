// lib/screens/salle_details_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import 'cour_details_screen.dart'; // صفحة تفاصيل الدورة

class SalleDetailsScreen extends StatefulWidget {
  final int salleId;
  final String salleName;

  const SalleDetailsScreen({
    super.key,
    required this.salleId,
    required this.salleName,
  });

  @override
  State<SalleDetailsScreen> createState() => _SalleDetailsScreenState();
}

class _SalleDetailsScreenState extends State<SalleDetailsScreen> {
  List<dynamic> courses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCoursesOfSalle();
  }

  Future<void> fetchCoursesOfSalle() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      // افتراض أن لديك endpoint يجلب دورات الصالة: /api/salles/{id}/cours
      // إذا لم يكن موجودًا، يمكنك جلب كل الدورات وتصفيتها محليًا
      final response = await auth.apiRequest('cours', 'GET'); // أو 'salles/${widget.salleId}/cours'

      if (response.statusCode == 200) {
        final List<dynamic> allCourses = json.decode(response.body)['data'] ?? [];

        // تصفية الدورات التابعة لهذه الصالة
        final filteredCourses = allCourses.where((cour) => cour['salle_id'] == widget.salleId).toList();

        if (mounted) {
          setState(() {
            courses = filteredCourses;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحميل الدورات'), backgroundColor: Colors.redAccent),
        );
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('دورات صالة ${widget.salleName}'),
        backgroundColor: const Color(0xFF001F3F),
        foregroundColor: Colors.white,
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
            : courses.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد دورات متاحة في هذه الصالة',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: fetchCoursesOfSalle,
                    color: Colors.white,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: courses.length,
                      itemBuilder: (context, i) {
                        final cour = courses[i];
                        final abonnement = cour['abonnement'].isNotEmpty ? cour['abonnement'][0] : null;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CourDetailsScreen(cour: cour),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(colors: [Color(0xFF003366), Color(0xFF002244)]),
                              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 6))],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                                  child: CachedNetworkImage(
                                    imageUrl: 'http://192.168.1.15:8000/storage/${cour['img']}',
                                    width: 130,
                                    height: 160,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(color: Colors.grey[800]),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(cour['nom'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        Text('${cour['horaire_deb']} - ${cour['horaire_fin']}', style: const TextStyle(color: Colors.white70)),
                                        Text('سعة: ${cour['capacite']} شخص', style: const TextStyle(color: Colors.white70)),
                                        if (abonnement != null)
                                          Text(
                                            '${abonnement['nom']} • ${abonnement['prix']} د.م',
                                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Icon(Icons.arrow_forward_ios, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}