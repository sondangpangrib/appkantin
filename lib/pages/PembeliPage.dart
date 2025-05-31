import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'TambahPembeliPage.dart';
import 'EditPembeliPage.dart';
import 'global_config.dart' as cfg;

class PembeliPage extends StatefulWidget {
  @override
  _PembeliPageState createState() => _PembeliPageState();
}

class _PembeliPageState extends State<PembeliPage> {
  List<dynamic> pembeliList = [];
  List<dynamic> filteredList = [];
  List<String> kategoriList = [];
  String? selectedKategori;
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String baseUrl = cfg.GlobalConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _fetchKategori();
    _fetchPembeli();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _applyFilter();
  }

  void _applyFilter() {
    final keyword = _searchController.text.toLowerCase();
    setState(() {
      filteredList = pembeliList.where((item) {
        final nama = item['pembeli_nama'].toLowerCase();
        final telp = item['pembeli_no_telp']?.toLowerCase() ?? '';
        final kategori = item['nama_group']?.toLowerCase() ?? '';
        final matchKategori = selectedKategori == null ||
            selectedKategori == 'Semua' ||
            kategori == selectedKategori?.toLowerCase();
        return matchKategori &&
            (nama.contains(keyword) ||
                telp.contains(keyword) ||
                kategori.contains(keyword));
      }).toList();
    });
  }

  Future<void> _fetchKategori() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pembeli'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          kategoriList = [
            'Semua',
            ...data.map((e) => e['nama_group']).toSet().toList()
          ];
        });
      }
    } catch (e) {
      print('Gagal ambil kategori: $e');
    }
  }

  Future<void> _fetchPembeli() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pembeli'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          pembeliList = data;
          filteredList = data;
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data pembeli');
      }
    } catch (e) {
      print(e);
    }
  }

  Widget _buildListItem(dynamic pembeli) {
    final String? foto = pembeli['foto_img_name'];
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: (foto != null && foto.isNotEmpty)
            ? NetworkImage(
                '$baseUrl/img/$foto?format=jpeg&height=60&crop=cover')
            : null,
        child: (foto == null || foto.isEmpty)
            ? Icon(Icons.person, color: Colors.white)
            : null,
        backgroundColor: Colors.blueGrey,
      ),
      title: Text(pembeli['pembeli_nama']),
      subtitle: Text(
          'Telp: ${pembeli['pembeli_no_telp'] ?? '-'}\nKategori: ${pembeli['nama_group'] ?? '-'}'),
      isThreeLine: true,
      trailing: IconButton(
        icon: Icon(Icons.edit, color: Colors.blue),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditPembeliPage(pembeli: pembeli),
            ),
          );
          _fetchPembeli();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Data Pembeli')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari nama / telp / kategori',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon:
                          Icon(Icons.add_circle, color: Colors.green, size: 32),
                      tooltip: 'Tambah Pembeli',
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => TambahPembeliPage()),
                        );
                        _fetchPembeli();
                      },
                    )
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: DropdownButtonFormField<String>(
                  value: selectedKategori ?? 'Semua',
                  items: kategoriList
                      .map((kategori) => DropdownMenuItem(
                            value: kategori,
                            child: Text(kategori),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedKategori = value);
                    _applyFilter();
                  },
                  decoration: InputDecoration(
                    labelText: 'Kategori Pembeli',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                ),
              ),
              SizedBox(height: 6),
              Expanded(
                child: ListView.separated(
                  itemCount: filteredList.length,
                  separatorBuilder: (context, index) => Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _buildListItem(filteredList[index]),
                ),
              ),
            ]),
    );
  }
}
