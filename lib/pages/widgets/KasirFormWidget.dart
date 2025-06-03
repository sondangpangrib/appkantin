import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class KasirFormWidget extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onDateChange;
  final String idtransaksi;
  final double total;
  final double discount;
  final Function(double) onDiscountChange;
  final String paymentMethod;
  final Function(String?) onPaymentMethodChange;
  final VoidCallback onPilihPembeli;
  final String? namaPembeli;
  final VoidCallback onTambahProduk;
  final List<Map<String, dynamic>> orderList;
  final Function(int index) onEditOrder;
  final Function(int index) onDeleteOrder;

  const KasirFormWidget({
    super.key,
    required this.idtransaksi,
    required this.selectedDate,
    required this.onDateChange,
    required this.total,
    required this.discount,
    required this.onDiscountChange,
    required this.paymentMethod,
    required this.onPaymentMethodChange,
    required this.onPilihPembeli,
    required this.namaPembeli,
    required this.onTambahProduk,
    required this.orderList,
    required this.onEditOrder,
    required this.onDeleteOrder,
  });

  String formatRupiah(dynamic number) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(number ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("ID Transaksi: ${idtransaksi}",
                style: TextStyle(fontSize: 14)),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18),
                SizedBox(width: 8),
                Text(DateFormat('dd-MM-yyyy').format(selectedDate)),
              ],
            ),
            Text("Diskon %: ", style: TextStyle(fontSize: 14)),
            SizedBox(
              width: 30,
              child: TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.end,
                onChanged: (val) {
                  double d = double.tryParse(val) ?? 0;
                  if (d < 0) d = 0;
                  if (d > 100) d = 100;
                  onDiscountChange(d);
                },
                decoration:
                    InputDecoration(hintText: discount.toStringAsFixed(0)),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text("Total: ${formatRupiah(total)}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
          ],
        ),
        SizedBox(height: 10),
        if (paymentMethod == 'Hutang')
          InkWell(
            onTap: onPilihPembeli,
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.purple),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    namaPembeli ?? 'Pilih Pembeli',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Icon(Icons.edit, color: Colors.purple)
              ],
            ),
          ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: onTambahProduk,
              icon: Icon(Icons.add),
              label: Text("Tambah Produk"),
            ),
            DropdownButton<String>(
              value: paymentMethod,
              items: ['Cash', 'QRIS', 'Transfer', 'Hutang']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onPaymentMethodChange,
            ),
          ],
        ),
        SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: orderList.length,
            itemBuilder: (context, index) {
              final item = orderList[index];
              final subtotal = item['qty'] * item['harga'];
              return ListTile(
                onTap: () => onEditOrder(index),
                leading: item['foto_produk'] != null &&
                        item['foto_produk'] != '' &&
                        item['foto_produk'].startsWith("http")
                    ? Image.network(
                        item['foto_produk'],
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      )
                    : Icon(Icons.image),
                title: Text(item['nama_produk'] ?? '-',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Qty: ${item['qty']} x ${formatRupiah(item['harga'])}",
                        style: TextStyle(fontSize: 13)),
                    Text("Subtotal: ${formatRupiah(subtotal)}",
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500))
                  ],
                ),
                trailing: IconButton(
                  onPressed: () => onDeleteOrder(index),
                  icon: Icon(Icons.delete, color: Colors.red),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
