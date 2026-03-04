import 'package:flutter/material.dart';
import 'drawer_widget.dart';
import 'services/ads_service.dart';

class DefterSayfasi extends StatefulWidget {
  final List<String> notebookList;
  final Function(List<String>) onUpdate;
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const DefterSayfasi({
    super.key, 
    required this.notebookList, 
    required this.onUpdate,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<DefterSayfasi> createState() => _DefterSayfasiState();
}

class _DefterSayfasiState extends State<DefterSayfasi> {
  late List<String> currentList;

  @override
  void initState() {
    super.initState();
    currentList = List.from(widget.notebookList);
  }

  Future<void> _editNote(int index) async {
    TextEditingController noteController = TextEditingController();
    
    String currentItem = currentList[index];
    String operation = currentItem;
    if (currentItem.contains("#")) {
      var parts = currentItem.split("#");
      operation = parts[0].trim();
      noteController.text = parts[1].trim();
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        title: Text("Notu Düzenle", style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
        content: TextField(
          controller: noteController,
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: "Örn: Market, Kira...",
            hintStyle: TextStyle(color: widget.isDarkMode ? Colors.grey : Colors.grey.shade600),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.isDarkMode ? Colors.white38 : Colors.black38)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9500),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (noteController.text.isNotEmpty) {
                  currentList[index] = "$operation #${noteController.text}";
                } else {
                  currentList[index] = operation;
                }
              });
              widget.onUpdate(currentList); 
              Navigator.pop(context);
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  void _deleteItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        title: Text("Silinsin mi?", style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
        content: Text("Bu kayıt defterden silinecek.", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Vazgeç"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                currentList.removeAt(index);
              });
              widget.onUpdate(currentList);
              Navigator.pop(context);
            },
            child: const Text("Sil", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    Color cardColor = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    Color textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    Color appBarColor = widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFFF9500);
    Color subTextColor = widget.isDarkMode ? Colors.grey : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: AppDrawer(
        isDarkMode: widget.isDarkMode,
        currentPage: 'notebook',
      ),
      appBar: AppBar(
        title: const Text("Hesap Defterim"),
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
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              widget.onThemeChanged(!widget.isDarkMode);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const DoubleBannerAdWidget(),
            Expanded(
              child: currentList.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.book, size: 64, color: subTextColor.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text("Defterin boş.", style: TextStyle(color: subTextColor)),
                    const SizedBox(height: 4),
                    Text("Geçmişten işlem ekleyebilirsin.", style: TextStyle(color: subTextColor, fontSize: 12)),
                  ],
                ),
              )
            : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: currentList.length,
              itemBuilder: (context, index) {
                String item = currentList[index];
                String operation = item;
                String? note;

                if (item.contains("#")) {
                  var parts = item.split("#");
                  operation = parts[0].trim();
                  note = parts[1].trim();
                }

                return Card(
                  color: cardColor,
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFF9500),
                      child: Icon(Icons.bookmark, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      operation,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (note != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.isDarkMode ? Colors.amber.withOpacity(0.2) : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: widget.isDarkMode ? Colors.amber.withOpacity(0.3) : Colors.amber.shade100),
                            ),
                            child: Text(
                              note,
                              style: TextStyle(
                                color: widget.isDarkMode ? const Color(0xFFFFB74D) : Colors.amber[900], 
                                fontWeight: FontWeight.w600
                              ),
                            ),
                          ),
                        ] else 
                           Padding(
                             padding: const EdgeInsets.only(top: 4.0),
                             child: Text("Not yok", style: TextStyle(fontSize: 12, color: subTextColor)),
                           ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: subTextColor),
                          onPressed: () => _editNote(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteItem(index),
                        ),
                      ],
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
