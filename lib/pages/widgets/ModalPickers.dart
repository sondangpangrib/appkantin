import 'package:flutter/material.dart';

Future<Map<String, dynamic>?> showPembeliPicker({
  required BuildContext context,
  required List<Map<String, dynamic>> pembeliList,
}) async {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredList = List.from(pembeliList);

  return await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Cari pembeli',
                prefixIcon: Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (query) {
                setState(() {
                  filteredList = pembeliList
                      .where((p) => p['pembeli_nama']
                          .toString()
                          .toLowerCase()
                          .contains(query.toLowerCase()))
                      .toList();
                });
              },
            ),
            SizedBox(height: 10),
            ...filteredList.map((p) => ListTile(
                  leading: p['foto'] != null && p['foto'] != ''
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(p['foto']),
                        )
                      : CircleAvatar(child: Icon(Icons.person)),
                  title: Text(p['pembeli_nama']),
                  subtitle: Text(p['pembeli_no_telp'] ?? '-'),
                  onTap: () => Navigator.pop(context, p),
                ))
          ],
        ),
      ),
    ),
  );
}

Future<Map<String, dynamic>?> showProdukPicker({
  required BuildContext context,
  required List<Map<String, dynamic>> produkList,
}) async {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredList = List.from(produkList);

  return await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Cari produk',
                prefixIcon: Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (query) {
                setState(() {
                  filteredList = produkList
                      .where((p) => p['nama_produk']
                          .toString()
                          .toLowerCase()
                          .contains(query.toLowerCase()))
                      .toList();
                });
              },
            ),
            SizedBox(height: 10),
            ...filteredList.map((p) => ListTile(
                  leading: p['foto_produk'] != null && p['foto_produk'] != ''
                      ? Image.network(
                          p['foto_produk'],
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        )
                      : Icon(Icons.image),
                  title: Text(p['nama_produk']),
                  subtitle: Text("Rp ${p['harga']}"),
                  onTap: () async {
                    final qtyHarga = await showQtyHargaDialog(context, p);
                    if (qtyHarga != null) {
                      Navigator.pop(context, {
                        'id_produk': p['id_produk'],
                        'nama_produk': p['nama_produk'],
                        'qty': qtyHarga['qty'],
                        'harga': qtyHarga['harga'],
                        'foto_produk': p['foto_produk'] ?? '',
                      });
                    }
                  },
                ))
          ],
        ),
      ),
    ),
  );
}

Future<Map<String, dynamic>?> showQtyHargaDialog(
    BuildContext context, Map<String, dynamic> produk) async {
  final qtyController = TextEditingController(text: '1');
  final hargaController =
      TextEditingController(text: produk['harga'].toString());

  return await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => AlertDialog(
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
          onPressed: () => Navigator.pop(context),
          child: Text("Batal"),
        ),
        ElevatedButton(
          onPressed: () {
            final qty = int.tryParse(qtyController.text) ?? 1;
            final harga =
                double.tryParse(hargaController.text) ?? produk['harga'];
            if (qty <= 0 || harga <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Qty dan harga harus lebih dari 0")),
              );
              return;
            }
            Navigator.pop(context, {'qty': qty, 'harga': harga});
          },
          child: Text("Simpan"),
        ),
      ],
    ),
  );
}
