import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import 'profile_edit_screen.dart';

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
          SnackBar(content: Text('Erreur de chargement des données'), backgroundColor: Colors.redAccent),
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
        title: Text('Ajouter une nouvelle salle', textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nomCtrl, decoration: InputDecoration(labelText: 'Nom de la salle', border: OutlineInputBorder())),
            SizedBox(height: 12),
            TextField(controller: addressCtrl, decoration: InputDecoration(labelText: 'Adresse', border: OutlineInputBorder())),
            SizedBox(height: 12),
            TextField(controller: capaciteCtrl, decoration: InputDecoration(labelText: 'Capacité', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (nomCtrl.text.isEmpty || addressCtrl.text.isEmpty || capaciteCtrl.text.isEmpty) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veuillez remplir tous les champs')));
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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Salle ajoutée avec succès'), backgroundColor: Colors.green));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Échec de l\'ajout'), backgroundColor: Colors.red));
              }
            },
            child: Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> addCourse() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final nomCtrl = TextEditingController();
    final horaireDebCtrl = TextEditingController();
    final horaireFinCtrl = TextEditingController();
    final capaciteCtrl = TextEditingController();

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
            title: Text('Ajouter un nouveau cours'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<dynamic>(
                    decoration: InputDecoration(labelText: 'Coach', border: OutlineInputBorder()),
                    items: coachesList.map((coach) => DropdownMenuItem(value: coach, child: Text(coach['name']))).toList(),
                    onChanged: (value) => setStateDialog(() => selectedCoach = value),
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<dynamic>(
                    decoration: InputDecoration(labelText: 'Salle', border: OutlineInputBorder()),
                    items: sallesList.map((salle) => DropdownMenuItem(value: salle, child: Text(salle['nom']))).toList(),
                    onChanged: (value) => setStateDialog(() => selectedSalle = value),
                  ),
                  SizedBox(height: 12),
                  TextField(controller: nomCtrl, decoration: InputDecoration(labelText: 'Nom du cours', border: OutlineInputBorder())),
                  SizedBox(height: 12),
                  TextField(
                    controller: horaireDebCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Heure de début',
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
                        horaireDebCtrl.text = '$hour:$minute';
                      }
                    },
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: horaireFinCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Heure de fin',
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
                        horaireFinCtrl.text = '$hour:$minute';
                      }
                    },
                  ),
                  SizedBox(height: 12),
                  TextField(controller: capaciteCtrl, decoration: InputDecoration(labelText: 'Capacité', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Abonnements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                            TextField(controller: controllers['nom'], decoration: InputDecoration(labelText: 'Nom de l\'abonnement', border: OutlineInputBorder())),
                            SizedBox(height: 8),
                            TextField(controller: controllers['prix'], decoration: InputDecoration(labelText: 'Prix', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                            SizedBox(height: 8),
                            TextField(controller: controllers['duree'], decoration: InputDecoration(labelText: 'Durée (mois)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
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
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
              ElevatedButton(
                onPressed: selectedCoach == null || selectedSalle == null || abonnements.isEmpty
                    ? null
                    : () async {
                        if (nomCtrl.text.isEmpty || horaireDebCtrl.text.isEmpty || horaireFinCtrl.text.isEmpty || capaciteCtrl.text.isEmpty) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Remplissez tous les champs principaux')));
                          return;
                        }

                        for (var ab in abonnements) {
                          if (ab['nom']!.text.isEmpty || ab['prix']!.text.isEmpty || ab['duree']!.text.isEmpty) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Remplissez tous les champs des abonnements')));
                            return;
                          }
                        }

                        var request = http.MultipartRequest('POST', Uri.parse('${authProvider.baseUrl}/cours'));
                        request.headers['Authorization'] = 'Bearer ${authProvider.token}';

                        request.fields['coach_id'] = selectedCoach['id'].toString();
                        request.fields['salle_id'] = selectedSalle['id'].toString();
                        request.fields['nom'] = nomCtrl.text;
                        request.fields['horaire_deb'] = horaireDebCtrl.text;
                        request.fields['horaire_fin'] = horaireFinCtrl.text;
                        request.fields['capacite'] = capaciteCtrl.text;

                        for (int i = 0; i < abonnements.length; i++) {
                          request.fields['abonnements[$i][nom]'] = abonnements[i]['nom']!.text;
                          request.fields['abonnements[$i][prix]'] = abonnements[i]['prix']!.text;
                          request.fields['abonnements[$i][duree]'] = abonnements[i]['duree']!.text;
                        }

                        request.files.add(await http.MultipartFile.fromPath('img', image.path));

                        final response = await request.send();

                        if (!mounted) return;

                        if (response.statusCode == 201) {
                          Navigator.pop(ctx);
                          fetchAllData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Cours et abonnements ajoutés avec succès'), backgroundColor: Colors.green),
                          );
                        } else {
                          final respBody = await response.stream.bytesToString();
                          print('Error Response: $respBody');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Échec de l\'ajout'), backgroundColor: Colors.red),
                          );
                        }
                      },
                child: Text('Ajouter'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> addCoach() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ajouter un nouveau coach'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Nom', border: OutlineInputBorder())),
          SizedBox(height: 12),
          TextField(controller: emailCtrl, decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
          SizedBox(height: 12),
          TextField(controller: passwordCtrl, decoration: InputDecoration(labelText: 'Mot de passe', border: OutlineInputBorder()), obscureText: true),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Coach ajouté avec succès'), backgroundColor: Colors.green));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Échec de l\'ajout du coach'), backgroundColor: Colors.red));
              }
            },
            child: Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteItem(String endpoint) async {
    try {
      await authProvider.apiRequest(endpoint, 'DELETE');
      fetchAllData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Supprimé avec succès'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de la suppression'), backgroundColor: Colors.red),
      );
    }
  }

  void editSalle(Map<dynamic, dynamic> salle) async {
    final picker = ImagePicker();
    XFile? newImage;
    final nomCtrl = TextEditingController(text: salle['nom']);
    final addressCtrl = TextEditingController(text: salle['address']);
    final capaciteCtrl = TextEditingController(text: salle['capacite'].toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modifier la salle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomCtrl, decoration: InputDecoration(labelText: 'Nom de la salle')),
              SizedBox(height: 12),
              TextField(controller: addressCtrl, decoration: InputDecoration(labelText: 'Adresse')),
              SizedBox(height: 12),
              TextField(controller: capaciteCtrl, decoration: InputDecoration(labelText: 'Capacité'), keyboardType: TextInputType.number),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  newImage = await picker.pickImage(source: ImageSource.gallery);
                  if (newImage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nouvelle image sélectionnée')));
                  }
                },
                child: Text('Changer l\'image'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Salle modifiée avec succès'), backgroundColor: Colors.green));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Échec de la modification'), backgroundColor: Colors.red));
              }
            },
            child: Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void editCourse(Map<dynamic, dynamic> originalCour) async {
    final picker = ImagePicker();
    XFile? newImage;

    final nomCtrl = TextEditingController(text: originalCour['nom']);
    final horaireDebCtrl = TextEditingController(text: originalCour['horaire_deb']);
    final horaireFinCtrl = TextEditingController(text: originalCour['horaire_fin']);
    final capaciteCtrl = TextEditingController(text: originalCour['capacite'].toString());

    final sallesRes = await authProvider.apiRequest('salles', 'GET');
    final coachesRes = await authProvider.apiRequest('users', 'GET');
    List<dynamic> sallesList = sallesRes.statusCode == 200 ? json.decode(sallesRes.body)['data'] ?? [] : [];
    List<dynamic> coachesList = coachesRes.statusCode == 200
        ? (json.decode(coachesRes.body)['data'] as List).where((u) => u['role'] == 'coach').toList()
        : [];

    dynamic? selectedSalle = sallesList.firstWhereOrNull((s) => s['id'] == originalCour['salle_id']);
    dynamic? selectedCoach = coachesList.firstWhereOrNull((c) => c['id'] == originalCour['coach_id']);

    List<Map<String, dynamic>> abonnements = (originalCour['abonnement'] as List<dynamic>? ?? [])
        .map((ab) => {
              'id': ab['id'],
              'nom': TextEditingController(text: ab['nom']),
              'prix': TextEditingController(text: ab['prix'].toString()),
              'duree': TextEditingController(text: ab['duree'].toString()),
            })
        .toList();

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
      if (index < 0 || index >= abonnements.length) {
        print('Index invalide ignoré: $index (longueur = ${abonnements.length})');
        return;
      }

      setState(() {
        abonnements.removeAt(index);
      });
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Modifier le cours : ${originalCour['nom']}'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<dynamic>(
                      value: selectedCoach,
                      decoration: InputDecoration(labelText: 'Coach', border: OutlineInputBorder()),
                      items: coachesList.map((coach) => DropdownMenuItem(value: coach, child: Text(coach['name']))).toList(),
                      onChanged: (value) => setStateDialog(() => selectedCoach = value),
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<dynamic>(
                      value: selectedSalle,
                      decoration: InputDecoration(labelText: 'Salle', border: OutlineInputBorder()),
                      items: sallesList.map((salle) => DropdownMenuItem(value: salle, child: Text(salle['nom']))).toList(),
                      onChanged: (value) => setStateDialog(() => selectedSalle = value),
                    ),
                    SizedBox(height: 12),
                    TextField(controller: nomCtrl, decoration: InputDecoration(labelText: 'Nom du cours', border: OutlineInputBorder())),
                    SizedBox(height: 12),
                    TextField(controller: horaireDebCtrl, decoration: InputDecoration(labelText: 'Heure de début (HH:MM)', border: OutlineInputBorder())),
                    SizedBox(height: 12),
                    TextField(controller: horaireFinCtrl, decoration: InputDecoration(labelText: 'Heure de fin (HH:MM)', border: OutlineInputBorder())),
                    SizedBox(height: 12),
                    TextField(controller: capaciteCtrl, decoration: InputDecoration(labelText: 'Capacité', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: Icon(Icons.image),
                      label: Text('Changer l\'image'),
                      onPressed: () async {
                        newImage = await picker.pickImage(source: ImageSource.gallery);
                        if (newImage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nouvelle image sélectionnée')));
                        }
                      },
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Abonnements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(icon: Icon(Icons.add_circle, color: Colors.green), onPressed: addNewAbonnement),
                      ],
                    ),
                    ...abonnements.asMap().entries.map((entry) {
                      int idx = entry.key;
                      var ab = entry.value;
                      bool isNew = ab['id'] == null;

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            children: [
                              TextField(controller: ab['nom'], decoration: InputDecoration(labelText: 'Nom de l\'abonnement', border: OutlineInputBorder())),
                              SizedBox(height: 8),
                              TextField(controller: ab['prix'], decoration: InputDecoration(labelText: 'Prix', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                              SizedBox(height: 8),
                              TextField(controller: ab['duree'], decoration: InputDecoration(labelText: 'Durée (mois)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
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
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
              ElevatedButton(
                onPressed: selectedCoach == null || selectedSalle == null
                    ? null
                    : () async {
                        if (nomCtrl.text.isEmpty || horaireDebCtrl.text.isEmpty || horaireFinCtrl.text.isEmpty || capaciteCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Remplissez les champs principaux')));
                          return;
                        }

                        var request = http.MultipartRequest('post', Uri.parse('${authProvider.baseUrl}/cours/${originalCour['id']}'));
                        request.headers.addAll({
                          'Authorization': 'Bearer ${authProvider.token}',
                          'Accept': 'application/json',
                        });

                        request.fields['coach_id'] = selectedCoach['id'].toString();
                        request.fields['salle_id'] = selectedSalle['id'].toString();
                        request.fields['nom'] = nomCtrl.text;
                        request.fields['horaire_deb'] = horaireDebCtrl.text;
                        request.fields['horaire_fin'] = horaireFinCtrl.text;
                        request.fields['capacite'] = capaciteCtrl.text;

                        if (newImage != null) {
                          request.files.add(await http.MultipartFile.fromPath('img', newImage!.path));
                        }

                        for (int i = 0; i < abonnements.length; i++) {
                          var ab = abonnements[i];
                          if (ab['nom'].text.isEmpty || ab['prix'].text.isEmpty || ab['duree'].text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Remplissez tous les champs des abonnements')));
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
                            SnackBar(content: Text('Cours modifié avec succès'), backgroundColor: Colors.green),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur : ${respBody}'), backgroundColor: Colors.red),
                          );
                        }
                      },
                child: Text('Enregistrer les modifications'),
              ),
            ],
          );
        },
      ),
    );
  }

  void editUser(Map<dynamic, dynamic> user) async {
    final nameCtrl = TextEditingController(text: user['name']);
    final emailCtrl = TextEditingController(text: user['email']);
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modifier le coach'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Nom')),
            SizedBox(height: 12),
            TextField(controller: emailCtrl, decoration: InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
            SizedBox(height: 12),
            TextField(controller: passwordCtrl, decoration: InputDecoration(labelText: 'Mot de passe (laissez vide pour ne pas modifier)'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Coach modifié avec succès'), backgroundColor: Colors.green));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Échec de la modification'), backgroundColor: Colors.red));
              }
            },
            child: Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void editInscriptionStatus(Map<dynamic, dynamic> inscription) async {
    String? newStatus = inscription['etat'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Changer le statut de l\'inscription'),
        content: DropdownButton<String>(
          value: newStatus,
          items: ['en attente', 'sans payée', 'valider', 'annuler'].map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(
                status == 'valider'
                    ? 'Accepté'
                    : status == 'annuler'
                        ? 'Refusé'
                        : status == 'sans payée'
                            ? 'Non payé'
                            : 'En attente',
              ),
            );
          }).toList(),
          onChanged: (val) => newStatus = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final response = await authProvider.apiRequest('inscriptions/${inscription['id']}', 'PUT', body: {'etat': newStatus});

              if (response.statusCode == 200) {
                Navigator.pop(ctx);
                fetchAllData();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Statut mis à jour'), backgroundColor: Colors.green));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Échec de la mise à jour'), backgroundColor: Colors.red));
              }
            },
            child: Text('Enregistrer'),
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
        title: Text('Tableau de bord POWERIX', style: TextStyle(fontWeight: FontWeight.bold, color: accentColor)),
        backgroundColor: primaryColor.withOpacity(0.9),
        elevation: 4,
        shadowColor: Colors.black45,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts),
            tooltip: 'Modifier le compte admin',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: accentColor,
          unselectedLabelColor: Colors.white60,
          indicatorColor: accentColor,
          indicatorWeight: 4,
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Salles'),
            Tab(text: 'Cours'),
            Tab(text: 'Utilisateurs'),
            Tab(text: 'Inscriptions'),
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
                salles.isEmpty
                    ? Center(child: Text('Aucune salle trouvée', style: TextStyle(color: Colors.white70, fontSize: 18)))
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
                                  Text('Capacité : ${salle['capacite']} personnes', style: TextStyle(color: Colors.white70)),
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

                courses.isEmpty
                    ? Center(child: Text('Aucun cours trouvé', style: TextStyle(color: Colors.white70, fontSize: 18)))
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
                                  Text('À : ${salle['nom'] ?? 'Non défini'}', style: TextStyle(color: Colors.white70)),
                                  Text('${cour['horaire_deb']} - ${cour['horaire_fin']}', style: TextStyle(color: Colors.white70)),
                                  Text('Capacité : ${cour['capacite']} personnes', style: TextStyle(color: Colors.white70)),
                                  if (firstAbonnement != null)
                                    Text('${firstAbonnement['nom']} • ${firstAbonnement['prix']} DA', style: TextStyle(color: Colors.greenAccent)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blueAccent),
                                    onPressed: () => editCourse(cour),
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

                users.isEmpty
                    ? Center(child: Text('Aucun utilisateur trouvé', style: TextStyle(color: Colors.white70, fontSize: 18)))
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: users.length,
                        itemBuilder: (ctx, i) {
                          final user = users[i];
                          final roleText = user['role'] == 'coach'
                              ? 'Coach'
                              : user['role'] == 'admin'
                                  ? 'Admin'
                                  : 'Client';

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

                inscriptions.isEmpty
                    ? Center(child: Text('Aucune inscription trouvée', style: TextStyle(color: Colors.white70, fontSize: 18)))
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: inscriptions.length,
                        itemBuilder: (ctx, i) {
                          final ins = inscriptions[i];
                          final clientName = ins['client']?['name'] ?? 'Client supprimé';
                          final courName = ins['cour']?['nom'] ?? 'Cours supprimé';
                          final abonnementName = ins['abonnement']?['nom'] ?? 'Abonnement';

                          final status = switch (ins['etat'] ?? 'en attente') {
                            'valider' => 'Accepté',
                            'annuler' => 'Refusé',
                            'sans payée' => 'Non payé',
                            _ => 'En attente',
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
                              subtitle: Text('Date : ${ins['date_inscription'] ?? 'Inconnue'}', style: TextStyle(color: Colors.white70)),
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