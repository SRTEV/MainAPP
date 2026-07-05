import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Register extends StatelessWidget {
  const Register({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = GoogleFonts.inter(
      color: Colors.black,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              Center(
                child: Text(
                  "Join us!",
                  style: GoogleFonts.inter(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.0,
                  ),
                ),
              ),


              const Spacer(flex: 3),

              Text("Your name and surname:", style: texts),
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Jan Kowalski',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.black, width: 3),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                ),
              ),

              const SizedBox(height: 16),
              Text("Your email:", style: texts),
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'kowalski@gmail.com',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.black, width: 3),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                ),
              ),

              const SizedBox(height: 16),
              Text("Your password:", style: texts),
              const SizedBox(height: 8),
              TextField(
                obscureText: true,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: '**********',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.black, width: 3),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                ),
              ),

              const SizedBox(height: 16),
              Text("Confirm your password:", style: texts),
              const SizedBox(height: 8),
              TextField(
                obscureText: true,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: '**********',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.black, width: 3),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                ),
              ),

              const Spacer(flex: 2),

              Center(
                child: SizedBox(
                  width: 200,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Register",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ЗАМІНІТЬ ЦЕЙ БЛОК:
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Log in",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text("Contact to support", style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
