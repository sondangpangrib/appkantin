import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'global_config.dart' as cfg;

class TambahPembeliPage extends StatefulWidget {
  @override
  _TambahPembeliPageState createState() => _TambahPembeliPageState();
}

class _TambahPembeliPageState extends State<TambahPembeliPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _telpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  int? selectedGroupId;
  List<dynamic> groupList = [];
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    final response =
        await http.get(Uri.parse('${cfg.GlobalConfig.baseUrl}/user_group'));
    if (response.statusCode == 200) {
      setState(() {
        groupList = json.decode(response.body);
      });
    }
  }

  Future<void> _submit() async {
    if (_namaController.text.isEmpty ||
        _telpController.text.isEmpty ||
        _passwordController.text.isEmpty) return;

    var request = http.MultipartRequest(
        'POST', Uri.parse('${cfg.GlobalConfig.baseUrl}/pembeli'));
    request.fields['user_nama'] = _namaController.text;
    request.fields['user_telp'] = _telpController.text;
    request.fields['user_password'] = _passwordController.text;
    request.fields['id_group_user'] = selectedGroupId?.toString() ?? '';

    if (_selectedImage != null) {
      request.files
          .add(await http.MultipartFile.fromPath('foto', _selectedImage!.path));
    }

    final response = await request.send();
    if (response.statusCode == 200) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Pembeli')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          TextField(
              controller: _namaController,
              decoration: InputDecoration(labelText: 'Nama')),
          TextField(
              controller: _telpController,
              decoration: InputDecoration(labelText: 'Telepon')),
          TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true),
          DropdownButtonFormField(
            value: selectedGroupId,
            items: groupList.map<DropdownMenuItem<int>>((item) {
              return DropdownMenuItem<int>(
                value: item['id_group_user'],
                child: Text(item['nama_group']),
              );
            }).toList(),
            onChanged: (val) => setState(() => selectedGroupId = val),
            decoration: InputDecoration(labelText: 'Kategori Pembeli'),
          ),
          SizedBox(height: 10),
          ElevatedButton.icon(
            icon: Icon(Icons.image),
            label: Text('Pilih Foto'),
            onPressed: () async {
              final picker = ImagePicker();
              final pickedFile =
                  await picker.pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                setState(() {
                  _selectedImage = File(pickedFile.path);
                });
              }
            },
          ),
          // Hanya bagian tampilan gambar:
          if (_selectedImage != null)
            Image.file(_selectedImage!, height: 100)
          else
            Icon(Icons.person, size: 100, color: Colors.grey),
          SizedBox(height: 20),
          ElevatedButton(onPressed: _submit, child: Text('Simpan'))
        ]),
      ),
    );
  }
}
