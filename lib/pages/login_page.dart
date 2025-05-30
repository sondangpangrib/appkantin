// lib/pages/login_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'global_config.dart' as cfg;

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _telpController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await http
        .post(Uri.parse('${cfg.GlobalConfig.baseUrl}/auth'), body: {
      'user_telp': _telpController.text,
      'user_password': _passController.text
    });

    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt('id_user', data['user']['id_user']);
      await prefs.setString('user_nama', data['user']['user_nama']);
      await prefs.setString('user_telp', data['user']['user_telp']);
      await prefs.setInt('user_tipe', data['user']['user_tipe']);
      await prefs.setInt('id_toko', data['shop']['id_toko']);
      await prefs.setString('nama_toko', data['shop']['nama_toko']);
      await prefs.setString('alamat_toko', data['shop']['alamat_toko']);
      await prefs.setString('telp_wa_toko', data['shop']['telp_wa_toko']);

      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      setState(() {
        _error = 'Login gagal';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _telpController,
              decoration: InputDecoration(labelText: 'No Telepon'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _passController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: Colors.red)),
              ),
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading ? CircularProgressIndicator() : Text('Login'))
          ],
        ),
      ),
    );
  }
}
