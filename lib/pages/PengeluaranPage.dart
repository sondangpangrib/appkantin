import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'TambahEditPengeluaran.dart';
import 'global_config.dart' as cfg;

class PengeluaranPage extends StatefulWidget {
  @override
  _PengeluaranPageState createState() => _PengeluaranPageState();
}

class _PengeluaranPageState extends State<PengeluaranPage> {
  List<dynamic> pengeluaranList = [];
  List<dynamic> kategoriList = [];
  String? selectedKategori;
  DateTimeRange? rentangTanggal;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    rentangTanggal = DateTimeRange(
      start: DateTime(now.year, now.month, now.day, 0, 0, 0),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
    fetchKategori();
    fetchPengeluaran();
  }

  Future<void> fetchKategori() async {
    final response = await http
        .get(Uri.parse('${cfg.GlobalConfig.baseUrl}/pengeluaran/kategori'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        kategoriList = data;
      });
    }
  }

  Future<void> fetchPengeluaran() async {
    final queryParams = {
      if (rentangTanggal != null)
        'dari': rentangTanggal!.start.toIso8601String(),
      if (rentangTanggal != null)
        'sampai': rentangTanggal!.end.toIso8601String(),
      if (selectedKategori != null && selectedKategori != '')
        'kategori': selectedKategori!
    };
    final uri = Uri.parse('${cfg.GlobalConfig.baseUrl}/pengeluaran')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      setState(() {
        pengeluaranList = json.decode(response.body);
      });
    }
  }

  String formatRupiah(dynamic amount) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  String potongDeskripsi(String text, {int max = 300}) {
    return text.length <= max ? text : text.substring(0, max).trim() + '...';
  }

  Future<void> _bukaTambahEdit(Map<String, dynamic>? item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TambahEditPengeluaranPage(item: item),
      ),
    );

    if (result == true) {
      fetchKategori();
      fetchPengeluaran();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pengeluaran')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                      initialDateRange: rentangTanggal,
                    );
                    if (picked != null) {
                      setState(() => rentangTanggal = picked);
                      fetchPengeluaran();
                    }
                  },
                  icon: Icon(Icons.date_range),
                  label: Text(
                    rentangTanggal != null
                        ? "${DateFormat('d MMM y').format(rentangTanggal!.start)} - ${DateFormat('d MMM y').format(rentangTanggal!.end)}"
                        : "Pilih Rentang Tanggal",
                  ),
                ),
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedKategori,
                  hint: Text("Pilih Kategori"),
                  items: [
                    DropdownMenuItem<String>(
                        value: '', child: Text("Semua Kategori")),
                    ...kategoriList.map<DropdownMenuItem<String>>((kategori) {
                      return DropdownMenuItem<String>(
                        value: kategori['idkategori_pengeluaran'].toString(),
                        child: Text(kategori['pengeluaran_nama']),
                      );
                    }).toList(),
                  ],
                  onChanged: (val) {
                    setState(() => selectedKategori = val == '' ? null : val);
                    fetchPengeluaran();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: pengeluaranList.isEmpty
                ? Center(child: Text("Tidak ada data"))
                : ListView.builder(
                    itemCount: pengeluaranList.length,
                    itemBuilder: (context, i) {
                      final item = pengeluaranList[i];
                      return Card(
                        margin:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        elevation: 2,
                        child: InkWell(
                          onTap: () => _bukaTambahEdit(item),
                          child: Row(
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                margin: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: item['foto_path'] != null &&
                                          item['foto_path'] != ''
                                      ? DecorationImage(
                                          image: NetworkImage(
                                              '${cfg.GlobalConfig.baseUrl}/img/${item['foto_path']}?format=jpeg&height=60&crop=cover'),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  color: item['foto_path'] == null
                                      ? Colors.grey[300]
                                      : null,
                                ),
                                child: item['foto_path'] == null
                                    ? Icon(Icons.image_not_supported, size: 40)
                                    : null,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['tanggal_pengeluaran'] ?? '',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700]),
                                      ),
                                      Text(
                                        formatRupiah(item['total_pengeluaran']),
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        potongDeskripsi(
                                            item['deskripsi_pengeluaran'] ??
                                                ''),
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _bukaTambahEdit(null),
        child: Icon(Icons.add),
      ),
    );
  }
}
