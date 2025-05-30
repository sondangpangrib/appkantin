import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/bluetooth_printer_service.dart';

class KasirPage extends StatefulWidget {
  @override
  _KasirPageState createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> {
  List<Map<String, dynamic>> keranjang = [];
  double total = 0;
  double diskon = 0;
  int metodePembayaran = 2;
  Map<String, dynamic>? pembeli;
  TextEditingController _diskonController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getString('user_nama');
    if (isLoggedIn == null && mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void tambahProduk(Map<String, dynamic> produk) {
    showDialog(
      context: context,
      builder: (ctx) {
        int qty = 1;
        TextEditingController hargaJualController =
            TextEditingController(text: produk['harga'].toString());

        return AlertDialog(
          title: Text(produk['nama_produk']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Qty'),
                onChanged: (val) => qty = int.tryParse(val) ?? 1,
              ),
              TextField(
                controller: hargaJualController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Harga Jual'),
              )
            ],
          ),
          actions: [
            TextButton(
              child: Text('Tambah'),
              onPressed: () {
                setState(() {
                  keranjang.add({
                    'id_produk': produk['id_produk'],
                    'nama': produk['nama_produk'],
                    'qty': qty,
                    'harga': double.tryParse(hargaJualController.text) ?? 0,
                    'foto': produk['foto_produk']
                  });
                  hitungTotal();
                });
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }

  void hapusItem(int index) {
    setState(() {
      keranjang.removeAt(index);
      hitungTotal();
    });
  }

  void hitungTotal() {
    total =
        keranjang.fold(0, (sum, item) => sum + (item['qty'] * item['harga']));
    diskon = double.tryParse(_diskonController.text) ?? 0;
    setState(() {});
  }

  void pilihPembayaran(int? value) async {
    if (value == 1) {
      final res = await http.get(Uri.parse('http://localhost:3000/pembeli'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final chosen = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (ctx) {
            List filtered = [...data];
            TextEditingController cari = TextEditingController();
            return StatefulBuilder(
              builder: (ctx, setState) => AlertDialog(
                title: Column(
                  children: [
                    TextField(
                      controller: cari,
                      decoration: InputDecoration(hintText: 'Cari pembeli...'),
                      onChanged: (val) {
                        setState(() {
                          filtered = data
                              .where((p) => p['pembeli_nama']
                                  .toLowerCase()
                                  .contains(val.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => ListTile(
                          title: Text(filtered[i]['pembeli_nama']),
                          onTap: () => Navigator.pop(ctx, filtered[i]),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
        if (chosen != null) {
          setState(() {
            pembeli = chosen;
          });
        }
      }
    } else {
      setState(() {
        pembeli = null;
      });
    }
    setState(() {
      metodePembayaran = value ?? 2;
    });
  }

  Future<void> simpanTransaksi({int status = 1}) async {
    if (keranjang.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Keranjang tidak boleh kosong')),
      );
      return;
    }
    if (metodePembayaran == 1 && pembeli == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Pembeli harus dipilih jika metode pembayaran hutang')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final idSeles = prefs.getInt('id_user');
    final toko = prefs.getString('nama_toko') ?? '';
    final alamat = prefs.getString('alamat_toko') ?? '';
    final telp = prefs.getString('telp_wa_toko') ?? '';
    final tanggal = DateTime.now().toString().substring(0, 19);

    final res = await http.post(Uri.parse('http://localhost:3000/penjualan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_pembeli': pembeli?['id_pembeli'],
          'id_seles': idSeles,
          'nama_pembeli': pembeli != null ? pembeli!['pembeli_nama'] : 'Umum',
          'metode_pembayaran': metodePembayaran,
          'diskon': diskon,
          'total_transaksi': total * (1 - diskon / 100),
          'status_transaksi': status
        }));

    if (res.statusCode == 200) {
      final idPenjualan = jsonDecode(res.body)['id'];
      for (var item in keranjang) {
        await http.post(Uri.parse('http://localhost:3000/penjualan/order-item'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id_penjualan': idPenjualan,
              'id_produk': item['id_produk'],
              'qty': item['qty'],
              'harga_jual': item['harga']
            }));
      }

      if (status == 1) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Transaksi Disimpan'),
            content: Text('Cetak nota sekarang?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Tidak'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Ya'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await BluetoothPrinterService().printNota(
            toko: toko,
            alamat: alamat,
            telp: telp,
            tanggal: tanggal,
            items: keranjang,
            diskon: diskon,
            total: total,
          );
        }
      }

      setState(() {
        keranjang.clear();
        _diskonController.text = '0';
        total = 0;
        diskon = 0;
        pembeli = null;
        metodePembayaran = 2;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan transaksi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kasir')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: Rp ${total.toStringAsFixed(0)}'),
                Expanded(
                  child: TextField(
                    controller: _diskonController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Diskon %'),
                    onChanged: (_) => hitungTotal(),
                  ),
                )
              ],
            ),
            DropdownButton<int>(
              value: metodePembayaran,
              items: [
                DropdownMenuItem(child: Text('Hutang'), value: 1),
                DropdownMenuItem(child: Text('Cash'), value: 2),
                DropdownMenuItem(child: Text('QRIS'), value: 3),
                DropdownMenuItem(child: Text('Transfer'), value: 4),
              ],
              onChanged: pilihPembayaran,
            ),
            if (pembeli != null) Text('Pembeli: ${pembeli!['pembeli_nama']}'),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: keranjang.length,
                itemBuilder: (_, i) => ListTile(
                  leading: keranjang[i]['foto'] != null
                      ? Image.network(
                          'http://localhost:3000/uploads/${keranjang[i]['foto']}',
                          width: 50,
                          height: 50,
                        )
                      : null,
                  title: Text(keranjang[i]['nama']),
                  subtitle: Text(
                      'x${keranjang[i]['qty']} @ ${keranjang[i]['harga']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => hapusItem(i),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => simpanTransaksi(status: 1),
                    child: Text('Simpan'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => simpanTransaksi(status: 2),
                    child: Text('Draft'),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
