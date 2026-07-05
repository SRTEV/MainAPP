import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Register.dart';
class Login extends StatelessWidget {
  const Login({super.key});

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
                  "Welcome back!",
                  style: GoogleFonts.inter(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.0,
                  ),
                ),
              ),

              const Spacer(flex: 1),
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

              const SizedBox(height: 25),
              Text("Your password:", style: texts),
              const SizedBox(height: 8),
              TextField(
                obscureText: true,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: '••••••••',
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

          const SizedBox(height: 85),


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
                  "Log in",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Register()),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text("Register", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text("Reset password", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
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
