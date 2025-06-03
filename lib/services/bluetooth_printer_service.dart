import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';

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

  String formatRupiah(num amount) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
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

    const int lineWidth = 48;
    printer.printNewLine();
    printer.printCustom(toko, 3, 1);
    printer.printCustom(alamat, 1, 1);
    printer.printCustom('WA: $telp', 1, 1);
    printer.printNewLine();
    printer.printCustom('Tanggal: $tanggal', 1, 0);
    printer.printCustom('-' * lineWidth, 1, 0);
    printer.printCustom(
        'Item                    Qty             Subtotal', 1, 0);
    printer.printCustom('-' * lineWidth, 1, 0);

    printer.printCustom('-' * 48, 1, 0);

    for (var item in items) {
      final nama = item['nama']?.toString() ?? '-';
      final qty = item['qty'] ?? 0;
      final harga = item['harga'] ?? 0;
      final subtotal = qty * harga;

      final namaFix =
          nama.length > 17 ? nama.substring(0, 17) : nama.padRight(17);
      final qtyStr = qty.toString().padLeft(3);
      final subtotalStr =
          formatRupiah(subtotal).padLeft(16); // <- push ke kanan

      printer.printCustom('$namaFix      $qtyStr      $subtotalStr', 1, 0);
    }

    printer.printCustom('-' * lineWidth, 1, 0);
    if (diskon > 0) {
      final after = total * (1 - diskon / 100);
      printer.printCustom('Diskon: $diskon%', 1, 2);
      printer.printCustom('Total : ${formatRupiah(after)}', 2, 2);
    } else {
      printer.printCustom('Total : ${formatRupiah(total)}', 2, 2);
    }

    printer.printNewLine();
    printer.printCustom('Terima kasih 🙏', 1, 1);
    printer.printNewLine();
    printer.printNewLine();
    printer.printNewLine();
    //printer.paperCut(); // jika printer mendukung
  }
}
