import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'drawer_widget.dart';

class AyarlarSayfasi extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final VoidCallback onClearHistory;
  final VoidCallback onClearNotebook;

  const AyarlarSayfasi({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onClearHistory,
    required this.onClearNotebook,
  });

  @override
  State<AyarlarSayfasi> createState() => _AyarlarSayfasiState();
}

class _AyarlarSayfasiState extends State<AyarlarSayfasi> {
  bool _vibrationEnabled = true;
  bool _soundEnabled = false;
  int _decimalPlaces = 8;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _vibrationEnabled = prefs.getBool('vibration') ?? true;
      _soundEnabled = prefs.getBool('sound') ?? false;
      _decimalPlaces = prefs.getInt('decimalPlaces') ?? 8;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode
            ? const Color(0xFF1E293B)
            : Colors.white,
        title: Text(
          "Geçmişi Temizle",
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          "Tüm hesaplama geçmişi silinecek. Bu işlem geri alınamaz.",
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Vazgeç"),
          ),
          TextButton(
            onPressed: () {
              widget.onClearHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Geçmiş temizlendi!")),
              );
            },
            child: const Text("Temizle", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearNotebookDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode
            ? const Color(0xFF1E293B)
            : Colors.white,
        title: Text(
          "Defteri Temizle",
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          "Defterdeki tüm kayıtlar silinecek. Bu işlem geri alınamaz.",
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Vazgeç"),
          ),
          TextButton(
            onPressed: () {
              widget.onClearNotebook();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Defter temizlendi!")),
              );
            },
            child: const Text("Temizle", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = widget.isDarkMode
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
    Color cardColor = widget.isDarkMode
        ? const Color(0xFF1E293B)
        : Colors.white;
    Color textColor = widget.isDarkMode
        ? Colors.white
        : const Color(0xFF0F172A);
    Color subTextColor = widget.isDarkMode
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    Color appBarColor = widget.isDarkMode
        ? const Color(0xFF0F172A)
        : const Color(0xFFFF9500);
    Color accentColor = const Color(0xFFFF9500);

    return Scaffold(
      backgroundColor: bgColor,
      drawer: AppDrawer(isDarkMode: widget.isDarkMode, currentPage: 'settings'),
      appBar: AppBar(
        title: const Text("Ayarlar"),
        centerTitle: true,
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menü',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle("Görünüm", textColor),
          Card(
            color: cardColor,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    "Karanlık Mod",
                    style: TextStyle(color: textColor),
                  ),
                  subtitle: Text(
                    widget.isDarkMode
                        ? "Karanlık tema aktif"
                        : "Aydınlık tema aktif",
                    style: TextStyle(color: subTextColor, fontSize: 12),
                  ),
                  secondary: Icon(
                    widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: accentColor,
                  ),
                  value: widget.isDarkMode,
                  activeColor: accentColor,
                  onChanged: (value) {
                    widget.onThemeChanged(value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionTitle("Hesaplama", textColor),
          Card(
            color: cardColor,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.pin, color: accentColor),
                  title: Text(
                    "Ondalık Basamak",
                    style: TextStyle(color: textColor),
                  ),
                  subtitle: Text(
                    "Sonuçlarda $_decimalPlaces basamak göster",
                    style: TextStyle(color: subTextColor, fontSize: 12),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      value: _decimalPlaces,
                      underline: const SizedBox(),
                      dropdownColor: cardColor,
                      style: TextStyle(color: textColor),
                      items: [2, 4, 6, 8, 10].map((val) {
                        return DropdownMenuItem(
                          value: val,
                          child: Text("$val"),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _decimalPlaces = val!;
                        });
                        _saveSetting('decimalPlaces', val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionTitle("Geri Bildirim", textColor),
          Card(
            color: cardColor,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text("Titreşim", style: TextStyle(color: textColor)),
                  subtitle: Text(
                    "Buton basımında titreşim",
                    style: TextStyle(color: subTextColor, fontSize: 12),
                  ),
                  secondary: Icon(Icons.vibration, color: accentColor),
                  value: _vibrationEnabled,
                  activeColor: accentColor,
                  onChanged: (value) {
                    setState(() {
                      _vibrationEnabled = value;
                    });
                    _saveSetting('vibration', value);
                  },
                ),
                Divider(height: 1, color: subTextColor.withOpacity(0.2)),
                SwitchListTile(
                  title: Text("Ses", style: TextStyle(color: textColor)),
                  subtitle: Text(
                    "Buton basımında ses efekti",
                    style: TextStyle(color: subTextColor, fontSize: 12),
                  ),
                  secondary: Icon(Icons.volume_up, color: accentColor),
                  value: _soundEnabled,
                  activeColor: accentColor,
                  onChanged: (value) {
                    setState(() {
                      _soundEnabled = value;
                    });
                    _saveSetting('sound', value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionTitle("Veri Yönetimi", textColor),
          Card(
            color: cardColor,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.orange),
                  title: Text(
                    "Geçmişi Temizle",
                    style: TextStyle(color: textColor),
                  ),
                  subtitle: Text(
                    "Tüm hesaplama geçmişini sil",
                    style: TextStyle(color: subTextColor, fontSize: 12),
                  ),
                  trailing: Icon(Icons.chevron_right, color: subTextColor),
                  onTap: _showClearHistoryDialog,
                ),
                Divider(height: 1, color: subTextColor.withOpacity(0.2)),
                ListTile(
                  leading: const Icon(Icons.bookmark, color: Colors.blue),
                  title: Text(
                    "Defteri Temizle",
                    style: TextStyle(color: textColor),
                  ),
                  subtitle: Text(
                    "Defterdeki tüm kayıtları sil",
                    style: TextStyle(color: subTextColor, fontSize: 12),
                  ),
                  trailing: Icon(Icons.chevron_right, color: subTextColor),
                  onTap: _showClearNotebookDialog,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionTitle("Hakkında", textColor),
          Card(
            color: cardColor,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline, color: accentColor),
                  title: Text(
                    "Uygulama Sürümü",
                    style: TextStyle(color: textColor),
                  ),
                  trailing: Text(
                    "1.0.0",
                    style: TextStyle(color: subTextColor),
                  ),
                ),
                Divider(height: 1, color: subTextColor.withOpacity(0.2)),
                ListTile(
                  leading: Icon(Icons.code, color: accentColor),
                  title: Text(
                    "Geliştirici",
                    style: TextStyle(color: textColor),
                  ),
                  trailing: Text(
                    "Süleyman Büdün",
                    style: TextStyle(color: subTextColor),
                  ),
                ),
                Divider(height: 1, color: subTextColor.withOpacity(0.2)),
                ListTile(
                  leading: Icon(Icons.business, color: accentColor),
                  title: Text("Yayıncı", style: TextStyle(color: textColor)),
                  trailing: Text(
                    "SuBuSoft",
                    style: TextStyle(color: subTextColor),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor.withOpacity(0.6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
