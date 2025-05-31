import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'global_config.dart' as cfg;

class EditPembeliPage extends StatefulWidget {
  final Map<String, dynamic> pembeli;

  EditPembeliPage({required this.pembeli});

  @override
  _EditPembeliPageState createState() => _EditPembeliPageState();
}

class _EditPembeliPageState extends State<EditPembeliPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _telpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  int? selectedGroupId;
  List<dynamic> groupList = [];
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _namaController.text = widget.pembeli['pembeli_nama'] ?? '';
    _telpController.text = widget.pembeli['pembeli_no_telp'] ?? '';
    _passwordController.text = ''; // Kosongkan password
    selectedGroupId = widget.pembeli['id_group_user'];
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    final response = await http
        .get(Uri.parse('${cfg.GlobalConfig.baseUrl}/user_group/pembeli'));
    if (response.statusCode == 200) {
      setState(() {
        groupList = json.decode(response.body);
      });
    }
  }

  Future<void> _submit() async {
    var request = http.MultipartRequest(
        'PUT',
        Uri.parse(
            '${cfg.GlobalConfig.baseUrl}/pembeli/${widget.pembeli['id_pembeli']}'));
    request.fields['user_nama'] = _namaController.text;
    request.fields['user_telp'] = _telpController.text;
    request.fields['user_password'] = _passwordController.text.isNotEmpty
        ? _passwordController.text
        : widget.pembeli['user_password'] ?? '';
    request.fields['id_group_user'] = selectedGroupId?.toString() ?? '';
    request.fields['foto_img_name'] = widget.pembeli['foto_img_name'] ?? '';

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
      appBar: AppBar(title: Text('Edit Pembeli')),
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
              decoration: InputDecoration(
                  labelText: 'Password (kosongkan jika tidak ubah)'),
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
            label: Text('Ubah Foto'),
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
          // Ganti bagian tampilan gambar:
          if (_selectedImage != null)
            Image.file(_selectedImage!, height: 100)
          else if (widget.pembeli['foto_img_name'] != null &&
              widget.pembeli['foto_img_name'] != '')
            Image.network(
                '${cfg.GlobalConfig.baseUrl}/img/${widget.pembeli['foto_img_name']}?format=jpeg&height=60&crop=cover',
                height: 100)
          else
            Icon(Icons.person, size: 100, color: Colors.grey),
          SizedBox(height: 20),
          ElevatedButton(onPressed: _submit, child: Text('Update'))
        ]),
      ),
    );
  }
}
