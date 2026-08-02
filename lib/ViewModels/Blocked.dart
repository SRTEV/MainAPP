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
        final userName = userCtrl.userName ?? "Jan";
        final reason =
            userCtrl.banReason ?? "Inappropriate use of the monowheel";

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
                // ВАЖЛИВО: Вирівнювання елементів стовпця по центру по горизонталі
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 1),
                  // Вітання (HI, [userName])
                  // Гарантоване центрування за допомогою Center
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

                  // Повідомлення про блок
                  const Text(
                    "Your account was blocked",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 35),

                  // Причина блокування
                  // Обгортаємо в Center, щоб він не притискався до краю
                  Center(
                    child: Text(
                      "Reason: $reason",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Чорна кнопка "OK" з переходом на логін
                  // Вона вже має фіксовану ширину, тому центрується автоматично в стовпці
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
