import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controllers/UserController.dart';
import '../Controllers/Controller.dart';


class Contactsupport extends StatefulWidget {
  final int? vehicleId;
  final String? email;
  const Contactsupport({super.key, this.vehicleId, this.email});

  @override
  State<Contactsupport> createState() => ContactsupportState();
}

class ContactsupportState extends State<Contactsupport> {

  final TextEditingController _problemController = TextEditingController();
  String _selectedProblem = 'Problem with vehicles';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    items: <String>['Problem with vehicles', 'Payment issue', 'Problem with account','Other']
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
                  onPressed: () {
                    final User = context.read<UserController>();
                    User.giveMeHeplPlease(
                      _problemController.text,
                      _selectedProblem,
                      widget.vehicleId ?? null,
                      widget.email,
                      User.tempId,
                    );

                    Navigator.pop(context);
                  },
                  child: const Text("Send", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}