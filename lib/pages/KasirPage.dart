import 'package:appkantin/services/bluetooth_printer_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'global_config.dart' as cfg;
import 'package:intl/intl.dart';
import 'TambahProdukPage.dart';

class KasirPage extends StatefulWidget {
  @override
  _KasirPageState createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> {
  DateTime selectedDate = DateTime.now();
  double total = 0;
  double discount = 0;
  String paymentMethod = 'Cash';
  String baseUrl = cfg.GlobalConfig.baseUrl;
  TextEditingController _searchPembeliController = TextEditingController();
  TextEditingController _searchProdukController = TextEditingController();
  List<dynamic> pembeliList = [];
  List<dynamic> produkList = [];
  List<Map<String, dynamic>> orderList = [];
  dynamic selectedPembeli;

  @override
  void initState() {
    super.initState();
    _fetchServerDate();
    _fetchPembeli();
    _fetchProduk();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _fetchServerDate() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/penjualan/tanggal-hari-ini'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          selectedDate = DateTime.parse(data['tanggal']);
        });
      }
    } catch (e) {
      print('Gagal ambil tanggal server: $e');
    }
  }

  Future<void> _fetchPembeli() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pembeli'));
      if (response.statusCode == 200) {
        setState(() {
          pembeliList = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Gagal ambil data pembeli: $e');
    }
  }

  Future<void> _fetchProduk() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/produk'));
      if (response.statusCode == 200) {
        setState(() {
          produkList = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Gagal ambil data produk: $e');
    }
  }

  void _showQtyDialog(Map<String, dynamic> produk, [int? index]) {
    final qtyController = TextEditingController(
        text: index != null ? orderList[index]['qty'].toString() : '1');
    final hargaController = TextEditingController(
        text: index != null
            ? orderList[index]['harga'].toString()
            : produk['harga'].toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(produk['nama_produk']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Qty'),
            ),
            TextField(
              controller: hargaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Harga Jual'),
            ),
          ],
        ),
        actions: [
          TextButton(
              child: Text('Batal'), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            child: Text('Simpan'),
            onPressed: () {
              final qty = int.tryParse(qtyController.text) ?? 1;
              final harga =
                  double.tryParse(hargaController.text) ?? produk['harga'];
              setState(() {
                if (index != null) {
                  total -= orderList[index]['qty'] * orderList[index]['harga'];
                  orderList[index]['qty'] = qty;
                  orderList[index]['harga'] = harga;
                } else {
                  orderList.add({
                    'id_produk': produk['id_produk'],
                    'nama_produk': produk['nama_produk'],
                    'qty': qty,
                    'harga': harga,
                    'foto_produk': produk['foto_produk'] ?? '',
                  });
                }
                _recalculateTotal();
              });
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  void _recalculateTotal() {
    total =
        orderList.fold(0, (sum, item) => sum + (item['qty'] * item['harga']));
    total -= (total * (discount / 100));
  }

  void _showProdukPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        List<dynamic> filteredProduk = produkList;
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchProdukController,
                        decoration: InputDecoration(
                          hintText: 'Cari produk',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (query) {
                          setModalState(() {
                            filteredProduk = produkList
                                .where((p) => p['nama_produk']
                                    .toLowerCase()
                                    .contains(query.toLowerCase()))
                                .toList();
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, color: Colors.blue),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => TambahProdukPage()));
                      },
                    )
                  ],
                ),
                SizedBox(height: 10),
                ...filteredProduk.map((p) => ListTile(
                      leading: p['foto_produk'] != null &&
                              p['foto_produk'] != ''
                          ? Image.network(
                              '$baseUrl/img/${p['foto_produk']}?format=jpeg&height=60&crop=cover',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover)
                          : Icon(Icons.image, size: 40),
                      title: Text(p['nama_produk']),
                      subtitle: Text("Rp ${p['harga']}"),
                      onTap: () => _showQtyDialog(p),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

/*
  Future<void> _saveDraft() async {
    if (orderList.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Order tidak boleh kosong!!"),
          actions: [
            TextButton(
                child: Text("OK"), onPressed: () => Navigator.pop(context))
          ],
        ),
      );
      return;
    }

    if (paymentMethod == 'Hutang' && selectedPembeli == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Pembayaran hutang harus pilih pembeli!!"),
          actions: [
            TextButton(
                child: Text("OK"), onPressed: () => Navigator.pop(context))
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Yakin simpan order ini sebagai draft?"),
        actions: [
          TextButton(
              child: Text("Tidak"), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            child: Text("Ya"),
            onPressed: () async {
              Navigator.pop(context);
              final draftData = {
                'tanggal': selectedDate.toIso8601String(),
                'metode': paymentMethod,
                'diskon': discount,
                'total': total - (total * discount / 100),
                'pembeli_id': selectedPembeli != null
                    ? selectedPembeli['id_pembeli']
                    : null,
                'items': orderList,
              };
              try {
                final response = await http.post(
                  Uri.parse('$baseUrl/penjualan/draft'),
                  headers: {"Content-Type": "application/json"},
                  body: json.encode(draftData),
                );
                if (response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Draft berhasil disimpan")));
                  setState(() {
                    orderList.clear();
                    selectedPembeli = null;
                    discount = 0;
                    total = 0;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Gagal simpan draft")));
                }
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
          )
        ],
      ),
    );
  }
  */
  /// ======== _saveDraft ======///

  Future<void> _saveDraft() async {
    if (orderList.isEmpty) {
      _showMessage("Order tidak boleh kosong !!");
      return;
    }
    if (paymentMethod == 'Hutang' && selectedPembeli == null) {
      _showMessage("Pembayaran hutang harus pilih pembeli !!");
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Yakin simpan order ini sebagai draft?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Tidak")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true), child: Text("Ya"))
        ],
      ),
    );
    if (confirm == true) simpanTransaksiKeServer(0);
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))
        ],
      ),
    );
  }

  Future<void> simpanTransaksiKeServer(int status) async {
    final prefs = await SharedPreferences.getInstance();
    final __iduser = prefs.getInt('id_user');
    final payload = {
      'id_seles': __iduser,
      'id_transaksi': DateTime.now().millisecondsSinceEpoch.toString(),
      'tanggal_transaksi': DateFormat('yyyy-MM-dd').format(selectedDate),
      'id_pembeli': selectedPembeli?['id_pembeli'],
      'nama_pembeli': selectedPembeli?['pembeli_nama'],
      'metode_pembayaran': _metodeBayarKeKode(paymentMethod),
      'diskon': discount,
      'total_transaksi': _hitungTotalSetelahDiskon(),
      'status_transaksi': status,
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
        Uri.parse('$baseUrl/penjualan/simpan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Berhasil disimpan.")));

        //// print nota ///
        final shouldPrint = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Print Nota?"),
            actions: [
              TextButton(
                child: Text("Tidak"),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                child: Text("Ya"),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );

        if (shouldPrint == true) {
          final printer = BluetoothPrinterService();
          await printer.printNota(
            toko: "Nama Toko", // ganti sesuai kebutuhan
            alamat: "Jl. Contoh No.1",
            telp: "0812-xxxx-xxxx",
            tanggal: DateFormat('dd-MM-yyyy').format(selectedDate),
            diskon: discount,
            total: _hitungTotalSetelahDiskon(),
            items: orderList
                .map((item) => {
                      'nama': item['nama_produk'],
                      'qty': item['qty'],
                      'harga': item['harga'],
                    })
                .toList(),
          );
        }
        //// end print nota ///
        setState(() {
          orderList.clear();
          total = 0;
          discount = 0;
          selectedPembeli = null;
        });
      } else {
        print('Gagal simpan: ${response.body}');
        _showMessage("Gagal simpan!");
      }
    } catch (e) {
      print('Error simpan transaksi: $e');
      _showMessage("Terjadi kesalahan saat simpan.");
    }
  }

  double _hitungTotalSetelahDiskon() {
    double rawTotal =
        orderList.fold(0, (sum, item) => sum + (item['qty'] * item['harga']));
    return rawTotal * (1 - discount / 100);
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

//======================= ////
  void _showPembeliPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        List<dynamic> filteredList = pembeliList;
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchPembeliController,
                        decoration: InputDecoration(
                          hintText: 'Cari pembeli',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (query) {
                          setModalState(() {
                            filteredList = pembeliList
                                .where((p) => p['pembeli_nama']
                                    .toLowerCase()
                                    .contains(query.toLowerCase()))
                                .toList();
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.person_add_alt_1, color: Colors.green),
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Navigasi ke tambah pembeli
                      },
                    )
                  ],
                ),
                SizedBox(height: 10),
                ...filteredList.map((p) => ListTile(
                      leading: p['foto'] != null && p['foto'] != ''
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(
                                  '$baseUrl/img/${p['foto']}?format=jpeg&height=60&crop=cover'))
                          : CircleAvatar(child: Icon(Icons.person)),
                      title: Text(p['pembeli_nama']),
                      subtitle: Text(p['pembeli_no_telp'] ?? '-'),
                      onTap: () {
                        setState(() => selectedPembeli = p);
                        Navigator.pop(context);
                      },
                    ))
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Kasir"),
              GestureDetector(
                onTap: _selectDate,
                child: Text(
                  DateFormat('dd-MM-yyyy').format(selectedDate),
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total: Rp ${total.toStringAsFixed(0)}"),
                  Row(
                    children: [
                      Text("Diskon %: "),
                      SizedBox(
                        width: 50,
                        child: TextField(
                          textAlign: TextAlign.end,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              discount = double.tryParse(value) ?? 0;
                              _recalculateTotal();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (paymentMethod == 'Hutang')
                InkWell(
                  onTap: _showPembeliPicker,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 20, color: Colors.purple),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            selectedPembeli != null
                                ? selectedPembeli['pembeli_nama']
                                : 'Pilih Pembeli',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Icon(Icons.edit, color: Colors.purple)
                      ],
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text("Tambah Produk"),
                    onPressed: _showProdukPicker,
                  ),
                  DropdownButton<String>(
                    value: paymentMethod,
                    items: ['Cash', 'QRIS', 'Transfer', 'Hutang']
                        .map((method) => DropdownMenuItem(
                              child: Text(method),
                              value: method,
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => paymentMethod = value!);
                    },
                  )
                ],
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: orderList.length,
                  itemBuilder: (context, index) {
                    final item = orderList[index];
                    final foto = item['foto_produk'] ?? '';
                    return ListTile(
                      onTap: () => _showQtyDialog(item, index),
                      leading: foto.isNotEmpty
                          ? Image.network(
                              '$baseUrl/img/$foto?format=jpeg&height=60&crop=cover',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover)
                          : Icon(Icons.image, size: 40),
                      title: Text(item['nama_produk'],
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle:
                          Text("Qty: ${item['qty']} x Rp ${item['harga']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              "Rp ${(item['qty'] * item['harga']).toStringAsFixed(0)}"),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                total -= item['qty'] * item['harga'];
                                orderList.removeAt(index);
                                _recalculateTotal();
                              });
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      print("Isi orderList: $orderList");
                      _saveDraft();
                    },
                    child: Text("Draft"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (orderList.isEmpty) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text("Order tidak boleh kosong!"),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("OK")),
                            ],
                          ),
                        );
                        return;
                      }

                      if (paymentMethod == 'Hutang' &&
                          selectedPembeli == null) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(
                                "Pembayaran Hutang Harus masukan pembeli!!"),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("OK")),
                            ],
                          ),
                        );
                        return;
                      }

                      await simpanTransaksiKeServer(1); // Simpan final
                    },
                    child: Text("Simpan"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
