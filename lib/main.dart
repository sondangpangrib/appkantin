import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/PengaturanPage.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<String?> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_nama');
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Kantin',
      theme: ThemeData(primarySwatch: Colors.teal),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: _checkLogin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snapshot.data == null ? LoginPage() : DashboardPage();
        },
      ),
      routes: {
        '/login': (_) => LoginPage(),
        '/dashboard': (_) => DashboardPage(),
        '/pengaturan': (_) => PengaturanPage(),
      },
    );
  }
}
