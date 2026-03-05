import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final bool isDarkMode;
  final String currentPage;
  final VoidCallback? onThemeToggle;

  const AppDrawer({
    super.key,
    required this.isDarkMode,
    required this.currentPage,
    this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor =
        isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    Color textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    Color subTextColor =
        isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Drawer(
      backgroundColor: bgColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF9500), Color(0xFFFF6B00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calculate,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Hesap Makinesi",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Çok Amaçlı Hesaplama Aracı",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.calculate,
            title: "Hesap Makinesi",
            subtitle: "Temel hesaplamalar",
            textColor: textColor,
            subTextColor: subTextColor,
            isSelected: currentPage == 'calculator',
            routeName: 'calculator',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.science,
            title: "Bilimsel Hesap Makinesi",
            subtitle: "Gelişmiş matematiksel işlemler",
            textColor: textColor,
            subTextColor: subTextColor,
            isSelected: currentPage == 'scientific',
            routeName: 'scientific',
          ),
          const Divider(),
          _buildDrawerItem(
            context: context,
            icon: Icons.currency_exchange,
            title: "Para Birimi Çevirici",
            subtitle: "Döviz kurları çevirme",
            textColor: textColor,
            subTextColor: subTextColor,
            isSelected: currentPage == 'currency',
            routeName: 'currency',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.straighten,
            title: "Birim Çevirici",
            subtitle: "Uzunluk, ağırlık, sıcaklık...",
            textColor: textColor,
            subTextColor: subTextColor,
            isSelected: currentPage == 'unit',
            routeName: 'unit',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.diamond,
            title: "Altın & Gümüş Fiyatları",
            subtitle: "Canlı kıymetli maden fiyatları",
            textColor: textColor,
            subTextColor: subTextColor,
            isSelected: currentPage == 'gold',
            routeName: 'gold',
          ),
          const Divider(),
          _buildDrawerItem(
            context: context,
            icon: Icons.history,
            title: "Geçmiş",
            subtitle: "Son hesaplamalar",
            textColor: textColor,
            subTextColor: subTextColor,
            isSelected: currentPage == 'history',
            routeName: 'history',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.bookmark,
            title: "Defterim",
            subtitle: "Kaydedilen işlemler",
            textColor: textColor,
            subTextColor: subTextColor,
            isSelected: currentPage == 'notebook',
            routeName: 'notebook',
          ),
          const Divider(),
          _buildDrawerItem(
            context: context,
            icon: Icons.settings,
            title: "Ayarlar",
            subtitle: "Uygulama tercihleri",
            textColor: textColor,
            subTextColor: subTextColor,
            isSelected: currentPage == 'settings',
            routeName: 'settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subTextColor,
    required bool isSelected,
    required String routeName,
  }) {
    return Container(
      color: isSelected
          ? (isDarkMode ? const Color(0xFF334155) : const Color(0xFFFFE4C4))
          : Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? const Color(0xFFFF9500)
              : const Color(0xFFFF9500).withOpacity(0.7),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: subTextColor, fontSize: 12),
        ),
        onTap: () {
          Navigator.pop(context); // Drawer'ı kapat

          if (!isSelected) {
            // Mevcut sayfadan çık ve yeni sayfaya git
            if (currentPage != 'calculator') {
              Navigator.pop(context); // Mevcut sayfadan çık
            }

            // Hedef sayfaya git
            if (routeName != 'calculator') {
              Navigator.pushNamed(context, '/$routeName');
            }
          }
        },
      ),
    );
  }
}
