import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'Register.dart';
import '../Controllers/AuthController.dart';
import 'ResetPassword.dart';
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String email = '';
  String password = '';

  void _hideKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthController>();
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
                const SizedBox(height: 80),
                Center(
                  child: Text(
                    "Welcome back!",
                    style: GoogleFonts.inter(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.0,
                    ),
                  ),
                ),

                const SizedBox(height: 100),
                Text("Your email:", style: texts),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (value) => email = value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'kowalski@gmail.com',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: viewModel.emailBorderColor, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: viewModel.emailBorderColor, width: 3),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                  ),
                ),

                const SizedBox(height: 25),
                Text("Your password:", style: texts),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (value) => password = value,
                  obscureText: true,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: '**********',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: viewModel.passwordBorderColor, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: viewModel.passwordBorderColor, width: 3),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                  ),
                ),


                const SizedBox(height: 10),
                if (viewModel.message.isNotEmpty)
                  Text(
                    viewModel.message,
                    style: const TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w500),
                  ),

                const SizedBox(height: 60),
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        _hideKeyboard();
                        viewModel.login(context, email, password);
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
                        "Log in",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: () {
                          _hideKeyboard();
                          viewModel.clearMessage();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Register()),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text("Register", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                      ),
                      TextButton(
                        onPressed: () {
                          _hideKeyboard();
                          Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Resetpassword()),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text("Reset password", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 155),
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
