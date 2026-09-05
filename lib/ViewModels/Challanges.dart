import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../Controllers/AuthController.dart';
import '../Controllers/ChallangeController.dart';
import '../Controllers/Controller.dart';

class Challanges extends StatefulWidget {
  const Challanges({super.key});

  @override
  State<Challanges> createState() => ChallangesState();
}

class ChallangesState extends State<Challanges> {
  String? selectedCategoryName;
  int? selectedVehicleTypeId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vehicleController = context.read<Controller>();
      vehicleController.fetchVehicles().then((_) {
        if (vehicleController.vehicles.isNotEmpty) {
          setState(() {
            selectedCategoryName = vehicleController.vehicles.first.type;
            selectedVehicleTypeId =
                vehicleController.vehicles.first.vehicleTypeId;
          });
          _loadCompetitionData();
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadCompetitionData() {
    if (selectedVehicleTypeId == null) return;

    final authVm = context.read<AuthController>();
    final token = authVm.token ?? "";

    context.read<Challangecontroller>().fetchLatestChallenge(
      selectedVehicleTypeId!,
      token,
    );
  }

  @override
  Widget build(BuildContext context) {
    final competitionVm = context.watch<Challangecontroller>();
    final vehicleController = context.watch<Controller>();

    final List<String> availableTypes = vehicleController.vehicleTypes;

    // Перевіряємо, чи всі нагороди (або поточний статус) мають rewardAmount == 0
    // (Адаптуйте під структуру ваших даних, якщо у вас є конкретне поле суми нагороди у competitionVm)
    bool isRewardUsed = competitionVm.rewardTypes.isNotEmpty &&
        competitionVm.rewardTypes.every((reward) {
          final amount = reward['reward_amount'] ?? reward['rewardAmount'] ?? 1;
          return amount == 0;
        });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: competitionVm.isLoading
            ? const Center(
          child: CircularProgressIndicator(color: Colors.black),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(width: 12),
                  Text(
                    "Challenges",
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Select your category:",
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Блок індикаторів у правому верхньому куті
                        Row(
                          children: [
                            if (isRewardUsed)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade800,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "USED",
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (competitionVm.isEnded)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade800,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "ENDED",
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: availableTypes.contains(
                            selectedCategoryName,
                          )
                              ? selectedCategoryName
                              : null,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.black,
                          ),
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          items: availableTypes.map((String typeName) {
                            return DropdownMenuItem<String>(
                              value: typeName,
                              child: Text(typeName),
                            );
                          }).toList(),
                          onChanged: (String? newTypeName) {
                            if (newTypeName != null) {
                              setState(() {
                                selectedCategoryName = newTypeName;
                                final matchedVehicle = vehicleController
                                    .vehicles
                                    .firstWhere(
                                      (v) => v.type == newTypeName,
                                  orElse: () =>
                                  vehicleController
                                      .vehicles
                                      .first,
                                );
                                selectedVehicleTypeId =
                                    matchedVehicle.vehicleTypeId;
                              });
                              _loadCompetitionData();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      competitionVm.message.isNotEmpty &&
                          competitionVm.competitionId == null
                          ? competitionVm.message
                          : (competitionVm.description ??
                          "Select category to view challenge"),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (competitionVm.competitionId != null) ...[
                ...competitionVm.rewardTypes
                    .asMap()
                    .entries
                    .map((entry) {
                  int index = entry.key;
                  var reward = entry.value;

                  String icon;
                  String positionText;

                  if (index == 0) {
                    icon = "🥇";
                    positionText = "1 place";
                  } else if (index == 1) {
                    icon = "🥈";
                    positionText = "2-4 places";
                  } else {
                    icon = "🥉";
                    positionText = "5 place";
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRewardRow(
                      icon,
                          () {
                        final name = reward['name'].toString().toLowerCase();
                        final unit = reward['unit'] ?? '';

                        if (name.contains('discount')) {
                          return "$positionText — ${reward['name']}: $unit%";
                        } else if (name.contains('free ride')) {
                          return "$positionText — ${reward['name']}: Free ";
                        } else {
                          return "$positionText — ${reward['name']}: $unit km";
                        }
                      }(),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(22),
                            topRight: Radius.circular(22),
                          ),
                        ),
                        child: Text(
                          "Leaderboard",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: competitionVm.leaderboard.isEmpty
                              ? Center(
                            child: Text(
                              "No participants yet",
                              style: GoogleFonts.inter(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          )
                              : RawScrollbar(
                            controller: _scrollController,
                            thumbColor: Colors.black54,
                            radius: const Radius.circular(8),
                            thickness: 6,
                            thumbVisibility: true,
                            child: ListView.builder(
                              controller: _scrollController,
                              shrinkWrap: true,
                              itemCount: competitionVm
                                  .leaderboard
                                  .length,
                              itemBuilder: (context, index) {
                                final entry = competitionVm
                                    .leaderboard[index];

                                final int rank =
                                    entry['rank'] ??
                                        (index + 1);
                                final String name =
                                    entry['name'] ?? 'User';
                                final int score =
                                    entry['score'] ?? 0;
                                final int entryUserId =
                                    entry['userId'] ?? 0;

                                final authVm = context
                                    .read<AuthController>();
                                final bool isMe =
                                    entryUserId == authVm.userId;

                                return Container(
                                  margin: const EdgeInsets.only(
                                    bottom: 8,
                                  ),
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius:
                                    BorderRadius.circular(
                                      16,
                                    ),
                                    border: isMe
                                        ? Border.all(
                                      color: Colors
                                          .blue
                                          .shade300,
                                      width: 1.5,
                                    )
                                        : Border.all(
                                      color: Colors
                                          .transparent,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Text(
                                              "$rank. ",
                                              style: GoogleFonts
                                                  .inter(
                                                fontSize: 16,
                                                fontWeight:
                                                FontWeight
                                                    .w700,
                                                color: Colors
                                                    .black,
                                              ),
                                            ),
                                            Flexible(
                                              child: Text(
                                                name,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                style: GoogleFonts
                                                    .inter(
                                                  fontSize: 16,
                                                  fontWeight: isMe
                                                      ? FontWeight
                                                      .w800
                                                      : FontWeight
                                                      .w600,
                                                  color: Colors
                                                      .black,
                                                ),
                                              ),
                                            ),
                                            if (isMe) ...[
                                              const SizedBox(
                                                width: 4,
                                              ),
                                              Text(
                                                "(You)",
                                                style: GoogleFonts
                                                    .inter(
                                                  fontSize: 16,
                                                  fontWeight:
                                                  FontWeight
                                                      .w800,
                                                  color: Colors
                                                      .black,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "$score",
                                        style: GoogleFonts
                                            .inter(
                                          fontSize: 16,
                                          fontWeight:
                                          FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardRow(String emoji, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}