import 'package:flutter/material.dart';
import 'drawer_widget.dart';

class BirimCevirme extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  
  const BirimCevirme({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<BirimCevirme> createState() => _BirimCevirmeState();
}

class _BirimCevirmeState extends State<BirimCevirme> {
  final TextEditingController _valueController = TextEditingController();
  String _selectedCategory = 'Uzunluk';
  String _fromUnit = 'Metre';
  String _toUnit = 'Kilometre';
  double _result = 0;

  final Map<String, Map<String, double>> _conversionRates = {
    'Uzunluk': {
      'Metre': 1.0,
      'Kilometre': 0.001,
      'Santimetre': 100.0,
      'Milimetre': 1000.0,
      'İnç': 39.3701,
      'Fit': 3.28084,
      'Yard': 1.09361,
      'Mil': 0.000621371,
    },
    'Ağırlık': {
      'Kilogram': 1.0,
      'Gram': 1000.0,
      'Miligram': 1000000.0,
      'Ton': 0.001,
      'Pound': 2.20462,
      'Ons': 35.274,
    },
    'Sıcaklık': {
      'Celsius': 1.0,
      'Fahrenheit': 1.0,
      'Kelvin': 1.0,
    },
    'Alan': {
      'Metrekare': 1.0,
      'Kilometrekare': 0.000001,
      'Hektar': 0.0001,
      'Dönüm': 0.001,
      'Fit kare': 10.7639,
      'Acre': 0.000247105,
    },
    'Hacim': {
      'Litre': 1.0,
      'Mililitre': 1000.0,
      'Metreküp': 0.001,
      'Galon': 0.264172,
      'Pint': 2.11338,
    },
    'Hız': {
      'Metre/saniye': 1.0,
      'Kilometre/saat': 3.6,
      'Mil/saat': 2.23694,
      'Knot': 1.94384,
    },
    'Zaman': {
      'Saniye': 1.0,
      'Dakika': 0.0166667,
      'Saat': 0.000277778,
      'Gün': 0.0000115741,
      'Hafta': 0.00000165344,
      'Ay': 0.000000380517,
      'Yıl': 0.0000000317098,
    },
    'Veri': {
      'Byte': 1.0,
      'Kilobyte': 0.001,
      'Megabyte': 0.000001,
      'Gigabyte': 0.000000001,
      'Terabyte': 0.000000000001,
      'Bit': 8.0,
    },
  };

  final Map<String, IconData> _categoryIcons = {
    'Uzunluk': Icons.straighten,
    'Ağırlık': Icons.fitness_center,
    'Sıcaklık': Icons.thermostat,
    'Alan': Icons.square_foot,
    'Hacim': Icons.local_drink,
    'Hız': Icons.speed,
    'Zaman': Icons.access_time,
    'Veri': Icons.storage,
  };

  void _convert() {
    double value = double.tryParse(_valueController.text) ?? 0;
    
    if (_selectedCategory == 'Sıcaklık') {
      _result = _convertTemperature(value, _fromUnit, _toUnit);
    } else {
      double toBase = value / _conversionRates[_selectedCategory]![_fromUnit]!;
      _result = toBase * _conversionRates[_selectedCategory]![_toUnit]!;
    }
    
    setState(() {});
  }

  double _convertTemperature(double value, String from, String to) {
    double celsius;
    
    switch (from) {
      case 'Celsius':
        celsius = value;
        break;
      case 'Fahrenheit':
        celsius = (value - 32) * 5 / 9;
        break;
      case 'Kelvin':
        celsius = value - 273.15;
        break;
      default:
        celsius = value;
    }
    
    switch (to) {
      case 'Celsius':
        return celsius;
      case 'Fahrenheit':
        return celsius * 9 / 5 + 32;
      case 'Kelvin':
        return celsius + 273.15;
      default:
        return celsius;
    }
  }

  void _swapUnits() {
    setState(() {
      String temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
      _convert();
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      List<String> units = _conversionRates[category]!.keys.toList();
      _fromUnit = units[0];
      _toUnit = units.length > 1 ? units[1] : units[0];
      _convert();
    });
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    Color cardColor = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    Color textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    Color appBarColor = widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFFF9500);
    Color accentColor = const Color(0xFFFF9500);

    List<String> currentUnits = _conversionRates[_selectedCategory]!.keys.toList();

    return Scaffold(
      backgroundColor: bgColor,
      drawer: AppDrawer(
        isDarkMode: widget.isDarkMode,
        currentPage: 'unit',
      ),
      appBar: AppBar(
        title: const Text("Birim Çevirici"),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _conversionRates.keys.length,
                itemBuilder: (context, index) {
                  String category = _conversionRates.keys.elementAt(index);
                  bool isSelected = category == _selectedCategory;
                  
                  return GestureDetector(
                    onTap: () => _onCategoryChanged(category),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? accentColor : cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _categoryIcons[category],
                            color: isSelected ? Colors.white : textColor.withOpacity(0.7),
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : textColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            Card(
              color: cardColor,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Değer",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _valueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: "0",
                        hintStyle: TextStyle(color: textColor.withOpacity(0.3)),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          _categoryIcons[_selectedCategory],
                          color: accentColor,
                          size: 28,
                        ),
                      ),
                      onChanged: (_) => _convert(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Card(
              color: cardColor,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildUnitSelector(
                      label: "Kaynak",
                      value: _fromUnit,
                      units: currentUnits,
                      onChanged: (val) {
                        setState(() {
                          _fromUnit = val!;
                          _convert();
                        });
                      },
                      textColor: textColor,
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: textColor.withOpacity(0.2))),
                          IconButton(
                            onPressed: _swapUnits,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.swap_vert,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: textColor.withOpacity(0.2))),
                        ],
                      ),
                    ),
                    
                    _buildUnitSelector(
                      label: "Hedef",
                      value: _toUnit,
                      units: currentUnits,
                      onChanged: (val) {
                        setState(() {
                          _toUnit = val!;
                          _convert();
                        });
                      },
                      textColor: textColor,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Card(
              color: accentColor,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      "Sonuç",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatResult(_result),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _toUnit,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatResult(double value) {
    if (value == 0) return "0";
    if (value.abs() >= 1000000 || value.abs() < 0.0001) {
      return value.toStringAsExponential(4);
    }
    String str = value.toStringAsFixed(6);
    str = str.replaceAll(RegExp(r'([.]*0+)$'), '');
    return str;
  }

  Widget _buildUnitSelector({
    required String label,
    required String value,
    required List<String> units,
    required ValueChanged<String?> onChanged,
    required Color textColor,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: textColor.withOpacity(0.7),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              items: units.map((unit) {
                return DropdownMenuItem(
                  value: unit,
                  child: Text(unit),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }
}
