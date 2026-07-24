import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mainapp/Controllers/AuthController.dart';
import 'package:mainapp/Controllers/UserController.dart';
import 'package:provider/provider.dart';

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll('/', '');

    if (text.length > 4) text = text.substring(0, 4);

    if (text.length >= 3) {
      text = "${text.substring(0, 2)}/${text.substring(2)}";
    } else if (text.length == 2 &&
        newValue.text.length > oldValue.text.length) {
      text = "$text/";
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class Changecard extends StatefulWidget {
  const Changecard({super.key});

  @override
  _ChangecardState createState() => _ChangecardState();
}

class _ChangecardState extends State<Changecard> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();

  String? _cardError;
  String? _cvvError;
  String? _expiryError;

  void _hideKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  bool _validateInputs() {
    setState(() {
      _cardError = null;
      _cvvError = null;
      _expiryError = null;
    });

    bool isValid = true;

    if (_cardNumberController.text.length < 13 ||
        _cardNumberController.text.length > 19) {
      setState(() => _cardError = "Invalid length (13-19 digits)");
      isValid = false;
    }

    if (_cvvController.text.length < 3 || _cvvController.text.length > 4) {
      setState(() => _cvvError = "CVV must be 3-4 digits");
      isValid = false;
    }

    try {
      final parts = _expiryController.text.split('/');

      // Перевіряємо, чи введено саме 5 символів (XX/XX)
      if (_expiryController.text.length != 5 || parts.length != 2) {
        throw Exception();
      }

      int month = int.parse(parts[0]);
      int year = int.parse("20${parts[1]}");

      // Перевірка коректності місяця
      if (month < 1 || month > 12) {
        setState(() => _expiryError = "Invalid month");
        return false;
      }

      DateTime now = DateTime.now();
      // Останній день введеного місяця
      DateTime expiry = DateTime(year, month + 1, 0);

      if (expiry.isBefore(DateTime(now.year, now.month))) {
        setState(() => _expiryError = "Card expired");
        isValid = false;
      }
    } catch (e) {
      setState(() => _expiryError = "Invalid format (MM/YY)");
      isValid = false;
    }

    return isValid;
  }

  void _showTopSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isSuccess
            ? Colors.green.shade600
            : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 75,
          left: 0,
          right: 0,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hideKeyboard,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_circle_left_outlined,
                        size: 36,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Change card",
                          style: GoogleFonts.inter(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  "Write card number:",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _cardNumberController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    hint: "1111222333444555666",
                    errorText: _cardError,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Write CVV:",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _cvvController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(
                              hint: "111",
                              errorText: _cvvError,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Write expiry date:",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _expiryController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              DateInputFormatter(),
                            ],
                            decoration: _inputDecoration(
                              hint: "MM/YY",
                              errorText: _expiryError,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () async {
                      _hideKeyboard();
                      if (!_validateInputs()) return;

                      final userCtrl = context.read<UserController>();
                      final authCtrl = context.read<AuthController>();

                      String? message = await userCtrl.updateCard(
                        authCtrl.userId!,
                        authCtrl.token!,
                        _cardNumberController.text,
                        _cvvController.text,
                        _expiryController.text,
                      );

                      if (context.mounted) {
                        bool isSuccess =
                            message != null && message.contains("Success");
                        _showTopSnackBar(message ?? "Error", isSuccess);
                        if (isSuccess) {
                          _cardNumberController.clear();
                          _cvvController.clear();
                          _expiryController.clear();
                          await userCtrl.fetchUserName(
                            authCtrl.userId!,
                            authCtrl.token!,
                          );
                          Navigator.pop(context);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "Save payment card",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint, String? errorText}) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      filled: true,
      fillColor: Colors.grey[100],
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      // Рамка завжди видима:
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.black, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.black, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.black, width: 2.0),
      ),
      // Підсвітка помилки:
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 2.0),
      ),
    );
  }
}
