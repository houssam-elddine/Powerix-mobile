// lib/screens/admin_home.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

extension ListExtension on List {
  dynamic firstWhereOrNull(bool Function(dynamic) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
class AdminHome extends StatefulWidget {
  @override
  _AdminHomeState createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AuthProvider authProvider;

  List<dynamic> salles = [];
  List<dynamic> courses = [];
  List<dynamic> users = [];
  List<dynamic> inscriptions = [];
  bool isLoading = true;

  final Color primaryColor = Color(0xFF001F3F);
  final Color accentColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final sallesRes = await authProvider.apiRequest('salles', 'GET');
      final coursRes = await authProvider.apiRequest('cours', 'GET');
      final usersRes = await authProvider.apiRequest('users', 'GET');
      final insRes = await authProvider.apiRequest('inscriptions', 'GET');

      if (!mounted) return;

      setState(() {
        salles = sallesRes.statusCode == 200 ? json.decode(sallesRes.body)['data'] ?? [] : [];
        courses = coursRes.statusCode == 200 ? json.decode(coursRes.body)['data'] ?? [] : [];
        users = usersRes.statusCode == 200 ? json.decode(usersRes.body)['data'] ?? [] : [];
        inscriptions = insRes.statusCode == 200 ? json.decode(insRes.body)['data'] ?? [] : [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

Future<void> addSalle() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final nomCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final capaciteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إضافة صالة جديدة', textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nomCtrl, decoration: InputDecoration(labelText: 'اسم الصالة', border: OutlineInputBorder())),
            SizedBox(height: 12),
            TextField(controller: addressCtrl, decoration: InputDecoration(labelText: 'العنوان', border: OutlineInputBorder())),
            SizedBox(height: 12),
            TextField(controller: capaciteCtrl, decoration: InputDecoration(labelText: 'السعة', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nomCtrl.text.isEmpty || addressCtrl.text.isEmpty || capaciteCtrl.text.isEmpty) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('املأ جميع الحقول')));
                return;
              }

              var request = http.MultipartRequest('POST', Uri.parse('${authProvider.baseUrl}/salles'));
              request.headers['Authorization'] = 'Bearer ${authProvider.token}';
              request.fields['nom'] = nomCtrl.text;
              request.fields['address'] = addressCtrl.text;
              request.fields['capacite'] = capaciteCtrl.text;
              request.files.add(await http.MultipartFile.fromPath('img', image.path));

              final response = await request.send();
              if (!mounted) return;

              if (response.statusCode == 201) {
                Navigator.pop(ctx);
                fetchAllData();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إضافة الصالة بنجاح'), backgroundColor: Colors.green));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الإضافة'), backgroundColor: Colors.red));
              }
            },
            child: Text('إضافة'),
          ),
        ],
      ),
    );
  }

  // إضافة دورة مع عدة اشتراكات (array)
  Future<void> addCourse() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final nomCtrl = TextEditingController();
    final horaireDebCtrl = TextEditingController();
    final horaireFinCtrl = TextEditingController();
    final capaciteCtrl = TextEditingController();

    // قائمة ديناميكية للاشتراكات
    List<Map<String, TextEditingController>> abonnements = [
      {'nom': TextEditingController(), 'prix': TextEditingController(), 'duree': TextEditingController()}
    ];

    final sallesRes = await authProvider.apiRequest('salles', 'GET');
    final coachesRes = await authProvider.apiRequest('users', 'GET');
    List<dynamic> sallesList = sallesRes.statusCode == 200 ? json.decode(sallesRes.body)['data'] ?? [] : [];
    List<dynamic> coachesList = coachesRes.statusCode == 200
        ? (json.decode(coachesRes.body)['data'] as List).where((u) => u['role'] == 'coach').toList()
        : [];

    dynamic? selectedSalle;
    dynamic? selectedCoach;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          void addAbonnementField() {
            setStateDialog(() {
              abonnements.add({'nom': TextEditingController(), 'prix': TextEditingController(), 'duree': TextEditingController()});
            });
          }

          void removeAbonnementField(int index) {
            setStateDialog(() {
              abonnements.removeAt(index);
            });
          }

          return AlertDialog(
            title: Text('إضافة دورة جديدة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<dynamic>(
                    decoration: InputDecoration(labelText: 'المدرب', border: OutlineInputBorder()),
                    items: coachesList.map((coach) => DropdownMenuItem(value: coach, child: Text(coach['name']))).toList(),
                    onChanged: (value) => setStateDialog(() => selectedCoach = value),
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<dynamic>(
                    decoration: InputDecoration(labelText: 'الصالة', border: OutlineInputBorder()),
                    items: sallesList.map((salle) => DropdownMenuItem(value: salle, child: Text(salle['nom']))).toList(),
                    onChanged: (value) => setStateDialog(() => selectedSalle = value),
                  ),
                  SizedBox(height: 12),
                  TextField(controller: nomCtrl, decoration: InputDecoration(labelText: 'اسم الدورة', border: OutlineInputBorder())),
                  SizedBox(height: 12),
TextField(
  controller: horaireDebCtrl,
  readOnly: true,
  decoration: InputDecoration(
    labelText: 'وقت البداية',
    suffixIcon: Icon(Icons.access_time),
    border: OutlineInputBorder(),
  ),
  onTap: () async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      horaireDebCtrl.text = '$hour:$minute'; // ✔ HH:mm
    }
  },
),
                  SizedBox(height: 12),
                  TextField(
  controller: horaireFinCtrl,
  readOnly: true,
  decoration: InputDecoration(
    labelText: 'وقت النهاية',
    suffixIcon: Icon(Icons.access_time),
    border: OutlineInputBorder(),
  ),
  onTap: () async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      horaireFinCtrl.text = '$hour:$minute'; // ✔ HH:mm
    }
  },
),

                  SizedBox(height: 12),
                  TextField(controller: capaciteCtrl, decoration: InputDecoration(labelText: 'السعة', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                  SizedBox(height: 20),

                  // قسم الاشتراكات المتعددة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('الاشتراكات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(icon: Icon(Icons.add_circle, color: Colors.green), onPressed: addAbonnementField),
                    ],
                  ),
                  ...abonnements.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var controllers = entry.value;
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          children: [
                            TextField(controller: controllers['nom'], decoration: InputDecoration(labelText: 'اسم الاشتراك', border: OutlineInputBorder())),
                            SizedBox(height: 8),
                            TextField(controller: controllers['prix'], decoration: InputDecoration(labelText: 'السعر', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                            SizedBox(height: 8),
                            TextField(controller: controllers['duree'], decoration: InputDecoration(labelText: 'المدة (بالأشهر)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                            if (abonnements.length > 1)
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () => removeAbonnementField(idx),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء')),
              ElevatedButton(
  onPressed: selectedCoach == null || selectedSalle == null || abonnements.isEmpty
      ? null
      : () async {
          // التحقق من الحقول الأساسية
          if (nomCtrl.text.isEmpty || horaireDebCtrl.text.isEmpty || horaireFinCtrl.text.isEmpty || capaciteCtrl.text.isEmpty) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('املأ جميع الحقول الأساسية')));
            return;
          }

          // التحقق من حقول الاشتراكات
          for (var ab in abonnements) {
            if (ab['nom']!.text.isEmpty || ab['prix']!.text.isEmpty || ab['duree']!.text.isEmpty) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('املأ جميع حقول الاشتراكات')));
              return;
            }
          }

          var request = http.MultipartRequest('POST', Uri.parse('${authProvider.baseUrl}/cours'));
          request.headers['Authorization'] = 'Bearer ${authProvider.token}';

          // الحقول العادية
          request.fields['coach_id'] = selectedCoach['id'].toString();
          request.fields['salle_id'] = selectedSalle['id'].toString();
          request.fields['nom'] = nomCtrl.text;
          request.fields['horaire_deb'] = horaireDebCtrl.text;
          request.fields['horaire_fin'] = horaireFinCtrl.text;
          request.fields['capacite'] = capaciteCtrl.text;

          // إرسال abonnements كـ array بطريقة Laravel الصحيحة
          for (int i = 0; i < abonnements.length; i++) {
            request.fields['abonnements[$i][nom]'] = abonnements[i]['nom']!.text;
            request.fields['abonnements[$i][prix]'] = abonnements[i]['prix']!.text;
            request.fields['abonnements[$i][duree]'] = abonnements[i]['duree']!.text;
          }

          // إضافة الصورة
          request.files.add(await http.MultipartFile.fromPath('img', image.path));

          final response = await request.send();

          if (!mounted) return;

          if (response.statusCode == 201) {
            Navigator.pop(ctx);
            fetchAllData();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تم إضافة الدورة مع الاشتراكات بنجاح'), backgroundColor: Colors.green),
            );
          } else {
            // لمعرفة الخطأ بالضبط (مفيد للـ debug)
            final respBody = await response.stream.bytesToString();
            print('Error Response: $respBody'); // شاهد هذا في console

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('فشل الإضافة: تأكد من البيانات'), backgroundColor: Colors.red),
            );
          }
        },
  child: Text('إضافة'),
),
            ],
          );
        },
      ),
    );
  }

  // إضافة مدرب (بدون تغيير)
  Future<void> addCoach() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إضافة مدرب جديد'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'الاسم', border: OutlineInputBorder())),
          SizedBox(height: 12),
          TextField(controller: emailCtrl, decoration: InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
          SizedBox(height: 12),
          TextField(controller: passwordCtrl, decoration: InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder()), obscureText: true),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final response = await authProvider.apiRequest('users', 'POST', body: {
                'name': nameCtrl.text,
                'email': emailCtrl.text,
                'password': passwordCtrl.text,
                'role': 'coach',
              });

              if (!mounted) return;

              if (response.statusCode == 201) {
                Navigator.pop(ctx);
                fetchAllData();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إضافة المدرب بنجاح'), backgroundColor: Colors.green));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل إضافة المدرب'), backgroundColor: Colors.red));
              }
            },
            child: Text('إضافة'),
          ),
        ],
      ),
    );
  }

