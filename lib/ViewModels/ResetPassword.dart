import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controllers/AuthController.dart';
import 'package:google_fonts/google_fonts.dart';

class Resetpassword extends StatefulWidget {
  const Resetpassword({super.key});

  @override
  State<Resetpassword> createState() => _ResetpasswordState();
}

class _ResetpasswordState extends State<Resetpassword> {
  final TextEditingController _emailController = TextEditingController();

  void _hideKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  Widget build(BuildContext context) {

    final viewModel = context.watch<AuthController>();

    return GestureDetector(
      onTap: _hideKeyboard,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 60),

                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_circle_left_outlined, size: 36),
                      onPressed: () => {Navigator.pop(context),
                      viewModel.clearMessage()
                      }
                    ),
                    Text(
                      "Reset password",
                      style: GoogleFonts.inter(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 175),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Your email:",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),

                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  obscureText: false,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Kowalski@gmail.com',
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


                const SizedBox(height: 10),
                if (viewModel.message.isNotEmpty)
                  Text(
                    viewModel.message,
                    style: const TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w500),
                  ),

                const SizedBox(height: 175),

                Center(
                  child: SizedBox(
                    width: 180,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        viewModel.clearMessage();
                        _hideKeyboard();
                        Provider.of<AuthController>(context, listen: false).ResetPassword(context, _emailController.text);
                      },
                      child: const Text("Send code", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}