import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mainapp/Controllers/AuthController.dart';
import 'package:mainapp/Controllers/UserController.dart';
import 'package:provider/provider.dart';
import '../ViewModels/Login.dart';

class RepairmanProfile extends StatefulWidget {
  final bool hasActiveRepair;

  const RepairmanProfile({super.key, this.hasActiveRepair = false});

  @override
  _RepairmanProfileState createState() => _RepairmanProfileState();
}

class _RepairmanProfileState extends State<RepairmanProfile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authCtrl = context.read<AuthController>();
      final userCtrl = context.read<UserController>();
      if (authCtrl.userId != null && authCtrl.token != null) {
        await userCtrl.fetchUserName(authCtrl.userId!, authCtrl.token!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userModel = context.watch<UserController>();
    final authCtrl = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Верхня панель з кнопкою назад та вітанням
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
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 2),

              Center(
                child: Column(
                  children: [
                    _buildActionButton(
                      "User mode",
                      widget.hasActiveRepair ? Colors.grey : Colors.black,
                      widget.hasActiveRepair
                          ? () {
                              // Виводимо сповіщення, якщо кнопка заблокована
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Cannot switch mode while repair is active!",
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          : () {
                              authCtrl.toggleRepairmanMode();
                              Navigator.pop(context);
                            },
                      width: 300,
                      height: 48,
                      fontSize: 25,
                    ),
                    if (widget.hasActiveRepair) ...[
                      const SizedBox(height: 8),
                      Text(
                        "Finish active repair first",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ]),,
              )const Spacer(flex: 3),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    authCtrl.clearMessage();
                    authCtrl.clearSomeData();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const Login()),
                          (route) => false,
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    "Log out",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
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
          backgroundColor: borderColor == Colors.grey
              ? Colors.grey.shade300
              : Colors.black,
          foregroundColor: borderColor == Colors.grey ? Colors.grey : Colors
              .white,
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
          ),
        ),
      ),
    );
  }
}