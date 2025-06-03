import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../global_config.dart' as cfg;

class NotaWidget extends StatelessWidget {
  final Map<String, dynamic> transaksi;
  final List<dynamic> items;
  final String namaToko, alamat, telp;

  NotaWidget({
    required this.transaksi,
    required this.items,
    required this.namaToko,
    required this.alamat,
    required this.telp,
  });

  final currency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final trx = transaksi;
    final double total = (trx['total_transaksi'] ?? 0).toDouble();
    final double diskon = (trx['diskon'] ?? 0).toDouble();
    final afterDiskon = total * (1 - diskon / 100);

    final validItems =
        items.where((e) => e != null && e is Map<String, dynamic>).toList();
    print("🧾 Jumlah item valid: ${validItems.length}");

    return SingleChildScrollView(
      // ✅ Fix overflow
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Column(
              children: [
                const Text("NOTA TRANSAKSI",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text("$namaToko : $alamat\nWA/TELP: $telp",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12))
              ],
            )),
            Divider(thickness: 2),
            _infoRow("ID Transaksi", trx['id_transaksi']?.toString() ?? '-'),
            _infoRow("Tanggal", trx['tanggal_transaksi'] ?? '-'),
            _infoRow("Pembeli", trx['nama_pembeli'] ?? "-"),
            _infoRow("Kasir", trx['nama_seles'] ?? "-"),
            SizedBox(height: 10),
            Text("Item yang Dibeli:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            if (validItems.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Tidak ada item."),
              )
            else
              ...validItems.asMap().entries.map((entry) {
                print("🧩 Item ke-${entry.key}: ${entry.value}");
                return _buildItemCard(entry.value);
              }).toList(),
            Divider(),
            _infoRow("Total", currency.format(total)),
            _infoRow("Diskon", "$diskon%"),
            _infoRow("Total Setelah Diskon", currency.format(afterDiskon)),
            SizedBox(height: 20),
            Center(
                child: Text("~ Terima Kasih ~",
                    style: TextStyle(fontStyle: FontStyle.italic))),
          ],
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

  Widget _buildItemCard(Map<String, dynamic> item) {
    final namaProduk = item['nama_produk'] ?? 'Produk';
    final qty = item['qty'];
    final harga = item['harga_jual'];
    final foto = item['foto'];

    final isQtyValid = qty is num;
    final isHargaValid = harga is num;
    final subtotal = (isQtyValid && isHargaValid) ? qty * harga : 0;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            (foto != null && foto.toString().isNotEmpty)
                ? Image.network(
                    '${cfg.GlobalConfig.baseUrl}/img/$foto?format=jpeg&height=50&crop=cover',
                    width: 50,
                    height: 50,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.image_not_supported),
                  )
                : Icon(Icons.image),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(namaProduk,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                      'Qty: $qty x Rp ${NumberFormat("#,###", "id_ID").format(harga)}'),
                ],
              ),
            ),
            Text(
              "Rp ${NumberFormat("#,###", "id_ID").format(subtotal)}",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
  /*
  Widget _buildItemCard(Map<String, dynamic> item) {
    final namaProduk =
        item['nama_produk']?.toString() ?? 'Produk Tidak Diketahui';
    final qty = item['qty'];
    final harga = item['harga_jual'];
    final foto = item['foto']?.toString();

    final isQtyValid = qty is num;
    final isHargaValid = harga is num;
    final subtotal = (isQtyValid && isHargaValid) ? qty * harga : 0;

    Widget leadingWidget = (foto != null && foto.isNotEmpty)
        ? Image.network(
            '${cfg.GlobalConfig.baseUrl}/img/$foto',
            width: 50,
            height: 50,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
          )
        : const Icon(Icons.image);

    return Card(
      child: ListTile(
        leading: leadingWidget,
        title: Text(namaProduk),
        subtitle: Text(
          (isQtyValid && isHargaValid)
              ? 'Qty: $qty x ${currency.format(harga)}'
              : 'Qty atau harga tidak valid',
        ),
        trailing: Text(currency.format(subtotal)),
      ),
    );
  }
  */
}
