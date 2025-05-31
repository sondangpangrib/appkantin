import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'global_config.dart' as cfg;

class NotaPreviewPage extends StatefulWidget {
  final Map<String, dynamic> transaksi;
  final List<dynamic> items;

  NotaPreviewPage({required this.transaksi, required this.items});

  @override
  _NotaPreviewPageState createState() => _NotaPreviewPageState();
}

class _NotaPreviewPageState extends State<NotaPreviewPage> {
  final ScreenshotController screenshotController = ScreenshotController();
  final currency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  Future<void> _shareScreenshot() async {
    final Uint8List? image = await screenshotController.capture();
    if (image == null) return;

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/nota.png';
    final file = File(path)..writeAsBytesSync(image);

    Share.shareXFiles([XFile(file.path)], text: 'Nota Transaksi');
  }

  @override
  Widget build(BuildContext context) {
    final trx = widget.transaksi;
    final items = widget.items;
    final afterDiskon = trx['total_transaksi'] * (1 - trx['diskon'] / 100);

    return Scaffold(
      appBar: AppBar(
        title: Text("Preview Nota"),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _shareScreenshot,
          )
        ],
      ),
      body: Screenshot(
        controller: screenshotController,
        child: Container(
          color: Colors.white,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Text("NOTA TRANSAKSI",
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold))),
              Divider(thickness: 2),
              _infoRow("ID Transaksi", trx['id_transaksi']),
              _infoRow("Tanggal", trx['tanggal_transaksi']),
              _infoRow("Pembeli", trx['nama_pembeli'] ?? "-"),
              _infoRow("Kasir", trx['nama_seles'] ?? "-"),
              SizedBox(height: 10),
              Text("Item yang Dibeli:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...items.map((item) => _buildItemCard(item)).toList(),
              Divider(),
              _infoRow("Total", currency.format(trx['total_transaksi'])),
              _infoRow("Diskon", "${trx['diskon']}%"),
              _infoRow("Total Setelah Diskon", currency.format(afterDiskon)),
              SizedBox(height: 20),
              Center(
                  child: Text("~ Terima Kasih ~",
                      style: TextStyle(fontStyle: FontStyle.italic))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child:
                  Text(label, style: TextStyle(fontWeight: FontWeight.bold))),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildItemCard(dynamic item) {
    final subtotal = item['qty'] * item['harga_jual'];
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: item['foto'] != null
            ? Image.network(
                '${cfg.GlobalConfig.baseUrl}/uploads/foto/${item['foto']}',
                width: 50,
                height: 50)
            : Icon(Icons.image),
        title: Text(item['nama_produk']),
        subtitle: Text(
            "Qty: ${item['qty']} x ${currency.format(item['harga_jual'])}"),
        trailing: Text(currency.format(subtotal)),
      ),
    );
  }
}
