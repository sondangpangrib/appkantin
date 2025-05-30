import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class BluetoothPrinterService {
  final BlueThermalPrinter printer = BlueThermalPrinter.instance;

  Future<List<BluetoothDevice>> getBondedDevices() async {
    return await printer.getBondedDevices();
  }

  Future<bool> isConnected() async {
    return await printer.isConnected ?? false;
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await printer.connect(device);
  }

  Future<void> disconnect() async {
    await printer.disconnect();
  }

  Future<void> printNota({
    required String toko,
    required String alamat,
    required String telp,
    required String tanggal,
    required List<Map<String, dynamic>> items,
    double diskon = 0,
    required double total,
  }) async {
    if (!(await isConnected())) return;

    printer.printNewLine();
    printer.printCustom(toko, 3, 1);
    printer.printCustom(alamat, 1, 1);
    printer.printCustom('WA: $telp', 1, 1);
    printer.printNewLine();
    printer.printCustom('Tanggal: $tanggal', 1, 0);
    printer.printNewLine();
    printer.printCustom('-----------------------------', 1, 0);
    printer.printCustom('Item        xQty     Subtotal', 1, 0);
    printer.printCustom('-----------------------------', 1, 0);

    for (var item in items) {
      final nama = item['nama'];
      final qty = item['qty'];
      final harga = item['harga'];
      final subtotal = qty * harga;
      printer.printCustom(
          '${nama.padRight(12).substring(0, 12)} x$qty   ${subtotal.toStringAsFixed(0)}',
          1,
          0);
    }

    printer.printCustom('-----------------------------', 1, 0);
    if (diskon > 0) {
      final after = total * (1 - diskon / 100);
      printer.printCustom('Diskon: $diskon%', 1, 0);
      printer.printCustom('Total: ${after.toStringAsFixed(0)}', 2, 2);
    } else {
      printer.printCustom('Total: ${total.toStringAsFixed(0)}', 2, 2);
    }

    printer.printNewLine();
    printer.printCustom('Terima kasih 🙏', 1, 1);
    printer.printNewLine();
    printer.printNewLine();
    printer.paperCut(); // jika printer mendukung
  }
}
