import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'global_config.dart' as cfg;

class EditProdukPage extends StatefulWidget {
  final Map<String, dynamic> data;

  EditProdukPage({required this.data});

  @override
  _EditProdukPageState createState() => _EditProdukPageState();
}

class _EditProdukPageState extends State<EditProdukPage> {
  final _formKey = GlobalKey<FormState>();
  late String namaProduk;
  late String harga;
  File? _imageFile;
  final picker = ImagePicker();
  late String baseUrl;

  int? selectedKategoriId;
  List<dynamic> kategoriList = [];

  @override
  void initState() {
    super.initState();
    baseUrl = cfg.GlobalConfig.baseUrl;
    namaProduk = widget.data['nama_produk'] ?? '';
    harga = widget.data['harga']?.toString() ?? '';
    selectedKategoriId = widget.data['id_produk_kategori'];
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
      _showMessage('Terjadi kesalahan: $e');
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

    try {
      final uri = Uri.parse('$baseUrl/produk/${widget.data['id_produk']}');
      var request = http.MultipartRequest('PUT', uri);
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
      } else {
        request.fields['foto_produk'] = widget.data['foto_produk'] ?? '';
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        Navigator.pop(this.context);
      } else {
        final respStr = await response.stream.bytesToString();
        _showMessage('Gagal update produk: $respStr');
      }
    } catch (e) {
      _showMessage('Terjadi kesalahan: $e');
    }
  }

  void _konfirmasiHapus() {
    showDialog(
      context: this.context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi'),
        content: Text('Yakin ingin menghapus produk ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _hapusProduk();
            },
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _hapusProduk() async {
    try {
      final id = widget.data['id_produk'];
      final uri = Uri.parse('$baseUrl/produk/$id');
      final response = await http.delete(uri);

      if (response.statusCode == 200) {
        _showMessage('Produk berhasil dihapus');
        Navigator.pop(this.context);
      } else {
        _showMessage('Gagal menghapus produk');
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
    final imageName = widget.data['foto_produk']?.split('/')?.last ?? '';
    final imageUrl =
        '$baseUrl/img/$imageName?format=jpeg&height=150&crop=cover';

    return Scaffold(
      appBar: AppBar(title: Text('Edit Produk')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: namaProduk,
                decoration: InputDecoration(labelText: 'Nama Produk'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Wajib diisi' : null,
                onChanged: (val) => namaProduk = val,
              ),
              TextFormField(
                initialValue: harga,
                decoration: InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Wajib diisi';
                  final parsed = num.tryParse(val);
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
                  : (widget.data['foto_produk'] != null &&
                          widget.data['foto_produk'] != '')
                      ? Image.network(imageUrl, height: 150)
                      : Text('Belum ada foto', textAlign: TextAlign.center),
              TextButton.icon(
                icon: Icon(Icons.image),
                label: Text('Ganti Gambar'),
                onPressed: _pickImage,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitProduk,
                child: Text('Simpan Perubahan'),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                icon: Icon(Icons.delete),
                label: Text('Hapus Produk'),
                onPressed: _konfirmasiHapus,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
