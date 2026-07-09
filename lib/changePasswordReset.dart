import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class changePasswordReset extends StatelessWidget {
  final String token;

  const changePasswordReset({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Reset your password ",
                style: GoogleFonts.inter(
                    fontSize: 35,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.0
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Token:",
                style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),
              SelectableText(
                token,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    backgroundColor: Colors.yellowAccent
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}