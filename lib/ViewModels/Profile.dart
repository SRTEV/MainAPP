import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../Controllers/UserController.dart';
import 'Login.dart';
import '../Controllers/AuthController.dart';
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
      final userId = Provider.of<AuthController>(context, listen: false).tempId;
      if (userId != null) {
        Provider.of<UserController>(context, listen: false).fetchUserName(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserController>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.arrow_circle_left_outlined, size: 36),
                    onPressed: () => Navigator.pop(context)
                ),
                const SizedBox(width: 5),
                Text(
                  viewModel.userName != null
                      ? "Hi, ${viewModel.userName}!"
                      : "Loading...",
                  style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w700),
                ),
              ],
            ),

            const SizedBox(height: 40),

            Column(
              children: [
                Text(
                  viewModel.balance != null
                      ? "Outstanding balance: ${viewModel.balance} Zł"
                      : "Loading...",
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (viewModel.balance != null && viewModel.balance! > 0.0)
                  ElevatedButton(
                    onPressed: () {
                      debugPrint("Pay button pressed");
                      //Pay logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      side: const BorderSide(
                        color: Colors.red,
                        width: 2.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    ),
                    child: const Text(
                      "Pay outstanding balance",
                      style: TextStyle(
                        fontSize: 18
                      ),
                    ),
                  )
              ],
            ),

            const SizedBox(height: 40),


            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Payment card: ",
                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),

                    ElevatedButton(
                      onPressed: () {
                        debugPrint("add card button pressed");

                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: Colors.black,
                          width: 2.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 75, vertical: 15),
                      ),
                      child: const Text(
                        "Add payment card",
                        style: TextStyle(
                            fontSize: 18
                        ),
                      ),
                    )
              ],
            ),

            const SizedBox(height: 120),

            ElevatedButton(
              onPressed: () {
                debugPrint("Contact to support");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 75, vertical: 15),
              ),
              child: const Text("Contact to support", style: TextStyle(fontSize: 18)),
            ),

            const SizedBox(height: 20),


            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => debugPrint("Edit profile"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  ),
                  child: const Text("Edit profile"),
                ),
                const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: () => debugPrint("Edit password"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text("Edit password"),
                ),
              ],
            ),

            const SizedBox(height: 90),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    debugPrint("Log out");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 5),
                  ),
                  child: const Text("Log out", style: TextStyle(fontSize: 15, color: Colors.grey)),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () => debugPrint("Delete account"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

                    padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 10),
                  ),
                  child: const Text("Delete account", style: TextStyle(color: Colors.red, fontSize: 18)),
                ),
              ],
            )
          ],

        ),


      ),
    );
  }
}