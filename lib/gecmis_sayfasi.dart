import 'package:flutter/material.dart';
import 'drawer_widget.dart';
import 'services/ads_service.dart';

class GecmisSayfasi extends StatelessWidget {
  final List<String> historyList;
  final Function(String) onAddToNotebook;
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const GecmisSayfasi({
    super.key, 
    required this.historyList, 
    required this.onAddToNotebook,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    Color cardColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    Color textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    Color subTextColor = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    Color appBarColor = isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFFF9500);

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: AppDrawer(
        isDarkMode: isDarkMode,
        currentPage: 'history',
      ),
      appBar: AppBar(
        title: const Text("Geçmiş İşlemler"),
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
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              onThemeChanged(!isDarkMode);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const DoubleBannerAdWidget(),
            Expanded(
              child: historyList.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: subTextColor.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text("Henüz işlem yapılmadı.", style: TextStyle(color: subTextColor)),
                  ],
                ),
              )
            : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: historyList.length,
              itemBuilder: (context, index) {
                String item = historyList[index];
                String operation = item.split("#")[0].trim(); 

                return Card(
                  color: cardColor,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      operation,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColor),
                    ),
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? const Color(0xFF334155) : Colors.grey.shade300,
                        foregroundColor: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        onAddToNotebook(operation);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Deftere eklendi!"),
                            duration: const Duration(seconds: 1),
                            backgroundColor: isDarkMode ? const Color(0xFF334155) : null,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text("Deftere Ekle"),
                    ),
                  ),
                );
              },
            ),
            ),
          ],
        ),
      ),
    );
  }
}
