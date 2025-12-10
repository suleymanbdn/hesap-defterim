import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'drawer_widget.dart';

class ParaBirimiCevirme extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const ParaBirimiCevirme({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<ParaBirimiCevirme> createState() => _ParaBirimiCevirmeState();
}

class _ParaBirimiCevirmeState extends State<ParaBirimiCevirme> {
  final TextEditingController _amountController = TextEditingController();
  String _fromCurrency = 'TRY';
  String _toCurrency = 'USD';
  double _result = 0;
  bool _isLoading = true;
  String? _errorMessage;
  String _lastUpdate = '';

  Map<String, double> _exchangeRates = {};

  final Map<String, String> _currencyNames = {
    'TRY': '🇹🇷 Türk Lirası',
    'USD': '🇺🇸 Amerikan Doları',
    'EUR': '🇪🇺 Euro',
    'GBP': '🇬🇧 İngiliz Sterlini',
    'JPY': '🇯🇵 Japon Yeni',
    'CHF': '🇨🇭 İsviçre Frangı',
    'CAD': '🇨🇦 Kanada Doları',
    'AUD': '🇦🇺 Avustralya Doları',
    'CNY': '🇨🇳 Çin Yuanı',
    'RUB': '🇷🇺 Rus Rublesi',
    'SAR': '🇸🇦 Suudi Riyali',
    'AED': '🇦🇪 BAE Dirhemi',
    'KWD': '🇰🇼 Kuveyt Dinarı',
    'QAR': '🇶🇦 Katar Riyali',
    'INR': '🇮🇳 Hindistan Rupisi',
    'KRW': '🇰🇷 Güney Kore Wonu',
    'BRL': '🇧🇷 Brezilya Reali',
    'MXN': '🇲🇽 Meksika Pesosu',
    'SEK': '🇸🇪 İsveç Kronu',
    'NOK': '🇳🇴 Norveç Kronu',
    'DKK': '🇩🇰 Danimarka Kronu',
    'PLN': '🇵🇱 Polonya Zlotisi',
    'ZAR': '🇿🇦 Güney Afrika Randı',
    'SGD': '🇸🇬 Singapur Doları',
    'HKD': '🇭🇰 Hong Kong Doları',
    'NZD': '🇳🇿 Yeni Zelanda Doları',
  };

  final Map<String, String> _currencySymbols = {
    'TRY': '₺',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CHF': 'Fr',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'CNY': '¥',
    'RUB': '₽',
    'SAR': '﷼',
    'AED': 'د.إ',
    'KWD': 'د.ك',
    'QAR': '﷼',
    'INR': '₹',
    'KRW': '₩',
    'BRL': 'R\$',
    'MXN': '\$',
    'SEK': 'kr',
    'NOK': 'kr',
    'DKK': 'kr',
    'PLN': 'zł',
    'ZAR': 'R',
    'SGD': 'S\$',
    'HKD': 'HK\$',
    'NZD': 'NZ\$',
  };

  @override
  void initState() {
    super.initState();
    _fetchExchangeRates();
  }

  Future<void> _fetchExchangeRates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/TRY'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['result'] == 'success') {
          final rates = data['rates'] as Map<String, dynamic>;

          setState(() {
            _exchangeRates = {'TRY': 1.0};

            for (String currency in _currencyNames.keys) {
              if (rates.containsKey(currency)) {
                _exchangeRates[currency] = (rates[currency] as num).toDouble();
              }
            }

            _lastUpdate = data['time_last_update_utc'] ?? '';
            if (_lastUpdate.isNotEmpty) {
              try {
                final parts = _lastUpdate.split(' ');
                if (parts.length >= 4) {
                  _lastUpdate = '${parts[1]} ${parts[2]} ${parts[3]}';
                }
              } catch (_) {}
            }

            _isLoading = false;
          });

          _convert();
        } else {
          throw Exception('API yanıtı başarısız');
        }
      } else {
        throw Exception('HTTP Hata: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Kurlar yüklenemedi. İnternet bağlantınızı kontrol edin.';

        _exchangeRates = {
          'TRY': 1.0,
          'USD': 0.029,
          'EUR': 0.027,
          'GBP': 0.023,
          'JPY': 4.35,
          'CHF': 0.026,
          'CAD': 0.040,
          'AUD': 0.045,
          'CNY': 0.21,
          'RUB': 2.90,
          'SAR': 0.11,
          'AED': 0.11,
          'KWD': 0.0089,
          'QAR': 0.11,
          'INR': 2.42,
        };
        _lastUpdate = 'Çevrimdışı mod (yaklaşık değerler)';
      });
    }
  }

  void _convert() {
    if (_exchangeRates.isEmpty) return;

    double amount = double.tryParse(_amountController.text) ?? 0;

    double fromRate = _exchangeRates[_fromCurrency] ?? 1.0;
    double toRate = _exchangeRates[_toCurrency] ?? 1.0;

    double inTRY = amount / fromRate;
    double converted = inTRY * toRate;

    setState(() {
      _result = converted;
    });
  }

  void _swapCurrencies() {
    setState(() {
      String temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      _convert();
    });
  }

  String _getExchangeRateText() {
    if (_exchangeRates.isEmpty) return '';

    double fromRate = _exchangeRates[_fromCurrency] ?? 1.0;
    double toRate = _exchangeRates[_toCurrency] ?? 1.0;
    double rate = toRate / fromRate;

    return '1 $_fromCurrency = ${rate.toStringAsFixed(4)} $_toCurrency';
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
    Color appBarColor = widget.isDarkMode
        ? const Color(0xFF0F172A)
        : const Color(0xFFFF9500);
    Color accentColor = const Color(0xFFFF9500);
    Color subTextColor = widget.isDarkMode
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      drawer: AppDrawer(isDarkMode: widget.isDarkMode, currentPage: 'currency'),
      appBar: AppBar(
        title: const Text("Para Birimi Çevirici"),
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
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchExchangeRates,
            tooltip: 'Kurları Güncelle',
          ),
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              widget.onThemeChanged(!widget.isDarkMode);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: accentColor),
                    const SizedBox(height: 16),
                    Text(
                      "Güncel kurlar yükleniyor...",
                      style: TextStyle(color: subTextColor),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.orange,
                              size: 20,
                            ),
                            onPressed: _fetchExchangeRates,
                          ),
                        ],
                      ),
                    ),

                  if (_lastUpdate.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.update, size: 14, color: subTextColor),
                          const SizedBox(width: 6),
                          Text(
                            _lastUpdate,
                            style: TextStyle(fontSize: 12, color: subTextColor),
                          ),
                        ],
                      ),
                    ),

                  Card(
                    color: cardColor,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tutar",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            decoration: InputDecoration(
                              hintText: "0.00",
                              hintStyle: TextStyle(
                                color: textColor.withOpacity(0.3),
                              ),
                              border: InputBorder.none,
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(
                                  left: 12,
                                  right: 8,
                                ),
                                child: Text(
                                  _currencySymbols[_fromCurrency] ??
                                      _fromCurrency,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 0,
                                minHeight: 0,
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildCurrencySelector(
                            label: "Kaynak",
                            value: _fromCurrency,
                            onChanged: (val) {
                              setState(() {
                                _fromCurrency = val!;
                                _convert();
                              });
                            },
                            textColor: textColor,
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: textColor.withOpacity(0.2),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _swapCurrencies,
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
                                    Expanded(
                                      child: Divider(
                                        color: textColor.withOpacity(0.2),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getExchangeRateText(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: accentColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          _buildCurrencySelector(
                            label: "Hedef",
                            value: _toCurrency,
                            onChanged: (val) {
                              setState(() {
                                _toCurrency = val!;
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                              "${_result.toStringAsFixed(4)} $_toCurrency",
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currencyNames[_toCurrency] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode
                          ? Colors.green.withOpacity(0.1)
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.isDarkMode
                            ? Colors.green.withOpacity(0.3)
                            : Colors.green.shade100,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_done,
                          color: widget.isDarkMode
                              ? Colors.green.shade300
                              : Colors.green.shade700,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Kurlar günlük olarak güncellenen canlı verilerden alınmaktadır.",
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.isDarkMode
                                  ? Colors.green.shade300
                                  : Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildCurrencySelector({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
    required Color textColor,
  }) {
    List<String> availableCurrencies = _exchangeRates.keys
        .where((currency) => _currencyNames.containsKey(currency))
        .toList();

    if (!availableCurrencies.contains(value)) {
      availableCurrencies.insert(0, value);
    }

    return Row(
      children: [
        SizedBox(
          width: 55,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? const Color(0xFF334155)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: widget.isDarkMode
                  ? const Color(0xFF1E293B)
                  : Colors.white,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              items: availableCurrencies.map((currency) {
                return DropdownMenuItem(
                  value: currency,
                  child: Text(_currencyNames[currency] ?? currency),
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
    _amountController.dispose();
    super.dispose();
  }
}
