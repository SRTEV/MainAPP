import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../Controllers/AuthController.dart';
import '../Controllers/UserController.dart';
import '../Modules/Notifications.dart'; // Імпортуємо файл нотифікацій

class Contactsupport extends StatefulWidget {
  final int? vehicleId;
  final String? email;

  const Contactsupport({
    super.key,
    this.vehicleId,
    this.email,
  });

  @override
  State<Contactsupport> createState() => ContactsupportState();
}

class ContactsupportState extends State<Contactsupport> {
  final TextEditingController _problemController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedProblem = 'Problem with vehicles';

  // Регулярний вираз для перевірки пошти
  final String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';

  void _hideKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  bool _isValidEmail(String email) {
    return RegExp(emailRegex).hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final userController = context.watch<UserController>();

    final bool isLoggedIn = authController.token != null &&
        (widget.email != null || userController.userEmail != null);
    final bool isRepairmanMode = isLoggedIn && authController.RMode;
    final String activeProblemCategory = isRepairmanMode
        ? 'Repairman'
        : (isLoggedIn ? _selectedProblem : 'Problem with account');

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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_circle_left_outlined,
                        size: 36,
                        color: Colors.black,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 15),
                    Text(
                      "Describe  your \n problem",
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        height: 1.1,
                        letterSpacing: -1.0,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // 1. Якщо НЕ залогінений — показуємо текстове поле для вводу Email
                if (!isLoggedIn) ...[
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'kowalski@gmail.com',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.black,
                            width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.black,
                            width: 3),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 2. Вибір категорії або фіксований статус Repairman
                if (isRepairmanMode)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.black, width: 1.5),
                      color: Colors.grey.shade200,
                    ),
                    child: const Text(
                      'Repairman',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.black, width: 1.5),
                      color: Colors.grey.shade200,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: isLoggedIn
                            ? _selectedProblem
                            : 'Problem with account',
                        dropdownColor: Colors.grey.shade200,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 30),
                        items: (isLoggedIn
                            ? <String>[
                          'Problem with vehicles',
                          'Payment issue',
                          'Problem with account',
                          'Other'
                        ]
                            : <String>['Problem with account', 'Other'])
                            .map((String value) =>
                            DropdownMenuItem<String>(
                                value: value, child: Text(value)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedProblem = val!),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: TextField(
                      controller: _problemController,
                      maxLines: null,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(16),
                        border: InputBorder.none,
                        hintText: 'Enter your message...',
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () async {
                      _hideKeyboard();

                      // Визначаємо фінальний email
                      final String? finalEmail = isLoggedIn
                          ? (widget.email ?? userController.userEmail)
                          : _emailController.text.trim();

                      // Перевірка валідності email для незалогінених користувачів
                      if (!isLoggedIn) {
                        if (finalEmail == null || finalEmail.isEmpty ||
                            !_isValidEmail(finalEmail)) {
                          if (context.mounted) {
                            // Використовуємо глобальну нотифікацію замість SnackBar
                            showTopNotification(
                                context, "Please enter a valid email address");
                          }
                          return;
                        }
                      }

                      // Надсилаємо запит, якщо все гаразд
                      String? result = await userController.giveMeHeplPlease(
                        _problemController.text,
                        activeProblemCategory,
                        widget.vehicleId,
                        finalEmail,
                        userController.tempId,
                      );

                      if (context.mounted) {
                        Navigator.pop(context, result);
                      }
                    },
                    child: const Text(
                      "Send",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}