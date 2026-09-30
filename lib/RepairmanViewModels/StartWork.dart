import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mainapp/Controllers/AuthController.dart';
import 'package:provider/provider.dart';

import '../Controllers/Controller.dart';
import 'AdminCalls.dart';

class Startwork extends StatefulWidget {
  const Startwork({super.key});

  @override
  State<Startwork> createState() => _StartworkState();
}

class _StartworkState extends State<Startwork> {
  int _selectedTab = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = context.read<Controller>();

      await controller.fetchVehicles();
      controller.startVehiclePolling();

      await controller.loadAddressesForVehicles(controller.vehicles);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Controller>(
      builder: (BuildContext context,
          Controller vehicleController,
          Widget? child,) {
        if (!_isLoading) {
          vehicleController.loadAddressesForVehicles(
            vehicleController.vehicles,
          );
        }

        // Charging:
        // NeedCheck + battery < 15%
        final chargingList =
        vehicleController.vehicles.where((v) {
          final statusLower = v.status.toLowerCase();
          final battery = v.batteryLevel;

          return statusLower.contains('needcheck') &&
              battery < 15;
        }).toList();

        final remontList =
        vehicleController.vehicles.where((v) {
          final statusLower = v.status.toLowerCase();
          final battery = v.batteryLevel;

          final bool isNeedCheckHighBattery =
              statusLower.contains('needcheck') &&
                  battery >= 15;

          return isNeedCheckHighBattery;
        }).toList();

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints:
                        const BoxConstraints(),
                        icon: const Icon(
                          Icons.arrow_circle_left_outlined,
                          size: 36,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "Start work",
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius:
                        BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedTab = 0;
                                      });
                                    },
                                    child: Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      alignment:
                                      Alignment.center,
                                      decoration: BoxDecoration(
                                        color:
                                        _selectedTab == 0
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius:
                                        BorderRadius.circular(
                                          10,
                                        ),
                                      ),
                                      child: Text(
                                        "Charging (${chargingList.length})",
                                        style:
                                        GoogleFonts.poppins(
                                          fontWeight:
                                          FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedTab = 1;
                                      });
                                    },
                                    child: Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      alignment:
                                      Alignment.center,
                                      decoration: BoxDecoration(
                                        color:
                                        _selectedTab == 1
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius:
                                        BorderRadius.circular(
                                          10,
                                        ),
                                      ),
                                      child: Text(
                                        "Remont (${remontList.length})",
                                        style:
                                        GoogleFonts.poppins(
                                          fontWeight:
                                          FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          Expanded(
                            child: _isLoading
                                ? const Center(
                              child:
                              CircularProgressIndicator(
                                color: Colors.black,
                              ),
                            )
                                : _selectedTab == 0
                                ? _buildVehicleList(
                              chargingList,
                              context,
                              vehicleController,
                            )
                                : _buildVehicleList(
                              remontList,
                              context,
                              vehicleController,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVehicleList(List<VehicleModel> items,
      BuildContext context,
      Controller vehicleController,) {
    if (items.isEmpty) {
      // Беремо AuthController тут, а не всередині children.
      final auth = context.read<AuthController>();

      return Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Text(
              "There are no vehicles with a system-reported malfunction",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AdminCallsPage(
                          token: auth.token!,
                        ),
                  ),
                );
              },
              child: Text(
                "Check the administrator's call",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.blue.shade700,
                  decoration:
                  TextDecoration.underline,
                  decorationColor: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final vehicle = items[index];

        final address =
            vehicleController.addressCache[vehicle.id] ??
                "Loading address...";

        return Container(
          margin:
          const EdgeInsets.only(bottom: 12),
          padding:
          const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade400,
            ),
          ),
          child: Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${vehicle.type} "
                          "${vehicle.model ?? vehicle.id}",
                      style: GoogleFonts.poppins(
                        fontWeight:
                        FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      address,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color:
                        Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              GestureDetector(
                onTap: () {
                  Navigator.of(context)
                      .pop(vehicle);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration:
                  const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "GO",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}