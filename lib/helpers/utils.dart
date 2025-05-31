import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../pages/global_config.dart' as cfg;

Future<void> bukaNotaPDF(BuildContext context, String idTransaksi) async {
  final url =
      '${cfg.GlobalConfig.baseUrl}/api/penjualan/nota/pdf?id_transaksi=$idTransaksi';
  final uri = Uri.parse(url);

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tidak bisa membuka nota PDF')),
    );
  }
}
