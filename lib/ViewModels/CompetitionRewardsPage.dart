import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../Controllers/AuthController.dart';
import '../Controllers/ChallangeController.dart';

class Competitionrewardspage extends StatefulWidget {
  final int userId;
  final int competitionId;

  const Competitionrewardspage({
    super.key,
    required this.userId,
    required this.competitionId,
  });

  @override
  State<Competitionrewardspage> createState() => _CompetitionrewardspageState();
}

class _CompetitionrewardspageState extends State<Competitionrewardspage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVm = context.read<AuthController>();
      final challengeVm = context.read<Challangecontroller>();
      final token = authVm.token ?? "";

      // Завантажуємо весь список нагород користувача
      challengeVm.fetchAllUserResults(token, widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Consumer<Challangecontroller>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.black));
            }

            // Фільтруємо список: залишаємо лише ті змагання, термін яких вже минув (endDate <= поточна дата)
            final results = controller.allUserResults.where((result) {
              if (result.endDate == null) return false;
              try {
                final endDate = DateTime.parse(result.endDate!);
                // Перевіряємо, чи дата закінчення раніша або дорівнює сьогоднішній
                return endDate.isBefore(DateTime.now()) ||
                    endDate.isAtSameMomentAs(DateTime.now());
              } catch (_) {
                return false;
              }
            }).toList();

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.arrow_circle_left_outlined,
                          size: 36,
                          color: Colors.black,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "Your Prizes",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (results.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          "No prizes found yet.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final result = results[index];

                          // Використовуємо paymentId для визначення, чи використана нагорода
                          final bool isRewardUsed = result.paymentId != null;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        result.challengeTypeName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amberAccent,
                                        ),
                                      ),
                                    ),
                                    if (isRewardUsed)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade800,
                                          borderRadius: BorderRadius.circular(
                                              8),
                                        ),
                                        child: Text(
                                          "USED",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0),
                                  child: Divider(
                                      color: Colors.white24, thickness: 1),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceBetween,
                                  children: [
                                    Text(
                                      result.vehicleTypeName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      "Rank #${result.rank}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "${result.score} m",
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Prize: ${result.rewardName}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Value: ${result.rewardAmount}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0),
                                  child: Divider(
                                      color: Colors.white24, thickness: 1),
                                ),
                                Text(
                                  "Period: ${result.startDate ?? ''} — ${result
                                      .endDate ?? ''}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}