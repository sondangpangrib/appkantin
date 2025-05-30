import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'KasirPage.dart';
import 'TransaksiPage.dart';
import 'PembeliPage.dart';
import 'ProdukPage.dart';
import 'PengeluaranPage.dart';
import 'LaporanPenjualanPage.dart';
import 'LaporanPengeluaranPage.dart';
import 'ManajemenUserPage.dart';
import 'ManajemenTokoPage.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String namaToko = '', alamat = '', telp = '', namaUser = '';
  int userTipe = 0;
  int _selectedIndex = 0;

  final List<Widget> menuWidgetUser = [
    KasirPage(),
    TransaksiPage(),
    PembeliPage(),
    ProdukPage(),
    PengeluaranPage(),
    LaporanPenjualanPage(),
    LaporanPengeluaranPage(),
  ];

  final List<Widget> menuWidgetAdminExtra = [
    ManajemenUserPage(),
    ManajemenTokoPage(),
  ];

  final List<Map<String, dynamic>> menuUser = [
    {'icon': Icons.point_of_sale, 'label': 'Kasir'},
    {'icon': Icons.receipt, 'label': 'Transaksi'},
    {'icon': Icons.group, 'label': 'Pembeli'},
    {'icon': Icons.inventory, 'label': 'Produk'},
    {'icon': Icons.money_off, 'label': 'Pengeluaran'},
    {'icon': Icons.bar_chart, 'label': 'Laporan Penjualan'},
    {'icon': Icons.assignment, 'label': 'Laporan Pengeluaran'},
  ];

  final List<Map<String, dynamic>> menuAdminExtra = [
    {'icon': Icons.supervisor_account, 'label': 'Manajemen User'},
    {'icon': Icons.store, 'label': 'Manajemen Toko'},
  ];

  @override
  void initState() {
    _checkLogin();
    super.initState();
    _loadData();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getString('user_nama');
    if (isLoggedIn == null && mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      namaToko = prefs.getString('nama_toko') ?? '';
      alamat = prefs.getString('alamat_toko') ?? '';
      telp = prefs.getString('telp_wa_toko') ?? '';
      namaUser = prefs.getString('user_nama') ?? '';
      userTipe = prefs.getInt('user_tipe') ?? 0;
    });
  }

  List<Map<String, dynamic>> _buildMenuData() {
    final menu = [...menuUser];
    if (userTipe == 1) menu.addAll(menuAdminExtra);
    return menu;
  }

  List<Widget> _buildWidgets() {
    final list = [...menuWidgetUser];
    if (userTipe == 1) list.addAll(menuWidgetAdminExtra);
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = _buildMenuData();

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/pengaturan');
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _buildWidgets(),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: menuItems.asMap().entries.map((entry) {
              int index = entry.key;
              var item = entry.value;
              bool isSelected = _selectedIndex == index;

              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = index),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[100] : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item['icon'],
                          color: isSelected ? Colors.blue : Colors.black),
                      SizedBox(height: 4),
                      Text(
                        item['label'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.blue : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
