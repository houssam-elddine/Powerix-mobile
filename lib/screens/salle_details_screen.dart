// lib/screens/salle_details_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import 'cour_details_screen.dart';

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
  Map<String, dynamic>? salleData;
  List<dynamic> courses = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchSalleDetails();
  }

  Future<void> fetchSalleDetails() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      // الـ endpoint الصحيح: /salles/{id}
      final response = await auth.apiRequest('salle/${widget.salleId}', 'GET');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 200 && jsonResponse['data'] != null) {
          final data = jsonResponse['data'];
          setState(() {
            salleData = data;
            courses = data['cours'] ?? []; // المصفوفة مباشرة داخل data
            isLoading = false;
          });
        } else {
          throw Exception('بيانات غير صالحة');
        }
      } else {
        throw Exception('فشل في جلب البيانات: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'فشل تحميل تفاصيل الصالة';
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
        title: Text('صالة ${widget.salleName}'),
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                        SizedBox(height: 16),
                        Text(errorMessage!, style: TextStyle(color: Colors.white70, fontSize: 18)),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: fetchSalleDetails,
                          child: Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: fetchSalleDetails,
                    color: Colors.white,
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // صورة الصالة الكبيرة
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CachedNetworkImage(
                              imageUrl: 'http://192.168.1.15:8000/storage/${salleData!['img']}',
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: Colors.grey[800], child: Center(child: CircularProgressIndicator(color: Colors.white))),
                              errorWidget: (_, __, ___) => Container(color: Colors.grey[800], child: Icon(Icons.broken_image, color: Colors.white70, size: 60)),
                            ),
                          ),

                          SizedBox(height: 20),

                          // معلومات الصالة
                          Text(salleData!['nom'], style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Row(children: [Icon(Icons.location_on, color: Colors.white70, size: 20), SizedBox(width: 8), Text(salleData!['address'], style: TextStyle(color: Colors.white70, fontSize: 16))]),
                          SizedBox(height: 8),
                          Row(children: [Icon(Icons.groups, color: Colors.white70, size: 20), SizedBox(width: 8), Text('سعة: ${salleData!['capacite']} شخص', style: TextStyle(color: Colors.white70, fontSize: 16))]),

                          SizedBox(height: 30),

                          // عنوان الدورات
                          Text('الدورات المتاحة في هذه الصالة', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          SizedBox(height: 12),

                          courses.isEmpty
                              ? Center(
                                  child: Text(
                                    'لا توجد دورات متاحة حالياً',
                                    style: TextStyle(color: Colors.white70, fontSize: 18),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: courses.length,
                                  itemBuilder: (context, i) {
                                    final cour = courses[i];
                                    final abonnement = cour['abonnement'] != null && (cour['abonnement'] as List).isNotEmpty
                                        ? cour['abonnement'][0]
                                        : null;

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

                          SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}