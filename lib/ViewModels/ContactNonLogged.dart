import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controllers/UserController.dart';
import '../Controllers/Controller.dart';


class ContactNonLogged extends StatefulWidget {

  const ContactNonLogged({super.key});

  @override
  State<ContactNonLogged> createState() => ContactNonLoggedState();
}

class ContactNonLoggedState extends State<ContactNonLogged> {

  final TextEditingController _problemController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedProblem = 'Problem with account';
  void _hideKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hideKeyboard,
      child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_circle_left_outlined, size: 36),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    "Describe  your \n problem",
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      height: 1.1,
                      letterSpacing: -1.0,

                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'kowalski@gmail.com',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.black, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.black, width: 3),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.black, width: 1.5),
                  color: Colors.grey.shade200,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedProblem,
                    dropdownColor: Colors.grey.shade200,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 30),
                    items: <String>['Problem with account','Other']
                        .map((String value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedProblem = val!),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: TextField(
                    controller: _problemController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(16),
                      border: InputBorder.none,
                      hintText: 'Enter your message...',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () async {
                    final User = context.read<UserController>();

                   String? result = await User.giveMeHeplPlease(
                      _problemController.text,
                      _selectedProblem,
                      null,
                      _emailController.text,
                      null
                    );

                    if (context.mounted) {
                      Navigator.pop(context, result);
                    }
                  },
                  child: const Text("Send", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      )
    );
  }
}