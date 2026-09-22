import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mainapp/Controllers/Controller.dart';
import 'package:mainapp/Controllers/UserController.dart';
import 'package:provider/provider.dart';

class AdminCallsPage extends StatefulWidget {
  final String token;

  const AdminCallsPage({super.key, required this.token});

  @override
  State<AdminCallsPage> createState() => _AdminCallsPageState();
}

class _AdminCallsPageState extends State<AdminCallsPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userController = context.read<UserController>();
      final vehicleController = context.read<Controller>();

      await Future.wait([
        userController.fetchAdminCalls(widget.token),
        vehicleController.fetchVehicles(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userController = context.watch<UserController>();
    final vehicleController = context.watch<Controller>();

    final reports = userController.adminCallsList;
    final isLoading = userController.isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.arrow_circle_left_outlined,
                        size: 36,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  Text(
                    'Admin calls',
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
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade400, width: 1.5),
                  ),
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.black),
                        )
                      : reports.isEmpty
                      ? Center(
                          child: Text(
                            'No admin calls found',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: reports.length,
                          itemBuilder: (context, index) {
                            final report = reports[index];

                            final vehicleId = int.tryParse(
                              '${report['vehicleId']}',
                            );

                            VehicleModel? vehicle;

                            for (final v in vehicleController.vehicles) {
                              if (v.id == vehicleId) {
                                vehicle = v;
                                break;
                              }
                            }

                            final vehicleName = vehicle != null
                                ? vehicle.model
                                : 'Vehicle #${vehicleId ?? ''}';

                            final reportText =
                                report['text'] ?? 'No description provided';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.zero,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1.8,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        vehicleName,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 10,
                                          right: 35,
                                        ),
                                        child: Text(
                                          reportText.toString(),
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.black54,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: InkWell(
                                      onTap: vehicle == null
                                          ? null
                                          : () {
                                              Navigator.of(
                                                context,
                                              ).pop(vehicle);
                                            },
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.pin_drop,
                                          size: 24,
                                          color: vehicle == null
                                              ? Colors.grey
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
