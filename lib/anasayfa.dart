import 'package:flutter/material.dart';
import 'drawer_widget.dart';

class Anasayfa extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final List<String> historyList;
  final List<String> notebookList;
  final Function(String) onAddToHistory;
  final Function(String) onAddToNotebook;
  final Function(List<String>) onUpdateNotebook;
  final VoidCallback onClearHistory;
  final VoidCallback onClearNotebook;

  const Anasayfa({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.historyList,
    required this.notebookList,
    required this.onAddToHistory,
    required this.onAddToNotebook,
    required this.onUpdateNotebook,
    required this.onClearHistory,
    required this.onClearNotebook,
  });

  @override
  State<Anasayfa> createState() => _AnasayfaState();
}

class _AnasayfaState extends State<Anasayfa> {
  String _output = "0";
  String _input = "";
  String _history = "";
  final List<String> _tokens = [];
  bool _shouldResetInput = false;

  String format(double n) {
    if (n.isInfinite) return "Tanımsız";
    if (n.isNaN) return "Hata";
    double val = double.parse(n.toStringAsFixed(8));
    String s = val.toString();
    if (s.endsWith(".0")) return s.substring(0, s.length - 2);
    return s;
  }

  void _updateOutput() {
    String s = _tokens.join(" ");
    if (_input.isNotEmpty) {
      if (s.isNotEmpty) s += " ";
      s += _input;
    }
    _output = s.isEmpty ? "0" : s;
  }

  void buttonPressed(String buttonText) {
    if (buttonText == "AC") {
      _tokens.clear();
      _input = "";
      _output = "0";
      _history = "";
      _shouldResetInput = false;
    } else if (buttonText == "C") {
      if (_input.isNotEmpty) {
        _input = _input.substring(0, _input.length - 1);
      } else if (_tokens.isNotEmpty) {
        _tokens.removeLast();
      }
      _shouldResetInput = false;
      _updateOutput();
    } else if (buttonText == "+/-") {
      if (_input.isNotEmpty) {
        if (_input.startsWith("-")) {
          _input = _input.substring(1);
        } else {
          _input = "-$_input";
        }
        _updateOutput();
      }
    } else if (["+", "-", "x", "/"].contains(buttonText)) {
      _shouldResetInput = false;
      if (_input.isNotEmpty) {
        _tokens.add(_input);
        _input = "";
      }

      if (_tokens.isNotEmpty) {
        if (["+", "-", "x", "/"].contains(_tokens.last)) {
          _tokens.last = buttonText;
        } else {
          _tokens.add(buttonText);
        }
      }
      _updateOutput();
    } else if (buttonText == "=") {
      if (_input.isNotEmpty) {
        _tokens.add(_input);
        _input = "";
      }

      if (_tokens.isNotEmpty && !["+", "-", "x", "/"].contains(_tokens.last)) {
        String expression = _tokens.join(" ");
        try {
          double result = eval(_tokens);
          String resultStr = format(result);

          if (resultStr != "Tanımsız" && resultStr != "Hata") {
            _history = "$expression = $resultStr";
            widget.onAddToHistory(_history);
          } else {
            _history = "";
          }

          _input = resultStr;
          _output = resultStr;
          _tokens.clear();
          _shouldResetInput = true;
        } catch (e) {
          _output = "Hata";
          _tokens.clear();
          _input = "";
        }
      }
    } else if (buttonText == ".") {
      if (_shouldResetInput) {
        _input = "0";
        _tokens.clear();
        _shouldResetInput = false;
      }
      if (!_input.contains(".")) {
        _input = _input.isEmpty ? "0." : "$_input.";
      }
      _updateOutput();
    } else {
      if (_shouldResetInput) {
        _input = "";
        _tokens.clear();
        _shouldResetInput = false;
      }
      _input += buttonText;
      _updateOutput();
    }
    setState(() {});
  }

