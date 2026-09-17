import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mainapp/Controllers/ChallangeController.dart';
import 'package:provider/provider.dart';

import '../Controllers/AuthController.dart';
import '../Controllers/PaymentController.dart';
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
        await userCtrl.fetchUserName(authCtrl.userId!, authCtrl.token!);
      }

      if (userCtrl.cardId != null &&
          (userCtrl.CardNumb == null || userCtrl.CardNumb!.isEmpty)) {
        await userCtrl.getCardNumb(authCtrl.userId!, authCtrl.token!);
      }
    });
  }

  Future<void> _refreshUserData() async {
    final authCtrl = context.read<AuthController>();
    final userCtrl = context.read<UserController>();
    if (authCtrl.userId != null && authCtrl.token != null) {
      await userCtrl.fetchUserName(authCtrl.userId!, authCtrl.token!);
      if (userCtrl.cardId != null) {
        await userCtrl.getCardNumb(authCtrl.userId!, authCtrl.token!);
      } else {
        userCtrl.CardNumb = null;
      }
      if (mounted) setState(() {});
    }
  }

  String _maskCardNumber(String? cardNumber) {
    if (cardNumber == null || cardNumber
        .trim()
        .length < 8) {
      return "•••• •••• •••• ••••";
    }
    String cleaned = cardNumber.trim();
    String first4 = cleaned.substring(0, 4);
    String last4 = cleaned.substring(cleaned.length - 4);
    return "$first4 •••• •••• $last4";
  }

  void _showTopNotification(BuildContext context, String message) {
    if (!mounted) return;
    bool isSuccess = message.toLowerCase().contains("success");

    OverlayState overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) =>
          Positioned(
            top: MediaQuery
                .of(context)
                .padding
                .top + 10,
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSuccess ? Colors.green.shade600 : Colors.red
                        .shade600,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
      ),
    );

    overlayState.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 4), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userModel = context.watch<UserController>();
    final authCtrl = context.watch<
        AuthController>(); // Слідкуємо за станом AuthController

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
                      () async {
                    final token = authCtrl.token;
                    final userId = authCtrl.userId;
                    final paymentCtrl = context.read<PaymentController>();
                    final userCtrl = context.read<UserController>();
                    if (token != null && userId != null) {
                      bool success = await paymentCtrl.payOutstandingBalance(
                        authCtrl.userId!, // 1. userId
                        authCtrl.token!, // 2. token
                        userCtrl.CardNumb, // 3. cardNum
                        userCtrl.cardExpiryDate, // 4. cardExpDate
                        userCtrl.cardCvv, // 5. cardCvv
                        userCtrl.userEmail, // 6. userEmail
                      );

                      if (mounted) {
                        _showTopNotification(context, paymentCtrl.message);
                        if (success) {
                          await _refreshUserData();
                        }
                      }
                    }
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
                    bool isSuccess = result.toLowerCase().contains("success");
                    if (isSuccess) {
                      await _refreshUserData();
                    }
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showTopNotification(context, result);
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
                            bool isSuccess = result.toLowerCase().contains(
                                "success");
                            if (isSuccess) {
                              await _refreshUserData();
                            }
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _showTopNotification(context, result);
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
                              final dialogContext = context;
                              final userCtrl = context.read<UserController>();

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
                                      Navigator.pop(ctx);

                                      int cardId = int.parse(
                                          userModel.cardId.toString());
                                      String? message = await userCtrl
                                          .deleteCard(cardId, authCtrl.token!);

                                      if (mounted) {
                                        bool isSuccess = message != null &&
                                            message.toLowerCase().contains(
                                                "success");

                                        if (isSuccess) {
                                          await _refreshUserData();
                                        }

                                        _showTopNotification(
                                            context, message ?? "Done");
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

              const SizedBox(height: 85),

              if (authCtrl.isRepairman) ...[
                Center(
                  child: _buildActionButton(
                    "Repairman mode",
                    Colors.black,
                        () {
                      authCtrl.toggleRepairmanMode();
                      Navigator.pop(context);
                    },
                    width: 300,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Center(
                child: _buildActionButton(
                  "Your Prizes",
                  Colors.black,
                      () async {
                        final challengeController = context.read<
                            Challangecontroller>();
                        final userId = authCtrl.userId;
                        final token = authCtrl.token;

                        if (userId != null && token != null) {
                          await challengeController.fetchAllUserResults(
                              token, userId);

                          int? targetCompetitionId = challengeController
                              .competitionId;

                          if (targetCompetitionId == null &&
                              challengeController.allUserResults.isNotEmpty) {
                            targetCompetitionId =
                                challengeController.allUserResults.first
                                    .competitionId;
                          }

                          if (targetCompetitionId != null && mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                Competitionrewardspage(
                                  userId: userId,
                                  competitionId: targetCompetitionId!,
                                ),
                          ),
                        );
                          } else {
                            _showTopNotification(
                                context, "No competition results found.");
                          }
                        } else {
                          _showTopNotification(
                              context, "User data not loaded yet.");
                    }
                  },
                  width: 300,
                ),
              ),
              const SizedBox(height: 60),

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
                      bool isSuccess = result.toLowerCase().contains("success");
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _showTopNotification(context, result);
                      });
                    }
                  },
                  width: 300,
                ),
              ),

              const SizedBox(height: 16),

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
                          bool isSuccess = result.toLowerCase().contains(
                              "success");
                          if (isSuccess) {
                            await context.read<UserController>().fetchUserName(
                                authCtrl.userId!, authCtrl.token!);
                          }
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _showTopNotification(context, result);
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
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) =>
                              Editpassword(token: authCtrl.token!)),
                        );

                        if (result != null && result is String && mounted) {
                          bool isSuccess = result.toLowerCase().contains(
                              "success");
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _showTopNotification(context, result);
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

              Center(
                child: _buildActionButton(
                  "Log out",
                  Colors.grey,
                      () {
                        authCtrl.clearMessage();
                        authCtrl.clearSomeData();
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

              Center(
                child: _buildActionButton(
                  "Delete account",
                  Colors.red,
                      () {
                        authCtrl.clearMessage();
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

  Widget _buildActionButton(String text, Color borderColor,
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