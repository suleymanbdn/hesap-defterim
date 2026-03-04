import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'dart:math' as math;
import 'drawer_widget.dart';
import 'services/ads_service.dart';

class BilimselHesapMakinesi extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const BilimselHesapMakinesi({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<BilimselHesapMakinesi> createState() => _BilimselHesapMakinesiState();
}

class _BilimselHesapMakinesiState extends State<BilimselHesapMakinesi> {
  String _expression = "0";
  String _history = "";
  String _previousAnswer = "";
  bool _isDegree = false;
  bool _isInv = false;

  String _formatNumberDisplay(String value) {
    if (value == "Hata" || value == "0") return value;

    final regex = RegExp(r'^(-?)(\d+)(\.(\d*))?$');
    final match = regex.firstMatch(value);
    if (match == null) return value;

    final sign = match.group(1) ?? '';
    final intPart = match.group(2) ?? '';
    final hasDot = match.group(3) != null;
    final decPart = match.group(4) ?? '';

    // Binlik nokta ekle
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(intPart[i]);
    }

    String result = '$sign${buffer.toString()}';
    if (hasDot) {
      result += decPart.isEmpty ? ',' : ',$decPart';
    }

    return result;
  }

  String get _displayExpression {
    final isPureNumber = RegExp(r'^-?\d+\.?\d*$').hasMatch(_expression);
    if (isPureNumber) return _formatNumberDisplay(_expression);
    return _expression;
  }

  String get _displayHistory {
    if (_history.isEmpty) return _history;
    return _history.replaceAllMapped(
      RegExp(r'\d+\.?\d*'),
      (match) => _formatNumberDisplay(match.group(0)!),
    );
  }

  void _onButtonPressed(String text) {
    setState(() {
      if (_expression == "0" || _expression == "Hata") _expression = "";

      switch (text) {
        case 'AC':
          _expression = "0";
          _history = "";
          break;
        case 'C':
          if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
          }
          if (_expression.isEmpty) {
            _expression = "0";
          }
          break;

        case 'Rad':
          _isDegree = false;
          break;
        case 'Deg':
          _isDegree = true;
          break;
        case 'Inv':
          _isInv = !_isInv;
          break;

        case 'Ans':
          if (_previousAnswer.isNotEmpty) {
            _expression += _previousAnswer;
          }
          break;
        case 'EXP':
          _expression += "E";
          break;
        case 'x!':
          try {
            // Mevcut ifadeyi sayıya çevir ve faktöriyeli hesapla
            String currentExpr = _expression;
            if (currentExpr.isNotEmpty &&
                RegExp(r'^\d+$').hasMatch(currentExpr)) {
              int n = int.parse(currentExpr);
              if (n >= 0 && n <= 20) {
                int result = 1;
                for (int i = 2; i <= n; i++) {
                  result *= i;
                }
                _expression = result.toString();
              } else {
                _expression = "Hata";
              }
            }
          } catch (e) {
            _expression = "Hata";
          }
          break;

        case 'sin':
        case 'sin⁻¹':
          _expression += _isInv ? "asin(" : "sin(";
          break;
        case 'cos':
        case 'cos⁻¹':
          _expression += _isInv ? "acos(" : "cos(";
          break;
        case 'tan':
        case 'tan⁻¹':
          _expression += _isInv ? "atan(" : "tan(";
          break;
        case 'ln':
        case 'eˣ':
          _expression += _isInv ? "e^" : "ln(";
          break;
        case 'log':
        case '10ˣ':
          _expression += _isInv ? "10^" : "log(";
          break;
        case '√':
        case 'x²':
          _expression += _isInv ? "^2" : "sqrt(";
          break;

        case '=':
          try {
            _history = _expression;
            String finalExpression = _expression;

            finalExpression = finalExpression.replaceAll('×', '*');
            finalExpression = finalExpression.replaceAll('÷', '/');
            finalExpression = finalExpression.replaceAll('π', '${math.pi}');

            // EXP tuşu için E harfini bilimsel notasyona çevir (örn: 5E3 -> 5*10^3)
            finalExpression = finalExpression.replaceAllMapped(
              RegExp(r'(\d+)E(\d+)'),
              (match) => '(${match.group(1)}*10^${match.group(2)})',
            );

            // Euler sabiti 'e' - sadece tek başına veya operatörlerden sonra gelen 'e' harflerini değiştir
            finalExpression = finalExpression.replaceAllMapped(
              RegExp(r'(?<![a-zA-Z])e(?![a-zA-Z])'),
              (match) => '${math.e}',
            );

            // log(x) ifadesini ln(x)/ln(10) formülüne çevir (log base 10)
            finalExpression = finalExpression.replaceAllMapped(
              RegExp(r'log\(([^)]+)\)'),
              (match) => '(ln(${match.group(1)})/ln(10))',
            );

            finalExpression = finalExpression.replaceAll('asin', 'arcsin');
            finalExpression = finalExpression.replaceAll('acos', 'arccos');
            finalExpression = finalExpression.replaceAll('atan', 'arctan');

            if (_isDegree) {
              finalExpression = finalExpression.replaceAllMapped(
                RegExp(r'(sin|cos|tan|arcsin|arccos|arctan)\(([^)]+)\)'),
                (match) {
                  String func = match.group(1)!;
                  String val = match.group(2)!;
                  if (func.startsWith('arc')) {
                    return '($func($val) * 180 / ${math.pi})';
                  }
                  return '$func(($val) * ${math.pi / 180})';
                },
              );
            }

            Parser p = Parser();
            Expression exp = p.parse(finalExpression);
            ContextModel cm = ContextModel();
            double eval = exp.evaluate(EvaluationType.REAL, cm);

            String resultStr;
            if (eval % 1 == 0) {
              resultStr = eval.toInt().toString();
            } else {
              resultStr = eval
                  .toStringAsFixed(8)
                  .replaceAll(RegExp(r'([.]*0)+$'), '');
            }

            _expression = resultStr;
            _previousAnswer = resultStr;
          } catch (e) {
            _expression = "Hata";
          }
          break;
        case ',':
          if (!_expression.contains('.')) {
            _expression += '.';
          }
          break;
        default:
          _expression += text;
      }
    });
  }

  Widget buildButton(
    String text, {
    Color? color,
    Color? textColor,
    int flex = 1,
  }) {
    String displayText = text;
    if (_isInv) {
      switch (text) {
        case 'sin':
          displayText = 'sin⁻¹';
          break;
        case 'cos':
          displayText = 'cos⁻¹';
          break;
        case 'tan':
          displayText = 'tan⁻¹';
          break;
        case 'ln':
          displayText = 'eˣ';
          break;
        case 'log':
          displayText = '10ˣ';
          break;
        case '√':
          displayText = 'x²';
          break;
      }
    }

    // Uyumlu Renk Paleti
    const Color primaryOrange = Color(0xFFFF9500);
    const Color deepAmber = Color(0xFFE67E22);
    const Color tealAccent = Color(0xFF0891B2);

    Color buttonColor = widget.isDarkMode
        ? const Color(0xFF1F2937)
        : const Color(0xFFF3F4F6);
    Color buttonTextColor = widget.isDarkMode
        ? Colors.white
        : const Color(0xFF1F2937);

    bool isActiveMode = false;
    if ((text == 'Rad' && !_isDegree) ||
        (text == 'Deg' && _isDegree) ||
        (text == 'Inv' && _isInv)) {
      isActiveMode = true;
    }

    if (isActiveMode) {
      // Aktif mod - Teal (turuncu ile uyumlu)
      buttonColor = tealAccent;
      buttonTextColor = Colors.white;
    } else if (text == '=') {
      // Eşittir - Koyu amber
      buttonColor = deepAmber;
      buttonTextColor = Colors.white;
    } else if (['÷', '×', '-', '+'].contains(text)) {
      // Operatörler - Ana turuncu
      buttonColor = primaryOrange;
      buttonTextColor = Colors.white;
    } else if (text == 'AC' || text == 'C') {
      // Temizle - Yumuşak mercan
      buttonColor = widget.isDarkMode
          ? const Color(0xFFDC6B4A)
          : const Color(0xFFFFCCAA);
      buttonTextColor = widget.isDarkMode
          ? Colors.white
          : const Color(0xFF9A3412);
    } else if (!RegExp(r'^[0-9.]+$').hasMatch(text)) {
      // Bilimsel fonksiyonlar - Teal tonları
      buttonColor = widget.isDarkMode
          ? const Color(0xFF164E63)
          : const Color(0xFFCFFAFE);
      buttonTextColor = widget.isDarkMode
          ? const Color(0xFF67E8F9)
          : const Color(0xFF0E7490);
    }

    Widget content;
    if (text == "C") {
      content = Icon(
        Icons.backspace_outlined,
        size: 22,
        color: buttonTextColor,
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text(
          displayText,
          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Expanded(
      flex: flex,
      child: Container(
        margin: const EdgeInsets.all(2.0),
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: buttonTextColor,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 1,
            ),
            onPressed: () => _onButtonPressed(displayText),
            child: FittedBox(fit: BoxFit.scaleDown, child: content),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = widget.isDarkMode
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
    Color mainTextColor = widget.isDarkMode
        ? Colors.white
        : const Color(0xFF0F172A);
    Color historyTextColor = widget.isDarkMode
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    Color appBarColor = widget.isDarkMode
        ? const Color(0xFF0F172A)
        : const Color(0xFFFF9500);

    return Scaffold(
      backgroundColor: bgColor,
      drawer: AppDrawer(
        isDarkMode: widget.isDarkMode,
        currentPage: 'scientific',
      ),
      appBar: AppBar(
        title: const Text(
          "Bilimsel Hesap Makinesi",
          style: TextStyle(fontSize: 16),
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
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _isDegree ? "DEG" : "RAD",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: mainTextColor.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      _displayHistory,
                      style: TextStyle(fontSize: 22, color: historyTextColor),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _displayExpression,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: mainTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        buildButton('Rad'),
                        buildButton('Deg'),
                        buildButton('x!'),
                        buildButton('('),
                        buildButton(')'),
                        buildButton('C'),
                        buildButton('AC'),
                      ],
                    ),
                    Row(
                      children: [
                        buildButton('Inv'),
                        buildButton('sin'),
                        buildButton('ln'),
                        buildButton('7'),
                        buildButton('8'),
                        buildButton('9'),
                        buildButton('÷'),
                      ],
                    ),
                    Row(
                      children: [
                        buildButton('π'),
                        buildButton('cos'),
                        buildButton('log'),
                        buildButton('4'),
                        buildButton('5'),
                        buildButton('6'),
                        buildButton('×'),
                      ],
                    ),
                    Row(
                      children: [
                        buildButton('e'),
                        buildButton('tan'),
                        buildButton('√'),
                        buildButton('1'),
                        buildButton('2'),
                        buildButton('3'),
                        buildButton('-'),
                      ],
                    ),
                    Row(
                      children: [
                        buildButton('Ans'),
                        buildButton('EXP'),
                        buildButton('^'),
                        buildButton(','),
                        buildButton('0'),
                        buildButton('='),
                        buildButton('+'),
                      ],
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
}