// ==================== دالة حذف عامة ====================
  Future<void> deleteItem(String endpoint) async {
    try {
      await authProvider.apiRequest(endpoint, 'DELETE');
      fetchAllData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم الحذف بنجاح'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الحذف'), backgroundColor: Colors.red),
      );
    }
  }
  
  // ==================== تعديل صالة ====================
  void editSalle(Map<dynamic, dynamic> salle) async {
    final picker = ImagePicker();
    XFile? newImage;
    final nomCtrl = TextEditingController(text: salle['nom']);
    final addressCtrl = TextEditingController(text: salle['address']);
    final capaciteCtrl = TextEditingController(text: salle['capacite'].toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تعديل الصالة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomCtrl, decoration: InputDecoration(labelText: 'اسم الصالة')),
              SizedBox(height: 12),
              TextField(controller: addressCtrl, decoration: InputDecoration(labelText: 'العنوان')),
              SizedBox(height: 12),
              TextField(controller: capaciteCtrl, decoration: InputDecoration(labelText: 'السعة'), keyboardType: TextInputType.number),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  newImage = await picker.pickImage(source: ImageSource.gallery);
                  if (newImage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم اختيار صورة جديدة')));
                  }
                },
                child: Text('تغيير الصورة'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              var request = http.MultipartRequest('POST', Uri.parse('${authProvider.baseUrl}/salles/${salle['id']}'));
              request.headers['Authorization'] = 'Bearer ${authProvider.token}';

              request.fields['nom'] = nomCtrl.text;
              request.fields['address'] = addressCtrl.text;
              request.fields['capacite'] = capaciteCtrl.text;

              if (newImage != null) {
                request.files.add(await http.MultipartFile.fromPath('img', newImage!.path));
              }

              final response = await request.send();

              if (response.statusCode == 200) {
                Navigator.pop(ctx);
                fetchAllData();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تعديل الصالة بنجاح'), backgroundColor: Colors.green));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التعديل'), backgroundColor: Colors.red));
              }
            },
            child: Text('حفظ'),
          ),
        ],
      ),
    );
  }

  // ==================== تعديل دورة ====================
