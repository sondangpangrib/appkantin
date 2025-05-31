import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'global_config.dart' as cfg;

class TambahProdukPage extends StatefulWidget {
  @override
  _TambahProdukPageState createState() => _TambahProdukPageState();
}

class _TambahProdukPageState extends State<TambahProdukPage> {
  final _formKey = GlobalKey<FormState>();
  String namaProduk = '';
  String harga = '';
  int? selectedKategoriId;
  List<dynamic> kategoriList = [];
  File? _imageFile;
  final picker = ImagePicker();
  late String baseUrl;

  @override
  void initState() {
    super.initState();
    baseUrl = cfg.GlobalConfig.baseUrl;
    _fetchKategori();
  }

  Future<void> _fetchKategori() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/produk_kategori'));
      if (response.statusCode == 200) {
        setState(() {
          kategoriList = json.decode(response.body);
        });
      } else {
        _showMessage('Gagal memuat kategori');
      }
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitProduk() async {
    if (!_formKey.currentState!.validate()) return;
    if (baseUrl.isEmpty) {
      _showMessage('Base URL tidak ditemukan di konfigurasi');
      return;
    }

    try {
      final uri = Uri.parse('$baseUrl/produk');
      var request = http.MultipartRequest('POST', uri);
      request.fields['nama_produk'] = namaProduk;
      request.fields['harga'] = harga;
      request.fields['id_produk_kategori'] =
          selectedKategoriId?.toString() ?? '';

      if (_imageFile != null) {
        final mimeType = lookupMimeType(_imageFile!.path) ?? 'image/jpeg';
        final fileStream = http.ByteStream(_imageFile!.openRead());
        final fileLength = await _imageFile!.length();

        request.files.add(http.MultipartFile(
          'foto_produk',
          fileStream,
          fileLength,
          filename: basename(_imageFile!.path),
          contentType: MediaType.parse(mimeType),
        ));
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        _showMessage('Produk berhasil ditambahkan');
        Navigator.pop(this.context);
      } else {
        final respStr = await response.stream.bytesToString();
        _showMessage('Gagal tambah produk: $respStr');
      }
    } catch (e) {
      _showMessage('Terjadi kesalahan: $e');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Produk')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Nama Produk'),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Wajib diisi' : null,
                onChanged: (val) => namaProduk = val,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Wajib diisi';
                  final num? parsed = num.tryParse(val);
                  if (parsed == null || parsed <= 0) return 'Harga tidak valid';
                  return null;
                },
                onChanged: (val) => harga = val,
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Kategori Produk'),
                value: selectedKategoriId,
                items: kategoriList.map<DropdownMenuItem<int>>((kategori) {
                  return DropdownMenuItem<int>(
                    value: kategori['id_produk_kategori'],
                    child: Text(kategori['nama_produk_kategori']),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => selectedKategoriId = val);
                },
                validator: (val) =>
                    val == null ? 'Pilih kategori produk' : null,
              ),
              SizedBox(height: 20),
              _imageFile != null
                  ? Image.file(_imageFile!, height: 150)
                  : Text('Belum ada foto', textAlign: TextAlign.center),
              TextButton.icon(
                icon: Icon(Icons.image),
                label: Text('Pilih Gambar'),
                onPressed: _pickImage,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitProduk,
                child: Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
