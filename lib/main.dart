import 'package:flutter/material.dart';
import 'package:tasarim_calismasi/anasayfa.dart';
import 'package:tasarim_calismasi/bilimsel_hesap_makinesi.dart';
import 'package:tasarim_calismasi/para_birimi_cevirme.dart';
import 'package:tasarim_calismasi/birim_cevirme.dart';
import 'package:tasarim_calismasi/gecmis_sayfasi.dart';
import 'package:tasarim_calismasi/defter_sayfasi.dart';
import 'package:tasarim_calismasi/ayarlar_sayfasi.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = true;
  List<String> historyList = [];
  List<String> notebookList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('darkMode') ?? true;
      historyList = prefs.getStringList('history') ?? [];
      notebookList = prefs.getStringList('notebook') ?? [];
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDarkMode);
    await prefs.setStringList('history', historyList);
    await prefs.setStringList('notebook', notebookList);
  }

  void _toggleTheme(bool value) {
    setState(() {
      isDarkMode = value;
    });
    _saveData();
  }

  void _addToHistory(String item) {
    setState(() {
      historyList.insert(0, item);
      if (historyList.length > 10) {
        historyList.removeLast();
      }
    });
    _saveData();
  }

  void _addToNotebook(String item) {
    setState(() {
      notebookList.insert(0, item);
    });
    _saveData();
  }

  void _updateNotebook(List<String> list) {
    setState(() {
      notebookList = list;
    });
    _saveData();
  }

  void _clearHistory() {
    setState(() {
      historyList.clear();
    });
    _saveData();
  }

  void _clearNotebook() {
    setState(() {
      notebookList.clear();
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hesap Makinesi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF9500)),
      ),
      home: Anasayfa(
        isDarkMode: isDarkMode,
        onThemeChanged: _toggleTheme,
        historyList: historyList,
        notebookList: notebookList,
        onAddToHistory: _addToHistory,
        onAddToNotebook: _addToNotebook,
        onUpdateNotebook: _updateNotebook,
        onClearHistory: _clearHistory,
        onClearNotebook: _clearNotebook,
      ),
      routes: {
        '/scientific': (context) => BilimselHesapMakinesi(
          isDarkMode: isDarkMode,
          onThemeChanged: _toggleTheme,
        ),
        '/currency': (context) => ParaBirimiCevirme(
          isDarkMode: isDarkMode,
          onThemeChanged: _toggleTheme,
        ),
        '/unit': (context) => BirimCevirme(
          isDarkMode: isDarkMode,
          onThemeChanged: _toggleTheme,
        ),
        '/history': (context) => GecmisSayfasi(
          historyList: historyList,
          onAddToNotebook: _addToNotebook,
          isDarkMode: isDarkMode,
          onThemeChanged: _toggleTheme,
        ),
        '/notebook': (context) => DefterSayfasi(
          notebookList: notebookList,
          onUpdate: _updateNotebook,
          isDarkMode: isDarkMode,
          onThemeChanged: _toggleTheme,
        ),
        '/settings': (context) => AyarlarSayfasi(
          isDarkMode: isDarkMode,
          onThemeChanged: _toggleTheme,
          onClearHistory: _clearHistory,
          onClearNotebook: _clearNotebook,
        ),
      },
    );
  }
}
