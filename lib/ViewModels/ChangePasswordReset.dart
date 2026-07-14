import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../Controllers/AuthController.dart';
import 'Login.dart';

class ChangePasswordReset extends StatefulWidget {
  final String token;

  const ChangePasswordReset({
    super.key,
    required this.token,

  });

  @override
  State<ChangePasswordReset> createState() => _ChangePasswordResetState();
}

class _ChangePasswordResetState extends State<ChangePasswordReset> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthController>().clearMessage();
    });
  }

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
                        onPressed: () {
                          Navigator.pop(context);
                          viewModel.clearMessage();
                        }),
                    const SizedBox(width: 10),
                    Text(
                      "Reset password",
                      style: GoogleFonts.inter(
                        fontSize: 35,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 80),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Write new password:",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                const SizedBox(height: 8),
                _buildTextField(_passwordController),

                const SizedBox(height: 25),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Retype new password:",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                const SizedBox(height: 8),
                _buildTextField(_confirmPasswordController),

                const SizedBox(height: 10),
                if (viewModel.message.isNotEmpty)
                  Text(viewModel.message,
                      style: const TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w500)),

                const SizedBox(height: 60),

                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final authProvider = Provider.of<AuthController>(context, listen: false);
                        _hideKeyboard();


                        await authProvider.changePassword(
                          context,
                          widget.token,
                          _passwordController.text,
                          _confirmPasswordController.text,
                        );

                        if (!authProvider.message.contains("Error") && authProvider.message.contains("success")) {
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const Login()),
                                  (route) => false,
                            );
                          }
                        }
                      },
                      child: const Text("Reset password", style: TextStyle(fontSize: 16)),
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

  Widget _buildTextField(TextEditingController controller) {
    final viewModel = context.watch<AuthController>();
    return TextField(
      controller: controller,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      ),
    );
  }
}