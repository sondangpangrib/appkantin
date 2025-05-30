import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PengaturanPage extends StatefulWidget {
  @override
  _PengaturanPageState createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  String _selectedUkuran = '58';

  @override
  void initState() {
    super.initState();
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedUkuran = prefs.getString('printer_ukuran') ?? '58';
    });
  }

  Future<void> _simpanSetting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_ukuran', _selectedUkuran);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ukuran printer disimpan: $_selectedUkuran mm')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pengaturan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih Ukuran Kertas:', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            RadioListTile<String>(
              title: Text('58 mm'),
              value: '58',
              groupValue: _selectedUkuran,
              onChanged: (val) => setState(() => _selectedUkuran = val!),
            ),
            RadioListTile<String>(
              title: Text('80 mm'),
              value: '80',
              groupValue: _selectedUkuran,
              onChanged: (val) => setState(() => _selectedUkuran = val!),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text('Simpan Pengaturan'),
              onPressed: _simpanSetting,
            ),
          ],
        ),
      ),
    );
  }
}
