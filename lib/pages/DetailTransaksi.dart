import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'global_config.dart' as cfg;

class DetailTransaksiPage extends StatefulWidget {
  final int idPenjualan;
  DetailTransaksiPage({required this.idPenjualan});

  @override
  _DetailTransaksiPageState createState() => _DetailTransaksiPageState();
}

class _DetailTransaksiPageState extends State<DetailTransaksiPage> {
  Map<String, dynamic>? transaksi;
  List<dynamic> items = [];
  bool isLoading = true;

  final currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  Future<void> bukaNotaPDF(BuildContext context, int idPenjualan) async {
    final url =
        '${cfg.GlobalConfig.baseUrl}/penjualan/nota/pdf?id_penjualan=$idPenjualan';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak bisa membuka nota PDF')),
      );
    }
  }

  Future<void> fetchDetail() async {
    final url =
        '${cfg.GlobalConfig.baseUrl}/penjualan/detail?id_penjualan=${widget.idPenjualan}';

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          transaksi = data['transaksi'];
          items = data['items'];
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

  String getMetode(int m) {
    switch (m) {
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

  Color getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.orange;
      case 3:
        return Colors.red;
      case 4:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget buildItemTile(Map<String, dynamic> item) {
    final total = item['qty'] * item['harga_jual'];
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: item['foto'] != null
            ? Image.network(
                '${cfg.GlobalConfig.baseUrl}/img/${item['foto']}?format=jpeg&height=150&crop=cover',
                width: 50,
                height: 50,
                fit: BoxFit.cover)
            : Icon(Icons.image_not_supported),
        title: Text(item['nama_produk'] ?? '-'),
        subtitle: Text(
            'Qty: ${item['qty']} x ${currencyFormatter.format(item['harga_jual'])}'),
        trailing: Text(currencyFormatter.format(total)),
      ),
    );
  }

  Widget buildInfoRow(String label, String value, {Color? badgeColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
              child:
                  Text(label, style: TextStyle(fontWeight: FontWeight.bold))),
          badgeColor != null
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(value,
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                )
              : Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Transaksi'),
        actions: [
          if (transaksi != null)
            IconButton(
              icon: Icon(Icons.picture_as_pdf),
              onPressed: () => bukaNotaPDF(context, transaksi!['id_penjualan']),
            )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : transaksi == null
              ? Center(child: Text('Data tidak ditemukan'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informasi Transaksi
                      Container(
                        color: Colors.grey.shade100,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildInfoRow(
                                'ID Transaksi:', transaksi!['id_transaksi']),
                            buildInfoRow(
                                'Tanggal:', transaksi!['tanggal_transaksi']),
                            buildInfoRow('Nama Pembeli:',
                                transaksi!['nama_pembeli'] ?? '-'),
                            buildInfoRow(
                                'Kasir:', transaksi!['nama_seles'] ?? '-'),
                            buildInfoRow('Status:',
                                getStatusLabel(transaksi!['status_transaksi']),
                                badgeColor: getStatusColor(
                                    transaksi!['status_transaksi'])),
                            buildInfoRow('Metode Bayar:',
                                getMetode(transaksi!['metode_pembayaran']),
                                badgeColor: Colors.grey),
                          ],
                        ),
                      ),
                      Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text('Daftar Item',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      ...items.map((item) => buildItemTile(item)).toList(),
                      Divider(),
                      // Ringkasan
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            buildInfoRow(
                                'Total:',
                                currencyFormatter
                                    .format(transaksi!['total_transaksi'])),
                            buildInfoRow('Diskon:', '${transaksi!['diskon']}%'),
                            buildInfoRow(
                                'Total Setelah Diskon:',
                                currencyFormatter.format(
                                    transaksi!['total_transaksi'] *
                                        (1 - (transaksi!['diskon'] / 100)))),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}
