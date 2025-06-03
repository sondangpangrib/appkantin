// ✅ File: EditKasirPage.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'global_config.dart' as cfg;
import 'widgets/KasirFormWidget.dart';
import 'widgets/ModalPickers.dart';

class EditKasirPage extends StatefulWidget {
  final Map<String, dynamic> transaksi;
  const EditKasirPage({super.key, required this.transaksi});

  @override
  State<EditKasirPage> createState() => _EditKasirPageState();
}

class _EditKasirPageState extends State<EditKasirPage> {
  late DateTime selectedDate;
  double discount = 0;
  double total = 0;
  String idtransaksi = '-';
  String paymentMethod = 'Cash';
  List<Map<String, dynamic>> orderList = [];
  dynamic selectedPembeli;
  List<Map<String, dynamic>> pembeliList = [];
  List<Map<String, dynamic>> produkList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDraftTransaksiById(widget.transaksi['id_penjualan'].toString())
        .then((_) => setState(() => isLoading = false));
    fetchPembeli();
    fetchProduk();
  }

  void _recalculateTotal() {
    total =
        orderList.fold(0.0, (sum, item) => sum + item['qty'] * item['harga']);
    total -= (total * (discount / 100));
    setState(() {});
  }

  Future<void> fetchDraftTransaksiById(String idPenjualan) async {
    final baseUrl = cfg.GlobalConfig.baseUrl;
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/penjualan/detail?id_penjualan=$idPenjualan'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final transaksi = jsonData['transaksi'];
        final items = List<Map<String, dynamic>>.from(jsonData['items']);

        setState(() {
          selectedDate = DateTime.parse(transaksi['tanggal_transaksi']);
          discount = (transaksi['diskon'] ?? 0).toDouble();
          idtransaksi = (transaksi['id_transaksi'] ?? 0).toString();
          paymentMethod = _metodeKodeKeString(transaksi['metode_pembayaran']);
          selectedPembeli = transaksi['id_pembeli'] != null
              ? {
                  'id_pembeli': transaksi['id_pembeli'],
                  'pembeli_nama': transaksi['nama_pembeli'],
                }
              : null;
          orderList = items
              .map((item) => {
                    'id_produk': item['id_produk'],
                    'nama_produk': item['nama_produk'],
                    'qty': item['qty'],
                    'harga': item['harga_jual'],
                    'foto_produk': item['foto'] ?? '',
                  })
              .toList();
          _recalculateTotal();
        });
      }
    } catch (_) {}
  }

  Future<void> fetchPembeli() async {
    final res =
        await http.get(Uri.parse('${cfg.GlobalConfig.baseUrl}/pembeli'));
    if (res.statusCode == 200) {
      setState(() =>
          pembeliList = List<Map<String, dynamic>>.from(json.decode(res.body)));
    }
  }

  Future<void> fetchProduk() async {
    final res = await http.get(Uri.parse('${cfg.GlobalConfig.baseUrl}/produk'));
    if (res.statusCode == 200) {
      setState(() =>
          produkList = List<Map<String, dynamic>>.from(json.decode(res.body)));
    }
  }

  String _metodeKodeKeString(int kode) {
    return ['-', 'Cash', 'QRIS', 'Transfer', 'Hutang'][kode];
  }

  int _metodeBayarKeKode(String method) {
    switch (method) {
      case 'Cash':
        return 1;
      case 'QRIS':
        return 2;
      case 'Transfer':
        return 3;
      case 'Hutang':
        return 4;
      default:
        return 0;
    }
  }

  Future<void> simpanPerubahanTransaksi(int statusTransaksi) async {
    final now = DateTime.now();
    final tanggalDenganWaktu = DateTime(selectedDate.year, selectedDate.month,
        selectedDate.day, now.hour, now.minute, now.second);

    final payload = {
      'id_penjualan': widget.transaksi['id_penjualan'],
      'id_transaksi': widget.transaksi['id_transaksi'],
      'tanggal_transaksi':
          DateFormat('yyyy-MM-dd HH:mm:ss').format(tanggalDenganWaktu),
      'diskon': discount,
      'total_transaksi':
          orderList.fold(0.0, (sum, item) => sum + item['qty'] * item['harga']),
      'status_transaksi': statusTransaksi,
      'id_pembeli': selectedPembeli?['id_pembeli'],
      'nama_pembeli': selectedPembeli?['pembeli_nama'],
      'metode_pembayaran': _metodeBayarKeKode(paymentMethod),
      'items': orderList
          .map((item) => {
                'id_produk': item['id_produk'],
                'qty': item['qty'],
                'harga_jual': item['harga'],
              })
          .toList(),
    };

    try {
      final response = await http.post(
        Uri.parse('${cfg.GlobalConfig.baseUrl}/penjualan/simpan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) Navigator.pop(context, true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text("Edit Transaksi")],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: KasirFormWidget(
                idtransaksi: idtransaksi,
                selectedDate: selectedDate,
                onDateChange: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => selectedDate = picked);
                },
                total: total,
                discount: discount,
                onDiscountChange: (val) {
                  discount = val;
                  _recalculateTotal();
                },
                paymentMethod: paymentMethod,
                onPaymentMethodChange: (val) =>
                    setState(() => paymentMethod = val ?? 'Cash'),
                onPilihPembeli: () async {
                  final pembeli = await showPembeliPicker(
                      context: context, pembeliList: pembeliList);
                  if (pembeli != null)
                    setState(() => selectedPembeli = pembeli);
                },
                namaPembeli: selectedPembeli?['pembeli_nama'],
                onTambahProduk: () async {
                  final produk = await showProdukPicker(
                      context: context, produkList: produkList);
                  if (produk != null) {
                    setState(() {
                      orderList.add(produk);
                      _recalculateTotal();
                    });
                  }
                },
                orderList: orderList.map((item) {
                  return {
                    ...item,
                    'foto_produk': item['foto_produk']
                            .toString()
                            .startsWith('http')
                        ? item['foto_produk']
                        : '${cfg.GlobalConfig.baseUrl}/img/${item['foto_produk']}?format=jpeg&height=60&crop=cover',
                  };
                }).toList(),
                onEditOrder: (index) async {
                  final produk = orderList[index];
                  final updated = await showQtyHargaDialog(context, produk);
                  if (updated != null) {
                    setState(() {
                      orderList[index]['qty'] = updated['qty'];
                      orderList[index]['harga'] = updated['harga'];
                      _recalculateTotal();
                    });
                  }
                },
                onDeleteOrder: (index) {
                  setState(() {
                    orderList.removeAt(index);
                    _recalculateTotal();
                  });
                },
              ),
            ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => simpanPerubahanTransaksi(0),
                child: Text("Draft"),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => simpanPerubahanTransaksi(1),
                child: Text("Simpan"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
