import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LaporanPenjualanPage extends StatefulWidget {
  @override
  _LaporanPenjualanPageState createState() => _LaporanPenjualanPageState();
}

class _LaporanPenjualanPageState extends State<LaporanPenjualanPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Laporan Penjualan Page')),
    );
  }
}
