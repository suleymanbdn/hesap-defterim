import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'dart:math' as math;
import 'drawer_widget.dart';

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
          _expression += "e";
          break;
        case 'x!':
          _expression += "!";
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
            finalExpression = finalExpression.replaceAll('e', '${math.e}');

            finalExpression = finalExpression.replaceAll('log', 'log10');
            finalExpression = finalExpression.replaceAll('ln', 'ln');

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

    Color buttonColor = widget.isDarkMode
        ? const Color(0xFF1E293B)
        : const Color(0xFFF0F0F0);
    Color buttonTextColor = widget.isDarkMode
        ? Colors.white
        : const Color(0xFF0F172A);

    bool isActiveMode = false;
    if ((text == 'Rad' && !_isDegree) ||
        (text == 'Deg' && _isDegree) ||
        (text == 'Inv' && _isInv)) {
      isActiveMode = true;
    }

    if (isActiveMode) {
      buttonColor = const Color(0xFF3B82F6);
      buttonTextColor = Colors.white;
    } else if (text == '=') {
      buttonColor = Colors.red.shade700;
      buttonTextColor = Colors.white;
    } else if (['÷', '×', '-', '+'].contains(text)) {
      buttonColor = const Color(0xFFFF9500);
      buttonTextColor = Colors.white;
    } else if (!RegExp(r'^[0-9.]+$').hasMatch(text) &&
        text != 'AC' &&
        text != 'C') {
      buttonColor = widget.isDarkMode
          ? const Color(0xFF334155)
          : const Color(0xFFE2E8F0);
    } else if (text == 'AC' || text == 'C') {
      buttonColor = Colors.redAccent.shade100;
      buttonTextColor = Colors.black;
    }

    Widget content;
    if (text == "C") {
      content = const Icon(
        Icons.backspace_outlined,
        size: 22,
        color: Colors.black,
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
            onPressed: () => _onButtonPressed(text),
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
      body: Column(
        children: [
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
                    _history,
                    style: TextStyle(fontSize: 22, color: historyTextColor),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _expression,
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
                      buildButton('.'),
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
    );
  }
}
