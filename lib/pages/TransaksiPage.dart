import 'dart:io';
import 'package:appkantin/pages/helper/NotaShareHelper.dart';
import 'package:appkantin/pages/widgets/nota_widget.dart';
import 'package:appkantin/printersetting.dart';
import 'package:appkantin/services/BluetoothValidator.dart';
import 'package:appkantin/services/bluetooth_printer_service.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_loading_dialog/simple_loading_dialog.dart';
import 'global_config.dart' as cfg;
import 'DetailTransaksi.dart';
import 'EditKasirPage.dart';
import 'NotaPreviewPage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'package:flutter_localizations/flutter_localizations.dart';

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
  String namaToko = "";
  String alamat = "";
  String telp = "";

  final TextEditingController _searchController = TextEditingController();
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  void __initData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      namaToko = prefs.getString('nama_toko') ?? '';
      alamat = prefs.getString('alamat_toko') ?? '';
      telp = prefs.getString('telp_wa_toko') ?? '';
    });
  }

  String formatRupiah(dynamic number) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(number ?? 0);
  }

  @override
  void initState() {
    super.initState();
    fetchTransaksi();
    __initData();
    //initPlatformState();
  }

  Future<void> shareNotaLangsungSilently({
    required Map<String, dynamic> transaksi,
    required List<dynamic> items,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final namaToko = prefs.getString('nama_toko') ?? '';
    final alamat = prefs.getString('alamat_toko') ?? '';
    final telp = prefs.getString('telp_wa_toko') ?? '';

    final controller = ScreenshotController();

    final capturedWidget = WidgetsApp(
      color: Colors.white,
      builder: (context, _) {
        return MediaQuery(
          data: MediaQueryData(
            size: Size(1080, 5000), // Buat tinggi besar agar tidak terpotong
            devicePixelRatio: 2.0,
          ),
          child: Localizations(
            locale: Locale('id', 'ID'),
            delegates: GlobalMaterialLocalizations.delegates,
            child: Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Builder(
                builder: (context) {
                  return Material(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: NotaWidget(
                          transaksi: transaksi,
                          items: items,
                          namaToko: namaToko,
                          alamat: alamat,
                          telp: telp,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    try {
      final image = await controller.captureFromWidget(
        capturedWidget,
        delay: Duration(milliseconds: 300),
        pixelRatio: 2.0,
      );

      if (image == null) {
        print("❌ Gagal capture");
        return;
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/nota-${transaksi['id_transaksi']}.png');
      file.writeAsBytesSync(image);
      await Share.shareXFiles([XFile(file.path)], text: 'Nota Transaksi');
    } catch (e) {
      print("❌ Error: $e");
    }
  }

  Future<void> __getDetail(int id_penjualan) async {
    Map<String, dynamic>? transaksi;
    List<dynamic> items = [];

    final result = await showSimpleLoadingDialog<String>(
      context: context,
      future: () async {
        final url =
            '${cfg.GlobalConfig.baseUrl}/penjualan/detail?id_penjualan=$id_penjualan';

        try {
          final res = await http.get(Uri.parse(url));
          if (res.statusCode == 200) {
            final data = json.decode(res.body);
            if (data['transaksi'] != null) {
              transaksi = data['transaksi'];
              items = data['items'];
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Gagal dapatkan data (status ${res.statusCode})')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }

        return 'done';
      },
    );

    // ✅ Lakukan navigasi setelah dialog tertutup
    if (transaksi != null) {
      /*
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NotaPreviewPage(
            transaksi: transaksi!,
            items: items,
          ),
        ),
      );*/

      await shareNotaLangsungSilently(transaksi: transaksi!, items: items);
    }
  }

  Future<void> __doPrint(int id_penjualan) async {
    Map<String, dynamic>? transaksi;
    List<dynamic> items = [];

    final result = await showSimpleLoadingDialog<String>(
      context: context,
      future: () async {
        final url =
            '${cfg.GlobalConfig.baseUrl}/penjualan/detail?id_penjualan=$id_penjualan';

        try {
          final res = await http.get(Uri.parse(url));
          if (res.statusCode == 200) {
            final data = json.decode(res.body);
            if (data['transaksi'] != null) {
              transaksi = data['transaksi'];
              items = data['items'];
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Gagal dapatkan data (status ${res.statusCode})')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }

        return 'done';
      },
    );

    // ✅ Lakukan navigasi setelah dialog tertutup
    if (transaksi != null) {
      final trx = transaksi;
      final _tanggal = DateFormat('dd-MM-yyyy')
          .format(DateTime.parse('${trx?['tanggal_transaksi']}'));

      double diskon = (trx?['diskon'] as num).toDouble();
      int _total = (trx?['total_transaksi'] ?? 0);

      print("NOTA ${namaToko} - ${alamat} - ${_tanggal}");
      print("NOTA2 ${diskon.toString()} - ${_total}");
      print("🔊 Mencetak nota...");

      final isValid = await BluetoothValidator.validate(context: context);
      if (!isValid) return;
      final printer = BluetoothPrinterService();
      print("🧾 ITEM DEBUG:");
      items.forEach((item) {
        print(
            "Nama: ${item['nama']}, Qty: ${item['qty']}, Harga: ${item['harga_jual'] ?? item['harga']}");
      });
      await printer.printNota(
        toko: namaToko, // ganti sesuai kebutuhan
        alamat: alamat,
        telp: telp,
        tanggal: _tanggal,
        diskon: diskon,
        total: _total.toDouble(),
        items: items
            .map((item) => {
                  'nama': item['nama_produk'] ?? item['nama'] ?? '-',
                  'qty': item['qty'],
                  'harga': item['harga_jual'] ?? item['harga'] ?? 0,
                })
            .toList(),
      );
    }
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
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            onTap: () {
              setState(() {
                expandedList[index] = !expandedList[index];
              });
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
          Container(
            width: double.infinity,
            color: getStatusColor(status), // background merah
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // biar ada jarak antar teks
              children: [
                Text(
                  'Total: ${formatRupiah(total)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // teks putih
                  ),
                ),
                Text(
                  'Net: ${formatRupiah(net)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white, // teks putih
                  ),
                ),
              ],
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailTransaksiPage(
                              idPenjualan: trx['id_penjualan']),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.remove_red_eye, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 5),
                  InkWell(
                    onTap: () async {
                      __getDetail(trx['id_penjualan']);
                    },
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 9, 204, 64),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.share_rounded, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 5),
                  InkWell(
                    onTap: () async {
                      __doPrint(trx['id_penjualan']);
                    },
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 247, 50, 247),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.print, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 5),
                  Visibility(
                    visible: (status == 1) ? true : false,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditKasirPage(transaksi: trx),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 232, 18, 121),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.edit, color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                  Row(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: getStatusColor(status),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(getStatusLabel(status),
                            style:
                                TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
