
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mainapp/Controllers/UserController.dart';
import 'package:mainapp/ViewModels/Login.dart';
import 'package:provider/provider.dart';

import '../Controllers/AuthController.dart';

class DeleteAccount extends StatefulWidget {
  const DeleteAccount({super.key});

  @override
  _DeleteAccountState createState() => _DeleteAccountState();
}

class _DeleteAccountState extends State<DeleteAccount> {
  final TextEditingController _passwordController =
  TextEditingController();
  final TextEditingController _confirmController =
  TextEditingController();

  bool _passwordError = false;
  bool _confirmError = false;

  void _hideKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final userController = context.read<UserController>();

    return GestureDetector(
      onTap: _hideKeyboard,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SingleChildScrollView(
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
                          color: Colors.black,
                        ),
                        onPressed: () =>
                            Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Delete account",
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  Text(
                    "Write your password :",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    onChanged: (value) {
                      if (_passwordError && value.isNotEmpty) {
                        setState(() {
                          _passwordError = false;
                        });
                      }
                    },
                    decoration: _inputDecoration(
                      hint: "*********",
                      borderColor: _passwordError
                          ? Colors.red
                          : Colors.grey.shade500,
                    ),
                  ),

                  const SizedBox(height: 30),

                  Text(
                    'Write "DELETE" :',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: _confirmController,
                    onChanged: (value) {
                      if (_confirmError && value == "DELETE") {
                        setState(() {
                          _confirmError = false;
                        });
                      }
                    },
                    decoration: _inputDecoration(
                      hint: "DELETE",
                      borderColor: _confirmError
                          ? Colors.red
                          : Colors.grey.shade500,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    authController.message,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 60),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        _hideKeyboard();

                        final passwordInvalid =
                            _passwordController.text.isEmpty;
                        final confirmInvalid =
                            _confirmController.text != "DELETE";

                        setState(() {
                          _passwordError = passwordInvalid;
                          _confirmError = confirmInvalid;
                        });

                        if (passwordInvalid || confirmInvalid) {
                          authController.setMessage(
                            passwordInvalid && confirmInvalid
                                ? "Please check your password and type DELETE"
                                : passwordInvalid
                                ? "Please enter your password"
                                : 'Please type "DELETE" correctly',
                            isError: true,
                          );
                          return;
                        }

                        authController.setMessage(
                          "",
                          isError: false,
                        );

                        try {
                          final auth =
                          context.read<AuthController>();

                          await userController.deleteAccount(
                            auth.userId!,
                            _passwordController.text,
                            auth.token!,
                          );

                          auth.clearSomeData();

                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Login(),
                              ),
                                  (route) => false,
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;

                          authController.setMessage(
                            "Failed to delete. Check your password.",
                            isError: true,
                          );

                          setState(() {
                            _passwordError = true;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Delete account",
                        style: TextStyle(
                          color: Colors.red,
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
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hint,
    required Color borderColor,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: borderColor,
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: borderColor,
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: borderColor,
          width: 2.0,
        ),
      ),
    );
  }
}
