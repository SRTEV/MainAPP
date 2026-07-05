import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'Controller.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  String email = '';
  String password = '';
  String confirmPassword = '';
  String name = '';

  InputDecoration _inputDecoration(String hint, Color borderColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.grey.shade200,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: borderColor, width: 3),


      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  void _hideKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ScooterViewModel>();
    final texts = GoogleFonts.inter(
      color: Colors.black,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );

    return GestureDetector(
      onTap: _hideKeyboard,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Center(
                  child: Text(
                    "Join us!",
                    style: GoogleFonts.inter(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text("Your name and surname:", style: texts),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (value) => name = value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: _inputDecoration('Jan Kowalski', viewModel.nameBorderColor),
                ),
                const SizedBox(height: 16),
                Text("Your email:", style: texts),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (value) => email = value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: _inputDecoration('kowalski@gmail.com', viewModel.emailBorderColor),
                ),
                const SizedBox(height: 16),
                Text("Your password:", style: texts),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (value) => password = value,
                  obscureText: true,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: _inputDecoration('**********', viewModel.passwordBorderColor),
                ),
                const SizedBox(height: 16),
                Text("Confirm your password:", style: texts),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (value) => confirmPassword = value,
                  obscureText: true,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: _inputDecoration('**********', viewModel.passwordBorderColor),
                ),
                const SizedBox(height: 10),
                Text(viewModel.message, style: const TextStyle(color: Colors.red , fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 70),
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        _hideKeyboard();
                        context.read<ScooterViewModel>().Register(
                              name,
                              email,
                              password,
                              confirmPassword,
                            );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Register",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account? ",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          "Log in",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 35),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text("Contact to support", style: TextStyle(color: Colors.grey)),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