void editCourse(Map<dynamic, dynamic> originalCour) async {
  final picker = ImagePicker();
  XFile? newImage;

  final nomCtrl = TextEditingController(text: originalCour['nom']);
  final horaireDebCtrl = TextEditingController(text: originalCour['horaire_deb']);
  final horaireFinCtrl = TextEditingController(text: originalCour['horaire_fin']);
  final capaciteCtrl = TextEditingController(text: originalCour['capacite'].toString());

  // جلب البيانات اللازمة
  final sallesRes = await authProvider.apiRequest('salles', 'GET');
  final coachesRes = await authProvider.apiRequest('users', 'GET');
  List<dynamic> sallesList = sallesRes.statusCode == 200 ? json.decode(sallesRes.body)['data'] ?? [] : [];
  List<dynamic> coachesList = coachesRes.statusCode == 200
      ? (json.decode(coachesRes.body)['data'] as List).where((u) => u['role'] == 'coach').toList()
      : [];

  dynamic? selectedSalle = sallesList.firstWhereOrNull((s) => s['id'] == originalCour['salle_id']);
  dynamic? selectedCoach = coachesList.firstWhereOrNull((c) => c['id'] == originalCour['coach_id']);

  // نسخ الاشتراكات الحالية للتعديل
  List<Map<String, dynamic>> abonnements = (originalCour['abonnement'] as List<dynamic>? ?? [])
      .map((ab) => {
            'id': ab['id'],
            'nom': TextEditingController(text: ab['nom']),
            'prix': TextEditingController(text: ab['prix'].toString()),
            'duree': TextEditingController(text: ab['duree'].toString()),
          })
      .toList();

  // إضافة حقل اشتراك جديد فارغ للإمكانية
  void addNewAbonnement() {
    setState(() {
      abonnements.add({
        'nom': TextEditingController(),
        'prix': TextEditingController(),
        'duree': TextEditingController(),
      });
    });
  }

  void removeAbonnement(int index) {
    setState(() {
      abonnements.removeAt(index);
    });
  }

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          title: Text('تعديل الدورة: ${originalCour['nom']}'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // اختيار المدرب
                  DropdownButtonFormField<dynamic>(
                    value: selectedCoach,
                    decoration: InputDecoration(labelText: 'المدرب', border: OutlineInputBorder()),
                    items: coachesList.map((coach) => DropdownMenuItem(value: coach, child: Text(coach['name']))).toList(),
                    onChanged: (value) => setStateDialog(() => selectedCoach = value),
                  ),
                  SizedBox(height: 12),

                  // اختيار الصالة
                  DropdownButtonFormField<dynamic>(
                    value: selectedSalle,
                    decoration: InputDecoration(labelText: 'الصالة', border: OutlineInputBorder()),
                    items: sallesList.map((salle) => DropdownMenuItem(value: salle, child: Text(salle['nom']))).toList(),
                    onChanged: (value) => setStateDialog(() => selectedSalle = value),
                  ),
                  SizedBox(height: 12),

                  TextField(controller: nomCtrl, decoration: InputDecoration(labelText: 'اسم الدورة', border: OutlineInputBorder())),
                  SizedBox(height: 12),
                  TextField(controller: horaireDebCtrl, decoration: InputDecoration(labelText: 'وقت البداية (HH:MM)', border: OutlineInputBorder())),
                  SizedBox(height: 12),
                  TextField(controller: horaireFinCtrl, decoration: InputDecoration(labelText: 'وقت النهاية (HH:MM)', border: OutlineInputBorder())),
                  SizedBox(height: 12),
                  TextField(controller: capaciteCtrl, decoration: InputDecoration(labelText: 'السعة', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                  SizedBox(height: 20),

                  // تغيير الصورة
                  ElevatedButton.icon(
                    icon: Icon(Icons.image),
                    label: Text('تغيير الصورة'),
                    onPressed: () async {
                      newImage = await picker.pickImage(source: ImageSource.gallery);
                      if (newImage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم اختيار صورة جديدة')));
                      }
                    },
                  ),
                  SizedBox(height: 20),

                  // الاشتراكات
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('الاشتراكات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(icon: Icon(Icons.add_circle, color: Colors.green), onPressed: addNewAbonnement),
                    ],
                  ),

                  ...abonnements.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var ab = entry.value;
                    bool isNew = ab['id'] == null; // جديد إذا لم يكن له id

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          children: [
                            TextField(controller: ab['nom'], decoration: InputDecoration(labelText: 'اسم الاشتراك', border: OutlineInputBorder())),
                            SizedBox(height: 8),
                            TextField(controller: ab['prix'], decoration: InputDecoration(labelText: 'السعر', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                            SizedBox(height: 8),
                            TextField(controller: ab['duree'], decoration: InputDecoration(labelText: 'المدة (بالأشهر)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                            if (!isNew || abonnements.length > 1)
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () => removeAbonnement(idx),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء')),
            ElevatedButton(
              onPressed: selectedCoach == null || selectedSalle == null
                  ? null
                  : () async {
                      // التحقق من الحقول الأساسية
                      if (nomCtrl.text.isEmpty || horaireDebCtrl.text.isEmpty || horaireFinCtrl.text.isEmpty || capaciteCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('املأ الحقول الأساسية')));
                        return;
                      }

                      var request = http.MultipartRequest('POST', Uri.parse('${authProvider.baseUrl}/cours/${originalCour['id']}'));
                      request.headers.addAll({
  'Authorization': 'Bearer ${authProvider.token}',
  'Accept': 'application/json', // ← هذا السطر مهم جدًا!
});


                      request.fields['coach_id'] = selectedCoach['id'].toString();
                      request.fields['salle_id'] = selectedSalle['id'].toString();
                      request.fields['nom'] = nomCtrl.text;
                      request.fields['horaire_deb'] = horaireDebCtrl.text;
                      request.fields['horaire_fin'] = horaireFinCtrl.text;
                      request.fields['capacite'] = capaciteCtrl.text;

                      // إرسال الصورة إذا تم اختيار واحدة جديدة
                      if (newImage != null) {
                        request.files.add(await http.MultipartFile.fromPath('img', newImage!.path));
                      }

                      // إرسال الاشتراكات
                      for (int i = 0; i < abonnements.length; i++) {
                        var ab = abonnements[i];
                        if (ab['nom'].text.isEmpty || ab['prix'].text.isEmpty || ab['duree'].text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('املأ جميع حقول الاشتراكات')));
                          return;
                        }

                        final prefix = 'abonnements[$i]';
                        if (ab['id'] != null) {
                          request.fields['$prefix[id]'] = ab['id'].toString();
                        }
                        request.fields['$prefix[nom]'] = ab['nom'].text;
                        request.fields['$prefix[prix]'] = ab['prix'].text;
                        request.fields['$prefix[duree]'] = ab['duree'].text;
                      }

                      final response = await request.send();
                      final respBody = await response.stream.bytesToString();
print('Status Code: ${response.statusCode}');
print('Response Body: $respBody');
                      if (!mounted) return;

                      if (response.statusCode == 200) {
                        Navigator.pop(ctx);
                        fetchAllData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تم تعديل الدورة بنجاح'), backgroundColor: Colors.green),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${response.statusCode}'), backgroundColor: Colors.red),
                        );
                      }
                    },
              child: Text('حفظ التعديلات'),
            ),
          ],
        );
      },
    ),
  );
}

  // ==================== تعديل مستخدم (مدرب) ====================
  void editUser(Map<dynamic, dynamic> user) async {
    final nameCtrl = TextEditingController(text: user['name']);
    final emailCtrl = TextEditingController(text: user['email']);
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تعديل المدرب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'الاسم')),
            SizedBox(height: 12),
            TextField(controller: emailCtrl, decoration: InputDecoration(labelText: 'البريد الإلكتروني'), keyboardType: TextInputType.emailAddress),
            SizedBox(height: 12),
            TextField(controller: passwordCtrl, decoration: InputDecoration(labelText: 'كلمة المرور (اتركه فارغًا إذا لا تريد تغييرها)'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Map<String, dynamic> body = {
                'name': nameCtrl.text,
                'email': emailCtrl.text,
              };
              if (passwordCtrl.text.isNotEmpty) {
                body['password'] = passwordCtrl.text;
              }

              final response = await authProvider.apiRequest('users/${user['id']}', 'PUT', body: body);

              if (response.statusCode == 200) {
                Navigator.pop(ctx);
                fetchAllData();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تعديل المدرب بنجاح'), backgroundColor: Colors.green));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التعديل'), backgroundColor: Colors.red));
              }
            },
            child: Text('حفظ'),
          ),
        ],
      ),
    );
  }

  // ==================== تعديل حالة الاشتراك ====================
  void editInscriptionStatus(Map<dynamic, dynamic> inscription) async {
    String? newStatus = inscription['etat'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تغيير حالة الاشتراك'),
        content: DropdownButton<String>(
          value: newStatus,
          items: ['en attente', 'sans payée', 'valider', 'annuler'].map((status) {
            return DropdownMenuItem(value: status, child: Text(status == 'valider' ? 'مقبول' : status == 'annuler' ? 'مرفوض' : status == 'sans payée' ? 'بدون دفع' : 'في الانتظار'));
          }).toList(),
          onChanged: (val) => newStatus = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final response = await authProvider.apiRequest('inscriptions/${inscription['id']}', 'PUT', body: {'etat': newStatus});

              if (response.statusCode == 200) {
                Navigator.pop(ctx);
                fetchAllData();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تحديث الحالة'), backgroundColor: Colors.green));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التحديث'), backgroundColor: Colors.red));
              }
            },
            child: Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: Text('لوحة تحكم POWERIX', style: TextStyle(fontWeight: FontWeight.bold, color: accentColor)),
        backgroundColor: primaryColor.withOpacity(0.9),
        elevation: 4,
        shadowColor: Colors.black45,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: accentColor,
          unselectedLabelColor: Colors.white60,
          indicatorColor: accentColor,
          indicatorWeight: 4,
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'الصالات'),
            Tab(text: 'الدورات'),
            Tab(text: 'المستخدمين'),
            Tab(text: 'الاشتراكات'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentColor,
        foregroundColor: primaryColor,
        elevation: 10,
        child: Icon(Icons.add, size: 32),
        onPressed: () {
          final index = _tabController.index;
          if (index == 0) addSalle();
          else if (index == 1) addCourse();
          else if (index == 2) addCoach();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor, strokeWidth: 5))
          : TabBarView(
              controller: _tabController,
              children: [
                // الصالات - مع زر تعديل
                salles.isEmpty
                    ? Center(child: Text('لا توجد صالات', style: TextStyle(color: Colors.white70, fontSize: 18)))
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: salles.length,
                        itemBuilder: (ctx, i) {
                          final salle = salles[i];
                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(colors: [Color(0xFF003366), Color(0xFF002244)]),
                              boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 6))],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: 'http://192.168.1.15:8000/storage/${salle['img'] ?? ''}',
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(salle['nom'], style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 18)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(salle['address'], style: TextStyle(color: Colors.white70)),
                                  Text('سعة: ${salle['capacite']} شخص', style: TextStyle(color: Colors.white70)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blueAccent),
                                    onPressed: () => editSalle(salle),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_forever, color: Colors.redAccent),
                                    onPressed: () => deleteItem('salles/${salle['id']}'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                // الدورات - مع زر تعديل (مؤقتًا معلق)
                courses.isEmpty
                    ? Center(child: Text('لا توجد دورات', style: TextStyle(color: Colors.white70, fontSize: 18)))
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: courses.length,
                        itemBuilder: (ctx, i) {
                          final cour = courses[i];
                          final salle = cour['salle'] ?? {};
                          final firstAbonnement = cour['abonnement']?.isNotEmpty == true ? cour['abonnement'][0] : null;

                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(colors: [Color(0xFF003366), Color(0xFF002244)]),
                              boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 6))],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: 'http://192.168.1.15:8000/storage/${cour['img'] ?? ''}',
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(cour['nom'], style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 18)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('في: ${salle['nom'] ?? 'غير محدد'}', style: TextStyle(color: Colors.white70)),
                                  Text('${cour['horaire_deb']} - ${cour['horaire_fin']}', style: TextStyle(color: Colors.white70)),
                                  Text('سعة: ${cour['capacite']} شخص', style: TextStyle(color: Colors.white70)),
                                  if (firstAbonnement != null)
                                    Text('${firstAbonnement['nom']} • ${firstAbonnement['prix']} د.م', style: TextStyle(color: Colors.greenAccent)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blueAccent),
                                    onPressed: () => editCourse(cour), // يمكن تطويره لاحقًا
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_forever, color: Colors.redAccent),
                                    onPressed: () => deleteItem('cours/${cour['id']}'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                // المستخدمين - مع زر تعديل
                users.isEmpty
                    ? Center(child: Text('لا يوجد مستخدمين', style: TextStyle(color: Colors.white70, fontSize: 18)))
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: users.length,
                        itemBuilder: (ctx, i) {
                          final user = users[i];
                          final roleText = user['role'] == 'coach' ? 'مدرب' : user['role'] == 'admin' ? 'أدمن' : 'عميل';

                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(colors: [Color(0xFF003366), Color(0xFF002244)]),
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: CircleAvatar(child: Icon(Icons.person, color: accentColor)),
                              title: Text(user['name'], style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                              subtitle: Text('$roleText • ${user['email']}', style: TextStyle(color: Colors.white70)),
                              trailing: user['role'] != 'admin'
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit, color: Colors.blueAccent),
                                          onPressed: () => editUser(user),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete_forever, color: Colors.redAccent),
                                          onPressed: () => deleteItem('users/${user['id']}'),
                                        ),
                                      ],
                                    )
                                  : Icon(Icons.admin_panel_settings, color: Colors.amber),
                            ),
                          );
                        },
                      ),

                // الاشتراكات - مع زر تعديل الحالة
                inscriptions.isEmpty
                    ? Center(child: Text('لا توجد اشتراكات', style: TextStyle(color: Colors.white70, fontSize: 18)))
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: inscriptions.length,
                        itemBuilder: (ctx, i) {
                          final ins = inscriptions[i];
                          final clientName = ins['client']?['name'] ?? 'عميل محذوف';
                          final courName = ins['cour']?['nom'] ?? 'دورة محذوفة';
                          final abonnementName = ins['abonnement']?['nom'] ?? 'اشتراك';

                          final status = switch (ins['etat'] ?? 'en attente') {
                            'valider' => 'مقبول',
                            'annuler' => 'مرفوض',
                            'sans payée' => 'بدون دفع',
                            _ => 'في الانتظار',
                          };

                          final statusColor = switch (ins['etat'] ?? 'en attente') {
                            'valider' => Colors.green,
                            'annuler' => Colors.red,
                            _ => Colors.orange,
                          };

                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(colors: [Color(0xFF003366), Color(0xFF002244)]),
                              boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 6))],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: statusColor.withOpacity(0.3),
                                child: Icon(Icons.assignment_turned_in, color: statusColor),
                              ),
                              title: Text('$clientName → $courName → $abonnementName', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                              subtitle: Text('التاريخ: ${ins['date_inscription'] ?? 'غير معروف'}', style: TextStyle(color: Colors.white70)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit_note, color: Colors.blueAccent),
                                    onPressed: () => editInscriptionStatus(ins),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: statusColor),
                                    ),
                                    child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}