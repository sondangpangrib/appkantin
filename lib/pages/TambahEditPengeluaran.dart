import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'global_config.dart' as cfg;

class TambahEditPengeluaranPage extends StatefulWidget {
  final Map<String, dynamic>? item;

  TambahEditPengeluaranPage({this.item});

  @override
  _TambahEditPengeluaranPageState createState() =>
      _TambahEditPengeluaranPageState();
}

class _TambahEditPengeluaranPageState extends State<TambahEditPengeluaranPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _deskripsiController = TextEditingController();
  TextEditingController _totalController = TextEditingController();
  DateTime? _tanggal;
  File? _foto;
  List kategoriList = [];
  String? _kategori;
  bool isEditMode = false;

  @override
  void initState() {
    super.initState();
    _fetchKategori();
    _deskripsiController.text = widget.item?['deskripsi_pengeluaran'] ?? '';
    _totalController.text = widget.item?['total_pengeluaran']?.toString() ?? '';
    _tanggal = widget.item?['tanggal_pengeluaran'] != null
        ? DateTime.tryParse(widget.item!['tanggal_pengeluaran'])
        : DateTime.now();
    _kategori = widget.item?['id_kategory_pengeluaran']?.toString();
    if (widget.item == null) isEditMode = true;
  }

  Future<void> _fetchKategori() async {
    final response = await http
        .get(Uri.parse('${cfg.GlobalConfig.baseUrl}/pengeluaran/kategori'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        kategoriList = data;
      });
    }
  }

  Future<void> _pickFoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _foto = File(picked.path));
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    var uri = Uri.parse(widget.item == null
        ? '${cfg.GlobalConfig.baseUrl}/pengeluaran'
        : '${cfg.GlobalConfig.baseUrl}/pengeluaran/${widget.item!['id_pengeluaran']}');
    var request =
        http.MultipartRequest(widget.item == null ? 'POST' : 'PUT', uri);
    request.fields['id_kategory_pengeluaran'] = _kategori!;
    request.fields['deskripsi_pengeluaran'] = _deskripsiController.text;
    request.fields['total_pengeluaran'] = _totalController.text;
    request.fields['tanggal_pengeluaran'] =
        _tanggal!.toIso8601String().split('T')[0];
    if (_foto != null) {
      request.files.add(await http.MultipartFile.fromPath('foto', _foto!.path));
    }
    final response = await request.send();
    if (response.statusCode == 200) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menyimpan')));
    }
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Image.network(imageUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isViewOnly = widget.item != null && !isEditMode;
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.item == null ? 'Tambah Pengeluaran' : 'Detail Pengeluaran'),
        actions: widget.item != null && !isEditMode
            ? [
                IconButton(
                  icon: Icon(FontAwesomeIcons.penToSquare),
                  onPressed: () => setState(() => isEditMode = true),
                )
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _kategori,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: kategoriList.map<DropdownMenuItem<String>>((kategori) {
                  return DropdownMenuItem<String>(
                    value: kategori['idkategori_pengeluaran'].toString(),
                    child: Text(kategori['pengeluaran_nama']),
                  );
                }).toList(),
                onChanged: isViewOnly
                    ? null
                    : (val) => setState(() => _kategori = val),
                validator: (val) =>
                    val == null ? 'Kategori wajib dipilih' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _deskripsiController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                readOnly: isViewOnly,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Deskripsi wajib diisi' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _totalController,
                decoration: InputDecoration(
                  labelText: 'Total (Rp)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                readOnly: isViewOnly,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Total wajib diisi' : null,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(FontAwesomeIcons.calendar),
                  SizedBox(width: 8),
                  Text("Tanggal: "),
                  TextButton(
                      onPressed: isViewOnly
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _tanggal ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null)
                                setState(() => _tanggal = picked);
                            },
                      child: Text(
                          _tanggal?.toIso8601String().split('T')[0] ?? '-')),
                ],
              ),
              SizedBox(height: 12),
              if (_foto != null)
                GestureDetector(
                  onTap: () => _showFullImage(_foto!.path),
                  child: Image.file(_foto!,
                      width: double.infinity, height: 200, fit: BoxFit.cover),
                )
              else if (widget.item?['foto_path'] != null)
                GestureDetector(
                  onTap: () => _showFullImage(
                      '${cfg.GlobalConfig.baseUrl}/img/${widget.item!['foto_path']}'),
                  child: Image.network(
                    '${cfg.GlobalConfig.baseUrl}/img/${widget.item!['foto_path']}?format=jpeg&height=300&crop=cover',
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              if (!isViewOnly)
                TextButton.icon(
                  onPressed: _pickFoto,
                  icon: Icon(FontAwesomeIcons.image),
                  label: Text('Pilih Foto'),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(12),
        child: widget.item == null
            ? ElevatedButton.icon(
                onPressed: _simpan,
                icon: Icon(FontAwesomeIcons.floppyDisk),
                label: Text('Simpan'),
              )
            : isEditMode
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => setState(() => isEditMode = false),
                        icon: Icon(FontAwesomeIcons.xmark),
                        label: Text('Batal'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _simpan,
                        icon: Icon(FontAwesomeIcons.save),
                        label: Text('Simpan'),
                      ),
                    ],
                  )
                : SizedBox.shrink(),
      ),
    );
  }
}
