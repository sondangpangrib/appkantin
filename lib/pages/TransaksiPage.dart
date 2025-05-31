import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'global_config.dart' as cfg;
import 'DetailTransaksi.dart';
import 'EditKasirPage.dart';

class TransaksiPage extends StatefulWidget {
  @override
  _TransaksiPageState createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  List<dynamic> transaksiList = [];
  List<bool> expandedList = [];
  bool isLoading = true;
  String searchKeyword = '';
  DateTime? dari;
  DateTime? sampai;
  String baseUrl = cfg.GlobalConfig.baseUrl;

  final TextEditingController _searchController = TextEditingController();
  final DateFormat formatter = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    fetchTransaksi();
  }

  Future<void> fetchTransaksi() async {
    setState(() => isLoading = true);
    String url = '$baseUrl/penjualan/list?search=$searchKeyword';
    if (dari != null && sampai != null) {
      url +=
          '&dari=${formatter.format(dari!)}&sampai=${formatter.format(sampai!)}';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          transaksiList = data;
          expandedList = List.generate(data.length, (_) => false);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String getStatusLabel(int status) {
    switch (status) {
      case 0:
        return 'Transaksi';
      case 1:
        return 'Draft';
      case 3:
        return 'Batal';
      case 4:
        return 'Hutang Lunas';
      default:
        return 'Tidak Diketahui';
    }
  }

  Color getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.green; // Transaksi
      case 1:
        return Colors.orange; // Draft
      case 3:
        return const Color.fromARGB(255, 238, 54, 244); // Batal
      case 4:
        return const Color.fromARGB(255, 232, 5, 77); // Hutang Lunas
      default:
        return Colors.grey;
    }
  }

  String getMetodeLabel(int metode) {
    switch (metode) {
      case 1:
        return 'Tunai';
      case 2:
        return 'Transfer';
      case 3:
        return 'QRIS';
      case 4:
        return 'Hutang';
      default:
        return '-';
    }
  }

  Widget buildItem(int index) {
    final trx = transaksiList[index];
    final expanded = expandedList[index];
    final total = trx['total_transaksi'] ?? 0;
    final diskon = trx['diskon'] ?? 0;
    final net = total * (1 - (diskon / 100));
    final status = trx['status_transaksi'] ?? 0;
    final metode = getMetodeLabel(trx['metode_pembayaran'] ?? 2);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            onTap: () {
              if (status == 1) {
                /*
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EditKasirPage(idTransaksi: trx['id_transaksi']),
                  ),
                );*/
              }
            },
            title: Text(
              trx['nama_pembeli'] ?? '-',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${trx['id_transaksi']}'),
                Text('Tanggal: ${trx['tanggal_transaksi']}'),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: getStatusColor(status),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(getStatusLabel(status),
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(metode, style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(expanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down),
              onPressed: () {
                setState(() {
                  expandedList[index] = !expandedList[index];
                });
              },
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailTransaksiPage(
                              idPenjualan: trx['id_penjualan']),
                        ),
                      );
                    },
                    icon: Icon(Icons.remove_red_eye),
                    label: Text("Detail"),
                  ),
                  Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total: Rp${total.toStringAsFixed(0)}',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Net: Rp${net.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }

  Future<void> pilihTanggalRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dari = picked.start;
        sampai = picked.end;
      });
      fetchTransaksi();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transaksi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      searchKeyword = val;
                      fetchTransaksi();
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari nama / ID',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.date_range),
                  onPressed: pilihTanggalRange,
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : transaksiList.isEmpty
                    ? Center(child: Text("Tidak ada transaksi"))
                    : ListView.builder(
                        itemCount: transaksiList.length,
                        itemBuilder: (_, i) => buildItem(i),
                      ),
          ),
        ],
      ),
    );
  }
}
