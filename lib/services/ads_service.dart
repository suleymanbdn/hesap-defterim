import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  // Gerçek AdMob ID'nizi buraya girin
  // Test ID'leri şu an aktif - yayına almadan önce gerçek ID ile değiştirin
  static const String _bannerAdUnitId =
      'ca-app-pub-7029430440483366/3213838031';

  static String get bannerAdUnitId => _bannerAdUnitId;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }
}

/// Her 3 sayfa geçişinde bir kez gösterilen interstitial reklam servisi.
class InterstitialAdService {
  static final InterstitialAdService _instance =
      InterstitialAdService._internal();
  factory InterstitialAdService() => _instance;
  InterstitialAdService._internal();

  // ✅ Gerçek AdMob Interstitial ID
  static const String _adUnitId = 'ca-app-pub-7029430440483366/6957017200';

  InterstitialAd? _interstitialAd;
  int _navigationCount = 0;
  static const int _showEveryN = 3; // Her 3 geçişte bir göster

  /// Uygulama başlangıcında çağırın
  Future<void> loadAd() async {
    await InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Drawer navigasyonunda çağırın
  Future<void> onNavigate() async {
    _navigationCount++;
    if (_navigationCount % _showEveryN == 0 && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          loadAd(); // Bir sonraki için yükle
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          loadAd();
        },
      );
      await _interstitialAd!.show();
    }
  }
}

// Tam genişlik adaptif banner widget'ı
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

// Geriye dönük uyumluluk için alias
class DoubleBannerAdWidget extends StatelessWidget {
  const DoubleBannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const BannerAdWidget();
  }
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    // İlk frame'den sonra yükle (MediaQuery hazır olsun)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAd();
    });
  }

  Future<void> _loadAd() async {
    if (!mounted) return;
    final width = MediaQuery.of(context).size.width.truncate();
    // Adaptif boyut null dönerse standart banner boyutuna geri dön
    final adSize =
        (await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
          width,
        )) ??
        AdSize.banner;

    if (!mounted) return;

    _bannerAd = BannerAd(
      adUnitId: AdsService.bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox(height: 50);
    }
    return SizedBox(
      width: double.infinity,
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