  double eval(List<String> tokens) {
    List<String> workingTokens = List.from(tokens);

    for (int i = 0; i < workingTokens.length; i++) {
      if (workingTokens[i] == "x" || workingTokens[i] == "/") {
        double left = double.parse(workingTokens[i - 1]);
        double right = double.parse(workingTokens[i + 1]);
        double res = 0;
        if (workingTokens[i] == "x") res = left * right;
        if (workingTokens[i] == "/") {
          if (right == 0) return double.infinity;
          res = left / right;
        }
        workingTokens[i - 1] = res.toString();
        workingTokens.removeAt(i);
        workingTokens.removeAt(i);
        i--;
      }
    }

    for (int i = 0; i < workingTokens.length; i++) {
      if (workingTokens[i] == "+" || workingTokens[i] == "-") {
        double left = double.parse(workingTokens[i - 1]);
        double right = double.parse(workingTokens[i + 1]);
        double res = 0;
        if (workingTokens[i] == "+") res = left + right;
        if (workingTokens[i] == "-") res = left - right;
        workingTokens[i - 1] = res.toString();
        workingTokens.removeAt(i);
        workingTokens.removeAt(i);
        i--;
      }
    }
    return double.parse(workingTokens[0]);
  }

  // Uyumlu Renk Paleti
  static const Color _primaryOrange = Color(0xFFFF9500);
  static const Color _deepAmber = Color(0xFFE67E22);

  Color getButtonColor(String text) {
    // Eşittir - Koyu amber
    if (text == "=") {
      return _deepAmber;
    }
    // Operatörler - Ana turuncu
    if (["/", "x", "-", "+"].contains(text)) {
      return _primaryOrange;
    }
    // Temizle butonları - Yumuşak mercan
    if (["AC", "C"].contains(text)) {
      return widget.isDarkMode
          ? const Color(0xFFDC6B4A)
          : const Color(0xFFFFCCAA);
    }
    // +/- ve nokta - Özel fonksiyon
    if (text == "+/-" || text == ".") {
      return widget.isDarkMode
          ? const Color(0xFF374151)
          : const Color(0xFFE5E7EB);
    }
    // Sayılar - Nötr
    return widget.isDarkMode
        ? const Color(0xFF1F2937)
        : const Color(0xFFF3F4F6);
  }

  Color getButtonTextColor(String text) {
    if (text == "=") {
      return Colors.white;
    }
    if (["/", "x", "-", "+"].contains(text)) {
      return Colors.white;
    }
    if (["AC", "C"].contains(text)) {
      return widget.isDarkMode ? Colors.white : const Color(0xFF9A3412);
    }
    return widget.isDarkMode ? Colors.white : const Color(0xFF1F2937);
  }

  Widget buildButton(String buttonText, {int flex = 1}) {
    Widget content;
    if (buttonText == "C") {
      content = Icon(
        Icons.backspace_outlined,
        size: 28,
        color: getButtonTextColor(buttonText),
      );
    } else {
      content = Text(
        buttonText,
        style: TextStyle(
          fontSize: 32.0,
          fontWeight: FontWeight.w500,
          color: getButtonTextColor(buttonText),
        ),
      );
    }

    return Expanded(
      flex: flex,
      child: Container(
        margin: const EdgeInsets.all(2.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: getButtonColor(buttonText),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
          ),
          child: Center(
            child: FittedBox(fit: BoxFit.scaleDown, child: content),
          ),
          onPressed: () => buttonPressed(buttonText),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = widget.isDarkMode
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
    Color iconColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: AppDrawer(
        isDarkMode: widget.isDarkMode,
        currentPage: 'calculator',
      ),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: appBarColor,
        foregroundColor: iconColor,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menü',
          ),
        ),
        title: const Text("Hesap Makinesi"),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            color: iconColor,
            onPressed: () {
              widget.onThemeChanged(!widget.isDarkMode);
            },
            tooltip: 'Tema Değiştir',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/history'),
                    child: Container(
                      width: double.infinity,
                      color: Colors.transparent,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Text(
                          _history,
                          style: TextStyle(
                            fontSize: 24.0,
                            color: historyTextColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25.0,
                      vertical: 5,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _output,
                        style: TextStyle(
                          fontSize: 45.0,
                          fontWeight: FontWeight.w300,
                          color: mainTextColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 7,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          buildButton("AC"),
                          buildButton("C"),
                          buildButton("+/-"),
                          buildButton("/"),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          buildButton("7"),
                          buildButton("8"),
                          buildButton("9"),
                          buildButton("x"),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          buildButton("4"),
                          buildButton("5"),
                          buildButton("6"),
                          buildButton("-"),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          buildButton("1"),
                          buildButton("2"),
                          buildButton("3"),
                          buildButton("+"),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          buildButton("0", flex: 2),
                          buildButton("."),
                          buildButton("="),
                        ],
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
}
