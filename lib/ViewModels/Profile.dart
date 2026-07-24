import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../Controllers/AuthController.dart';
import '../Controllers/UserController.dart';
import 'AddCart.dart';
import 'ChangeCard.dart';
import 'ContactSupport.dart';
import 'DeleteAccount.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ...
    });
  }

  @override
  Widget build(BuildContext context) {
    final userModel = context.watch<UserController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_circle_left_outlined, size: 36),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    userModel.userName != null ? "Hi, ${userModel.userName}!" : "Loading...",
                    style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w700),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              Text(
                userModel.balance != null
                    ? "Outstanding balance: ${userModel.balance} Zł"
                    : "Loading...",
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
              ),

              if (userModel.balance != null && userModel.balance! > 0.0) ...[
                const SizedBox(height: 10),
                _buildActionButton("Pay outstanding balance", Colors.red, () {
                  debugPrint("Pay button pressed");
                }),
              ],

              const SizedBox(height: 40),

              if (userModel.cardId == null) ...[
                _buildActionButton("Add payment card", Colors.black, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddCard()),
                  );
                }, horizontalPadding: 75),
              ] else ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Payment card:",
                    style: GoogleFonts.inter(fontSize: 16,
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
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 2.0),
                  ),
                  child: Text(
                    "****************", // Replace with the actual card number

                    style: GoogleFonts.inter(
                        fontSize: 16, letterSpacing: 2, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        "Change payment card",
                        Colors.black,
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Changecard()),
                          );
                        },
                        horizontalPadding: 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        "Remove payment card",
                        Colors.black,
                            () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
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
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Cancel",
                                        style: TextStyle(color: Colors.black)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () async {
                                      Navigator.pop(context);

                                      final userCtrl = context.read<
                                          UserController>();
                                      final authCtrl = context.read<
                                          AuthController>();

                                      int cardId = int.parse(
                                          userModel.cardId.toString());
                                      String? message = await userCtrl
                                          .deleteCard(cardId, authCtrl.token!);

                                      if (context.mounted) {
                                        bool isSuccess = message != null &&
                                            message.contains("Success");

                                        ScaffoldMessenger
                                            .of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              message ?? "Done",
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            backgroundColor: isSuccess ? Colors
                                                .green.shade600 : Colors.red
                                                .shade600,
                                            behavior: SnackBarBehavior.floating,
                                            dismissDirection: DismissDirection
                                                .startToEnd,
                                            margin: EdgeInsets.only(
                                              bottom: MediaQuery
                                                  .of(context)
                                                  .size
                                                  .height - 90,
                                              left: 20,
                                              right: 20,
                                            ),
                                            duration: const Duration(
                                                seconds: 4),
                                          ),
                                        );

                                        if (isSuccess) {
                                          await userCtrl.fetchUserName(
                                              authCtrl.userId!,
                                              authCtrl.token!);
                                          setState(() {});
                                        }
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
                        horizontalPadding: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],

              const SizedBox(height: 95),

              _buildActionButton("Contact to support", Colors.black, () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Contactsupport(
                      vehicleId: null,
                      email: context.read<UserController>().userEmail,
                    ),
                  ),
                );

                if (result != null && result is String && mounted) {
                  bool isSuccess = result.contains("success");

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
                      behavior: SnackBarBehavior.floating,
                      dismissDirection: DismissDirection.startToEnd,
                      margin: EdgeInsets.only(
                        bottom: MediaQuery
                            .of(context)
                            .size
                            .height - 90,
                        left: 20,
                        right: 20,
                      ),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }, horizontalPadding: 75),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton("Edit profile", Colors.black, () {}, horizontalPadding: 30),
                  const SizedBox(width: 15),
                  _buildActionButton("Edit password", Colors.black, () {}, horizontalPadding: 20),
                ],
              ),

              const SizedBox(height: 90),
              _buildActionButton("Log out", Colors.grey, () {
                final auth = context.read<AuthController>();
                auth.clearMessage();
                auth.clearSomeData();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                      (route) => false,
                );
              }, horizontalPadding: 90),

              const SizedBox(height: 20),

              _buildActionButton("Delete account", Colors.red, () {
                context.read<AuthController>().clearMessage();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DeleteAccount()),
                );
              }, horizontalPadding: 90),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, Color borderColor, VoidCallback onPressed, {double horizontalPadding = 20}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        side: BorderSide(color: borderColor, width: 2.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
      ),
      child: Text(text, style: TextStyle(fontSize: 16, color: borderColor == Colors.grey ? Colors.grey : null)),
    );
  }
}