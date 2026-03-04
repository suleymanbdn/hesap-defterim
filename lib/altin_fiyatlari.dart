import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'drawer_widget.dart';
import 'services/ads_service.dart';

class AltinFiyatlari extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const AltinFiyatlari({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<AltinFiyatlari> createState() => _AltinFiyatlariState();
}

class _AltinFiyatlariState extends State<AltinFiyatlari> {
  bool _isLoading = true;
  String? _error;
  DateTime? _lastUpdate;

  // Fiyat verileri
  Map<String, double> _prices = {};
  Map<String, double> _previousPrices = {};

  // Altın ayarları için çarpanlar (saf altına göre)
  final Map<String, double> _goldPurityMultipliers = {
    'Gram Altın (24 Ayar)': 1.0,
    '22 Ayar Altın': 0.916,
    '18 Ayar Altın': 0.750,
    '14 Ayar Altın': 0.585,
  };

  // Cumhuriyet altınları gramaj (yaklaşık saf altın içeriği)
  final Map<String, double> _republicGoldGrams = {
    'Çeyrek Altın': 1.75 * 0.916,
    'Yarım Altın': 3.5 * 0.916,
    'Tam Altın': 7.0 * 0.916,
    'Ata Altın': 7.2 * 0.916,
  };

  @override
  void initState() {
    super.initState();
    _fetchPrices();
  }

  Future<void> _fetchPrices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Strateji 1: Yahoo Finance - doğrudan TRY cinsinden
      await _fetchYahooFinance();
    } catch (e) {
      try {
        // Strateji 2: metals.live (USD) + open.er-api (USD/TRY)
        await _fetchMetalsWithFx();
      } catch (e2) {
        try {
          // Strateji 3: goldprice.org
          await _fetchGoldPriceOrg();
        } catch (e3) {
          _useDemoData();
        }
      }
    }
  }

  Future<void> _fetchYahooFinance() async {
    // GC=F: Altın vadeli (USD/oz), SI=F: Gümüş (USD/oz), USDTRY=X: USD/TRY kuru
    final results = await Future.wait([
      http.get(
        Uri.parse(
            'https://query1.finance.yahoo.com/v8/finance/chart/GC%3DF?interval=1m&range=1d'),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 12)),
      http.get(
        Uri.parse(
            'https://query1.finance.yahoo.com/v8/finance/chart/USDTRY%3DX?interval=1m&range=1d'),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 12)),
      http.get(
        Uri.parse(
            'https://query1.finance.yahoo.com/v8/finance/chart/SI%3DF?interval=1m&range=1d'),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 12)),
    ]);

    if (results[0].statusCode != 200 || results[1].statusCode != 200) {
      throw Exception('Yahoo Finance hatası');
    }

    final goldData = json.decode(results[0].body);
    final fxData = json.decode(results[1].body);

    final double goldUsd =
        (goldData['chart']['result'][0]['meta']['regularMarketPrice'] as num)
            .toDouble();
    final double usdTry =
        (fxData['chart']['result'][0]['meta']['regularMarketPrice'] as num)
            .toDouble();

    double silverGramTry;
    try {
      final silverData = json.decode(results[2].body);
      final double silverUsd = (silverData['chart']['result'][0]['meta']
              ['regularMarketPrice'] as num)
          .toDouble();
      silverGramTry = silverUsd * usdTry / 31.1035;
    } catch (_) {
      silverGramTry = goldUsd * usdTry / 31.1035 / 85;
    }

    setState(() {
      _previousPrices = Map.from(_prices);
      _prices = {
        'gram_altin': goldUsd * usdTry / 31.1035,
        'gram_gumus': silverGramTry,
      };
      _lastUpdate = DateTime.now();
      _isLoading = false;
    });
  }

  Future<void> _fetchMetalsWithFx() async {
    final results = await Future.wait([
      http
          .get(Uri.parse('https://api.metals.live/v1/spot'))
          .timeout(const Duration(seconds: 10)),
      http
          .get(Uri.parse('https://open.er-api.com/v6/latest/USD'))
          .timeout(const Duration(seconds: 10)),
    ]);

    if (results[0].statusCode != 200 || results[1].statusCode != 200) {
      throw Exception('API yanıt vermedi');
    }

    final List metalData = json.decode(results[0].body);
    final Map fxData = json.decode(results[1].body);
    final double usdTry = (fxData['rates']['TRY'] as num).toDouble();

    double? xauUsd, xagUsd;
    for (final item in metalData) {
      final symbol =
          (item['symbol'] ?? item['metal'] ?? '').toString().toLowerCase();
      final price = (item['price'] ?? item['ask'] ?? 0).toDouble();
      if (symbol.contains('xau') || symbol.contains('gold')) xauUsd = price;
      if (symbol.contains('xag') || symbol.contains('silver')) xagUsd = price;
    }

    if (xauUsd == null || xauUsd == 0)
      throw Exception('Altın fiyatı alınamadı');

    setState(() {
      _previousPrices = Map.from(_prices);
      _prices = {
        'gram_altin': xauUsd! * usdTry / 31.1035,
        'gram_gumus': (xagUsd != null && xagUsd > 0)
            ? xagUsd * usdTry / 31.1035
            : xauUsd * usdTry / 31.1035 / 90,
      };
      _lastUpdate = DateTime.now();
      _isLoading = false;
    });
  }

  Future<void> _fetchGoldPriceOrg() async {
    final response = await http
        .get(Uri.parse('https://data-asg.goldprice.org/dbXRates/TRY'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) throw Exception('goldprice.org başarısız');

    final data = json.decode(response.body);
    if (data['items'] == null || data['items'].isEmpty) {
      throw Exception('Veri yok');
    }

    double xauPrice = (data['items'][0]['xauPrice'] as num).toDouble();
    double xagPrice = (data['items'][0]['xagPrice'] as num).toDouble();

    setState(() {
      _previousPrices = Map.from(_prices);
      _prices = {
        'gram_altin': xauPrice / 31.1035,
        'gram_gumus': xagPrice / 31.1035,
      };
      _lastUpdate = DateTime.now();
      _isLoading = false;
    });
  }

  void _useDemoData() {
    // Mart 2026 tahmini (USD/TRY ~44, XAU ~$3000/oz)
    setState(() {
      _previousPrices = Map.from(_prices);
      _prices = {
        'gram_altin': 4250.0, // ~$3000 * 44 / 31.1
        'gram_gumus': 48.0, // ~$34 * 44 / 31.1
      };
      _lastUpdate = DateTime.now();
      _isLoading = false;
      _error =
          'Tahmini fiyatlar gösteriliyor. İnternet bağlantınızı kontrol edin.';
    });
  }

  double _getGoldPrice(String type) {
    double basePrice = _prices['gram_altin'] ?? 0;

    if (_goldPurityMultipliers.containsKey(type)) {
      return basePrice * _goldPurityMultipliers[type]!;
    }

    if (_republicGoldGrams.containsKey(type)) {
      return basePrice * _republicGoldGrams[type]!;
    }

    return basePrice;
  }

  double _getPriceChange(String key) {
    if (!_previousPrices.containsKey(key) || _previousPrices[key] == 0) {
      return 0;
    }
    double current = _prices[key] ?? 0;
    double previous = _previousPrices[key] ?? 0;
    return ((current - previous) / previous) * 100;
  }

  String _formatPrice(double price) {
    return '₺${price.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor =
        widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    Color textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    Color subTextColor =
        widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    Color appBarColor =
        widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFFF9500);

    return Scaffold(
      backgroundColor: bgColor,
      drawer: AppDrawer(isDarkMode: widget.isDarkMode, currentPage: 'gold'),
      appBar: AppBar(
        title: const Text(
          "Altın & Gümüş Fiyatları",
          style: TextStyle(fontSize: 18),
        ),
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
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchPrices,
            tooltip: 'Yenile',
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
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFFFFD700)),
                          SizedBox(height: 16),
                          Text('Fiyatlar yükleniyor...'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchPrices,
                      color: const Color(0xFFFFD700),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hata mesajı
                            if (_error != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Son güncelleme
                            if (_lastUpdate != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: subTextColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Son güncelleme: ${_lastUpdate!.hour.toString().padLeft(2, '0')}:${_lastUpdate!.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // ALTIN FİYATLARI
                            _buildSectionTitle(
                              'Altın Fiyatları',
                              Icons.diamond,
                              const Color(0xFFFFD700),
                              textColor,
                            ),
                            const SizedBox(height: 12),

                            // Gram Altın Kartları
                            ..._goldPurityMultipliers.keys.map(
                              (type) => _buildPriceCard(
                                title: type,
                                price: _getGoldPrice(type),
                                isGold: true,
                                textColor: textColor,
                                subTextColor: subTextColor,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Cumhuriyet Altınları
                            _buildSectionTitle(
                              'Cumhuriyet Altınları',
                              Icons.monetization_on,
                              const Color(0xFFFFD700),
                              textColor,
                            ),
                            const SizedBox(height: 12),

                            ..._republicGoldGrams.keys.map(
                              (type) => _buildPriceCard(
                                title: type,
                                price: _getGoldPrice(type),
                                isGold: true,
                                textColor: textColor,
                                subTextColor: subTextColor,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // GÜMÜŞ FİYATLARI
                            _buildSectionTitle(
                              'Gümüş Fiyatları',
                              Icons.circle,
                              const Color(0xFFC0C0C0),
                              textColor,
                            ),
                            const SizedBox(height: 12),

                            _buildPriceCard(
                              title: 'Gram Gümüş',
                              price: _prices['gram_gumus'] ?? 0,
                              isGold: false,
                              textColor: textColor,
                              subTextColor: subTextColor,
                            ),

                            const SizedBox(height: 24),

                            // Bilgi notu
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: widget.isDarkMode
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: subTextColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Fiyatlar anlık piyasa verilerine göre değişiklik gösterebilir. Kesin fiyatlar için kuyumcunuza danışın.',
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 11,
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
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
    Color iconColor,
    Color textColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceCard({
    required String title,
    required double price,
    required bool isGold,
    required Color textColor,
    required Color subTextColor,
  }) {
    double change = _getPriceChange(isGold ? 'gram_altin' : 'gram_gumus');
    bool isPositive = change >= 0;

    // Gradient renkleri
    List<Color> gradientColors = isGold
        ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
        : [const Color(0xFFC0C0C0), const Color(0xFF808080)];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradientColors[0].withOpacity(widget.isDarkMode ? 0.2 : 0.15),
            gradientColors[1].withOpacity(widget.isDarkMode ? 0.1 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gradientColors[0].withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isGold ? Icons.diamond : Icons.circle,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatPrice(price),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (change != 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isPositive ? Colors.green : Colors.red,
                    size: 12,
                  ),
                  Text(
                    '${change.abs().toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
