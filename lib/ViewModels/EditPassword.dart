import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../Controllers/AuthController.dart';

class Editpassword extends StatefulWidget {
  final String token; // Приймаємо токен через конструктор

  const Editpassword({super.key, required this.token});

  @override
  State<Editpassword> createState() => EditpasswordState();
}

class EditpasswordState extends State<Editpassword> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  void _hideKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Метод для показу модального вікна підтвердження
  void _showConfirmationDialog(BuildContext context) {
    _hideKeyboard();
    final viewModel = context.read<AuthController>();
    viewModel.clearMessage();

    // Проста валідація перед відкриттям модалки
    if (_passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      viewModel.setMessage("Please enter all fields", isError: true);
      return;
    }
    if (_passwordController.text.length < 8) {
      viewModel.setMessage(
          "Password must be at least 8 characters", isError: true);
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      viewModel.setMessage("Passwords do not match", isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Text(
                  "Are you sure you want to edit your\npassword?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(dialogContext); // Закриваємо модалку

                            // Викликаємо зміну пароля через контролер
                            await viewModel.changelogedPassword(
                              _passwordController.text,
                              _confirmPasswordController.text,
                            );

                            // Перевіряємо, чи зміни пройшли успішно (немає помилки в повідомленні)
                            if (context.mounted) {
                              if (viewModel.message.toLowerCase().contains(
                                  "success")) {
                                // Повертаємось на Profile і передаємо текст нотифікації
                                Navigator.pop(context, viewModel.message);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            "Save",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.arrow_circle_left_outlined,
                        size: 36,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        viewModel.clearMessage();
                      },
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        "Edit password",
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.0,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                const Text(
                  "Your new password:",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black, width: 1.5),
                    color: Colors.grey.shade200,
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      border: InputBorder.none,
                      hintText: '********',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Confirm your password:",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black, width: 1.5),
                    color: Colors.grey.shade200,
                  ),
                  child: TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      border: InputBorder.none,
                      hintText: '********',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                    ),
                  ),
                ),

                const SizedBox(height: 15),
                if (viewModel.message.isNotEmpty)
                  Text(
                    viewModel.message,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                const SizedBox(height: 60),

                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () => _showConfirmationDialog(context),
                      child: const Text(
                        "Save",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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