import 'package:appkantin/pages/widgets/nota_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/NotaShareHelper.dart';

class NotaShareHelper {
  static Future<bool> share(BuildContext context,
      Map<String, dynamic> transaksi, List<dynamic> items) async {
    try {
      if (items.isEmpty) return false;

      final prefs = await SharedPreferences.getInstance();
      final String namaToko = prefs.getString('nama_toko') ?? '';
      final String alamat = prefs.getString('alamat_toko') ?? '';
      final String telp = prefs.getString('telp_wa_toko') ?? '';

      final screenshotController = ScreenshotController();

      final notaWidget = MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
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

      final image = await screenshotController.captureFromWidget(notaWidget);
      if (image == null) return false;

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/nota-${transaksi['id_transaksi']}.png';
      final file = File(path)..writeAsBytesSync(image);

      await Share.shareXFiles([XFile(file.path)], text: 'Nota Transaksi');
      return true;
    } catch (e) {
      print("❌ Error saat share nota: $e");
      return false;
    }
  }
}
