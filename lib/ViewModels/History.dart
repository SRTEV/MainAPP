import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mainapp/Controllers/AuthController.dart';
import 'package:mainapp/Controllers/RentalController.dart';
import 'package:provider/provider.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  _HistoryState createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    final rentalController = Provider.of<RentalController>(
      context,
      listen: false,
    );
    final authController = Provider.of<AuthController>(context, listen: false);

    _historyFuture = rentalController.FetchRentalHistory(
      authController.userId!,
      authController.token!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_circle_left_outlined,
                      size: 36,
                      color: Colors.black,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Travel history',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: const BoxDecoration(
                  color: Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: FutureBuilder<List<dynamic>>(
                  future: _historyFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.black),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'Failed to load history data',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'History is empty',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    }

                    final historyItems = snapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.all(20.0),
                      itemCount: historyItems.length,
                      itemBuilder: (context, index) {
                        final item =
                            historyItems[index] as Map<String, dynamic>;
                        final vehicle =
                            item['vehicle'] as Map<String, dynamic>? ?? {};
                        final vehicleType = vehicle['vehicleTypeId'];

                        final distance = '${item['distance'] ?? 0} km';
                        final dateTime = item['endTime'] != null
                            ? DateTime.parse(
                                item['endTime'],
                              ).toLocal().toString().substring(0, 16)
                            : '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: _buildHistoryCard(
                            imagePath: _getIconForVehicleType(vehicleType),
                            distance: distance,
                            dateTime: dateTime,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getIconForVehicleType(dynamic id) {
    switch (id.toString().trim()) {
      case '1':
        return 'lib/assets/imgs/S.png';
      case '2':
        return 'lib/assets/imgs/Wheel.png';
      case '3':
        return 'lib/assets/imgs/Bicycle.png';
      default:
        return 'lib/assets/imgs/S.png';
    }
  }

  Widget _buildHistoryCard({
    required String imagePath,
    required String distance,
    required String dateTime,
  }) {
    return Container(
      height: 125,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 14,
            left: 20,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 14,
            right: 20,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 6),
                Row(
                  children: [
                    Image.asset(imagePath, width: 64, height: 64),
                    const SizedBox(width: 16),
                    Text(
                      distance,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    dateTime,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
