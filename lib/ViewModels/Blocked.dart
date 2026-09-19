import 'package:flutter/material.dart';
import 'package:mainapp/ViewModels/Login.dart';
import 'package:provider/provider.dart';

import '../Controllers/AuthController.dart';
import '../Controllers/UserController.dart';

class Blocked extends StatelessWidget {
  const Blocked({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserController>(
      builder: (context, userCtrl, child) {
        final userName = userCtrl.userName ?? "User";

        // Перевіряємо, чи дійсно є причина блокування з бази даних
        final String? rawReason = userCtrl.banReason;
        final bool hasReason = rawReason != null && rawReason.trim().isNotEmpty;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 1),
                  Center(
                    child: Text(
                      "HI, $userName",
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(flex: 2),
                  const Text(
                    "Your account was blocked",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Показуємо блок причини лише тоді, коли вона є в базі
                  if (hasReason) ...[
                    const SizedBox(height: 35),
                    Center(
                      child: Text(
                        "Reason: $rawReason",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const Spacer(flex: 3),
                  SizedBox(
                    width: 140,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        final authController = Provider.of<AuthController>(
                          context,
                          listen: false,
                        );
                        authController.clearSomeData();

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Login(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        "OK",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}