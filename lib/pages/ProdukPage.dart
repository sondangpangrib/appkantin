import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'TambahProdukPage.dart';
import 'EditProdukPage.dart';
import 'global_config.dart' as cfg;

class ProdukPage extends StatefulWidget {
  @override
  _ProdukPageState createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  List<dynamic> produkList = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String baseUrl = cfg.GlobalConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _checkLogin();
    _fetchProduk();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getString('user_nama');
    if (isLoggedIn == null && mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _fetchProduk({String keyword = ''}) async {
    setState(() => isLoading = true);
    try {
      final uri = Uri.parse('$baseUrl/produk?q=$keyword');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() {
          produkList = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat produk');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK')),
        ],
      ),
    );
  }

  void _onTambahProduk() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TambahProdukPage()),
    ).then((_) => _fetchProduk(keyword: _searchController.text));
  }

  Widget _buildProdukItem(Map<String, dynamic> produk) {
    final filename = produk['foto_produk']?.split('/')?.last ?? '';
    final kategori = produk['nama_produk_kategori'] ?? 'Tanpa Kategori';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: filename.isNotEmpty
            ? Image.network(
                '$baseUrl/img/$filename?format=jpeg&height=60&crop=cover',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.broken_image),
              )
            : Icon(Icons.image_not_supported, size: 60),
        title: Text(
          produk['nama_produk'] ?? '',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rp ${produk['harga']}'),
            Text('Kategori: $kategori'),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.edit, color: Colors.blue),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProdukPage(data: produk),
              ),
            ).then((_) => _fetchProduk(keyword: _searchController.text));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Produk'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _onTambahProduk,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _fetchProduk(keyword: _searchController.text),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Cari produk...',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.arrow_forward),
                        onPressed: () {
                          _fetchProduk(keyword: _searchController.text);
                          FocusScope.of(context)
                              .unfocus(); // nutup keyboard kalau ditekan tombol
                        },
                      ),
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) {
                      _fetchProduk(keyword: value);
                    },
                  ),
                ),
                Expanded(
                  child: produkList.isEmpty
                      ? Center(child: Text('Tidak ada produk ditemukan.'))
                      : ListView.builder(
                          itemCount: produkList.length,
                          itemBuilder: (ctx, index) =>
                              _buildProdukItem(produkList[index]),
                        ),
                ),
              ],
            ),
    );
  }
}
