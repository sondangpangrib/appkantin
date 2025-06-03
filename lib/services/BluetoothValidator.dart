import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../printersetting.dart';

class BluetoothValidator {
  static final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  static Future<bool> validate({
    required BuildContext context,
    bool showAlert = true,
  }) async {
    bool? isConnected = await _bluetooth.isConnected;

    if (isConnected == true) return true;

    if (showAlert) {
      final scaffold = ScaffoldMessenger.of(context);
      scaffold.showSnackBar(
        SnackBar(content: Text("🔌 Printer belum terhubung")),
      );
    }

    // Buka halaman pengaturan printer
    Future.delayed(Duration(milliseconds: 300), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PrinterSetting()),
      );
    });

    return false;
  }
}
