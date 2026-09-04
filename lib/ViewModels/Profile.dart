import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mainapp/Controllers/ChallangeController.dart';
import 'package:provider/provider.dart';

import '../Controllers/AuthController.dart';
import '../Controllers/UserController.dart';
import 'AddCart.dart';
import 'ChangeCard.dart';
import 'CompetitionRewardsPage.dart';
import 'ContactSupport.dart';
import 'DeleteAccount.dart';
import 'EditPassword.dart';
import 'EditProfile.dart';
import 'Login.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authCtrl = context.read<AuthController>();
      final userCtrl = context.read<UserController>();
      if (authCtrl.userId != null && authCtrl.token != null) {
        userCtrl.fetchUserName(authCtrl.userId!, authCtrl.token!);
      }

      if (userCtrl.cardId != null &&
          (userCtrl.CardNumb == null || userCtrl.CardNumb!.isEmpty)) {
        await userCtrl.getCardNumb(authCtrl.userId!, authCtrl.token!);
      }
    });
  }

  String _maskCardNumber(String? cardNumber) {
    if (cardNumber == null) {
      return "****************";
    }
    String first4 = cardNumber.substring(0, 4);
    String last4 = cardNumber.substring(cardNumber.length - 4);
    return "$first4****$last4";
  }

  void notification(String message, bool isSuccess) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final topPadding = MediaQuery
        .of(context)
        .padding
        .top;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        backgroundColor: isSuccess ? Colors.green.shade600 : Colors.red
            .shade600,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          top: topPadding + 5,
          left: 20,
          right: 20,
          bottom: MediaQuery
              .of(context)
              .size
              .height - topPadding - 70,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 10,
        duration: const Duration(seconds: 4),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userModel = context.watch<UserController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_circle_left_outlined,
                      size: 36,
                      color: Colors.black,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      userModel.userName != null
                          ? "Hi, ${userModel.userName}!"
                          : "Loading...",
                      style: GoogleFonts.inter(
                          fontSize: 30, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Text(
                userModel.balance != null
                    ? "Outstanding balance : ${userModel.balance} Zł"
                    : "Loading...",
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w700),
              ),

              if (userModel.balance != null && userModel.balance! > 0.0) ...[
                const SizedBox(height: 10),
                _buildActionButton(
                  "Pay outstanding balance",
                  Colors.red,
                      () {
                    debugPrint("Pay button pressed");
                  },
                  width: 260,
                  height: 30,
                  fontSize: 14,
                ),
              ],

              const SizedBox(height: 16),
              if (userModel.cardId == null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Payment card:",
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildActionButton("Add payment card", Colors.black, () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddCard()),
                  );

                  if (result != null && result is String && mounted) {
                    bool isSuccess = result.contains("Success");
                    if (isSuccess) {
                      final authCtrl = context.read<AuthController>();
                      await context.read<UserController>().fetchUserName(
                          authCtrl.userId!, authCtrl.token!);
                    }
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      notification(result, isSuccess);
                    });
                  }
                }, width: double.infinity),
              ] else ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Payment card:",
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 2.0),
                  ),
                  child: Text(
                    _maskCardNumber(userModel.CardNumb),
                    style: GoogleFonts.inter(
                        fontSize: 16, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        "Change card",
                        Colors.black,
                            () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Changecard()),
                          );

                          if (result != null && result is String && mounted) {
                            bool isSuccess = result.contains("Success");
                            if (isSuccess) {
                              final authCtrl = context.read<AuthController>();
                              await context
                                  .read<UserController>()
                                  .fetchUserName(
                                  authCtrl.userId!, authCtrl.token!);
                            }
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              notification(result, isSuccess);
                            });
                          }
                        },
                        height: 30,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        "Remove card",
                        Colors.black,
                            () {
                              // Зберігаємо посилання заздалегідь
                              final dialogContext = context;
                              final userCtrl = context.read<UserController>();
                              final authCtrl = context.read<AuthController>();

                          showDialog(
                            context: dialogContext,
                            builder: (BuildContext ctx) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                title: Text(
                                  "Delete Payment Card",
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700),
                                ),
                                content: Text(
                                  "Are you sure you want to remove your payment card?",
                                  style: GoogleFonts.inter(),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text("Cancel",
                                        style: TextStyle(color: Colors.black)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () async {
                                      Navigator.pop(ctx); // Закриваємо діалог

                                      int cardId = int.parse(
                                          userModel.cardId.toString());
                                      String? message = await userCtrl
                                          .deleteCard(cardId, authCtrl.token!);

                                      if (mounted) {
                                        bool isSuccess = message != null &&
                                            message.contains("Success");

                                        if (isSuccess) {
                                          // Оновлюємо дані юзера, щоб cardId став null і зникли поля карти
                                          await userCtrl.fetchUserName(
                                              authCtrl.userId!,
                                              authCtrl.token!);
                                        }

                                        notification(
                                            message ?? "Done", isSuccess);
                                      }
                                    },
                                    child: const Text("Delete",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        height: 30,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 120),
              Center(
                child: _buildActionButton(
                  "Your Prizes",
                  Colors.black,
                      () async {
                    final challengeController = context.read<
                        Challangecontroller>();
                    final authController = context.read<AuthController>();

                    final competitionId = challengeController.competitionId;
                    final userId = authController.userId;
                    final token = authController.token;

                    if (competitionId != null && userId != null &&
                        token != null) {
                      // Завантажуємо результат перед переходом
                      await challengeController.fetchUserResult(
                          token, userId, competitionId);

                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                Competitionrewardspage(
                                  userId: userId,
                                  competitionId: competitionId,
                                ),
                          ),
                        );
                      }
                    } else {
                      notification("Competition data not loaded yet.", false);
                    }
                  },
                  width: 300,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 50),
              Center(
                child: _buildActionButton(
                  "Contact to support",
                  Colors.black,
                      () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            Contactsupport(
                              vehicleId: null,
                              email: context
                                  .read<UserController>()
                                  .userEmail,
                            ),
                      ),
                    );

                    if (result != null && result is String && mounted) {
                      bool isSuccess = result.contains("success");
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        notification(result, isSuccess);
                      });
                    }
                  },
                  width: 300,
                ),
              ),

              const SizedBox(height: 16),

              // Рядок з маленькими кнопками Edit profile та Edit password
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildActionButton(
                      "Edit profile",
                      Colors.black,
                          () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => EditProfile()),
                        );

                        if (result != null && result is String && mounted) {
                          bool isSuccess = result.contains("Success");
                          if (isSuccess) {
                            final authCtrl = context.read<AuthController>();
                            await context.read<UserController>().fetchUserName(
                                authCtrl.userId!, authCtrl.token!);
                          }
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            notification(result, isSuccess);
                          });
                        }
                      },
                      height: 30,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildActionButton(
                      "Edit password",
                      Colors.black,
                          () async {
                        final authController = Provider.of<AuthController>(
                            context, listen: false);

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) =>
                              Editpassword(token: authController.token!)),
                        );

                        if (result != null && result is String && mounted) {
                          bool isSuccess = result.contains("success");
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            notification(result, isSuccess);
                          });
                        }
                      },
                      height: 30,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 80),

              // Кнопка Log out
              Center(
                child: _buildActionButton(
                  "Log out",
                  Colors.grey,
                      () {
                    final auth = context.read<AuthController>();
                    auth.clearMessage();
                    auth.clearSomeData();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const Login()),
                          (route) => false,
                    );
                  },
                  width: 220,
                  height: 30,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 16),

              // Кнопка Delete account
              Center(
                child: _buildActionButton(
                  "Delete account",
                  Colors.red,
                      () {
                    context.read<AuthController>().clearMessage();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DeleteAccount()),
                    );
                  },
                  width: 320,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text,
      Color borderColor,
      VoidCallback onPressed, {
        double? width,
        double height = 48,
        double fontSize = 16,
      }) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          side: BorderSide(color: borderColor, width: 2.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: borderColor == Colors.grey ? Colors.grey : null,
          ),
        ),
      ),
    );
  }
}