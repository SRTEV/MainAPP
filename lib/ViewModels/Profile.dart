import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mainapp/ViewModels/ContactSupport.dart' hide Contactsupport;
import 'package:provider/provider.dart';
import '../Controllers/UserController.dart';
import '../Controllers/AuthController.dart';
import 'Login.dart';
import 'DeleteAccount.dart';
import 'ContactSupport.dart';
import 'AddCart.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // Видалено зайвий @override
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
                    "Your card: ${userModel.cardId}", // або userModel.cardNumber
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.green),


                  ),
                ),
              ],

              const SizedBox(height: 120),

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
                        bottom: MediaQuery.of(context).size.height - 75,
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
              const SizedBox(height: 40),
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