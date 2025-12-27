// lib/screens/coach_home.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';

class CoachHome extends StatefulWidget {
  @override
  _CoachHomeState createState() => _CoachHomeState();
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
      // جلب دورات المدرب
      final coursResponse = await auth.apiRequest(
        'coach/cours/${auth.userId}',
        'GET',
      );

      if (coursResponse.statusCode == 200) {
        final data = json.decode(coursResponse.body);
        myCourses = data['data'];
      }

      // جلب طلبات الاشتراك في دورات المدرب
      final insResponse = await auth.apiRequest(
        'coach/inscriptions',
        'GET',
      );

      if (insResponse.statusCode == 200) {
        final data = json.decode(insResponse.body);
        inscriptions = data['data'];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // دالة لتحديث حالة الاشتراك (قبول / رفض)
  Future<void> updateInscriptionStatus(int inscriptionId, String newStatus) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final response = await auth.apiRequest(
        'inscriptions/$inscriptionId',
        'PUT',
        body: {'etat': newStatus},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحديث الحالة بنجاح')),
        );
        fetchCoachData(); // تحديث القائمة
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحديث الحالة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchCoachData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'دوراتي',
                      style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                    ),
                    SizedBox(height: 12),
                    myCourses.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد دورات حالياً',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: myCourses.length,
                            itemBuilder: (ctx, i) {
                              final course = myCourses[i];
                              final abonnement = course['abonnement'].isNotEmpty
                                  ? course['abonnement'][0]
                                  : null;

                              return Card(
                                elevation: 4,
                                margin: EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.all(16),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          '${Provider.of<AuthProvider>(context, listen: false).baseUrl}/storage/${course['img'] ?? ''}',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(color: Colors.grey[300]),
                                      errorWidget: (context, url, error) => Icon(Icons.fitness_center, size: 40),
                                    ),
                                  ),
                                  title: Text(
                                    course['nom'],
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('الصالة: ${course['salle']['nom']}'),
                                      Text('الوقت: ${course['horaire_deb']} - ${course['horaire_fin']}'),
                                      if (abonnement != null)
                                        Text(
                                          'الاشتراك: ${abonnement['nom']} - ${abonnement['prix']} د.م / ${abonnement['duree']} أشهر',
                                          style: TextStyle(color: Colors.green[700]),
                                        ),
                                      Text('السعة: ${course['capacite']} شخص'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                    SizedBox(height: 32),

                    Text(
                      'طلبات الاشتراك في دوراتي',
                      style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                    ),
                    SizedBox(height: 12),
                    inscriptions.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد طلبات اشتراك حالياً',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: inscriptions.length,
                            itemBuilder: (ctx, i) {
                              final ins = inscriptions[i];
                              final client = ins['client'];
                              final course = ins['cour'];
                              final abonnement = ins['abonnement'];

                              return Card(
                                elevation: 3,
                                margin: EdgeInsets.symmetric(vertical: 6),
                                color: ins['etat'] == 'valider'
                                    ? Colors.green[50]
                                    : ins['etat'] == 'annuler'
                                        ? Colors.red[50]
                                        : Colors.orange[50],
                                child: ExpansionTile(
                                  title: Text(
                                    '${client['name']} - ${course['nom']}',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    'الحالة: ${ins['etat'] == 'en attente' ? 'في الانتظار' : ins['etat'] == 'valider' ? 'مقبول' : ins['etat'] == 'annuler' ? 'مرفوض' : 'بدون دفع'}',
                                    style: TextStyle(
                                      color: ins['etat'] == 'valider'
                                          ? Colors.green
                                          : ins['etat'] == 'annuler'
                                              ? Colors.red
                                              : Colors.orange,
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('التاريخ: ${ins['date_inscription']}'),
                                          Text('الاشتراك: ${abonnement['nom']} (${abonnement['prix']} د.م)'),
                                          SizedBox(height: 12),
                                          if (ins['etat'] == 'en attente')
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                ElevatedButton(
                                                  onPressed: () => updateInscriptionStatus(ins['id'], 'valider'),
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                                  child: Text('قبول', style: TextStyle(color: Colors.white)),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () => updateInscriptionStatus(ins['id'], 'annuler'),
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                  child: Text('رفض', style: TextStyle(color: Colors.white)),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}