import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../Controllers/AuthController.dart';
import '../Controllers/Controller.dart';
import '../Controllers/UserController.dart';
import '../Modules/Notifications.dart';

class Reportwork extends StatefulWidget {
  final dynamic vehicle;
  final int? vehicleId;
  final String? vehicleType;
  final String? vehicleModel;
  final String? email;

  const Reportwork({
    super.key,
    this.vehicle,
    this.vehicleId,
    this.vehicleType,
    this.vehicleModel,
    this.email,
  });

  @override
  State<Reportwork> createState() => ReportworkState();
}

class ReportworkState extends State<Reportwork> {
  final TextEditingController _reportController = TextEditingController();
  int _reportNumber = 1;
  bool _isLoadingNumber = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserReportCount();
    });
  }

  Future<void> _fetchUserReportCount() async {
    try {
      final authController = context.read<AuthController>();
      final userController = context.read<UserController>();

      final token = authController.token ?? "";
      if (token.isNotEmpty) {
        int count = await userController.RepeirmanReportCount(token);

        if (mounted) {
          setState(() {
            _reportNumber = count + 1;
            _isLoadingNumber = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingNumber = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching report count: $e");
      if (mounted) {
        setState(() {
          _isLoadingNumber = false;
        });
      }
    }
  }

  void _hideKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  Widget build(BuildContext context) {
    final userController = context.watch<UserController>();
    final authController = context.watch<AuthController>();
    final vehicleController = context.read<Controller>();

    const String reportCategory = 'Repairman';

    final int? currentId = widget.vehicle?.id ?? widget.vehicleId;
    final String currentType =
        widget.vehicle?.type ?? widget.vehicleType ?? 'Vehicle';

    final rawModel = widget.vehicle?.model ?? widget.vehicleModel;
    final String currentModel =
        (rawModel != null && rawModel.toString().isNotEmpty)
        ? rawModel.toString()
        : (currentId?.toString() ?? '1');

    return GestureDetector(
      onTap: _hideKeyboard,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
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
                              const SizedBox(width: 15),
                              Text(
                                "Report",
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Плашка "Repair Report" на всю ширину
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBEBEB),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.black,
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              "Repair Report",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Головний сірий блок на всю довжину завдяки Expanded всередині IntrinsicHeight
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBEBEB),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 8),
                                  // Номер, тип та модель по центру
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      _isLoadingNumber
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.black,
                                              ),
                                            )
                                          : Text(
                                              "Report No. $_reportNumber",
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.black,
                                              ),
                                            ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Type: $currentType",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Model: $currentModel",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  // Текстове поле на всю решту висоти сірого блоку
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _reportController,
                                        maxLines: null,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.all(
                                            16,
                                          ),
                                          border: InputBorder.none,
                                          hintText:
                                              'Battery charged; vehicle ready for use',
                                          hintStyle: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Чорна кнопка "Send"
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed: () async {
                                _hideKeyboard();

                                final String userTypedText = _reportController
                                    .text
                                    .trim();

                                if (userTypedText.isEmpty ||
                                    userTypedText.length <= 3) {
                                  if (context.mounted) {
                                    showTopNotification(
                                      context,
                                      "The report description must be longer than 3 characters and cannot be empty!",
                                    );
                                  }
                                  return;
                                }

                                final String fullReportText =
                                    "Report No: $_reportNumber | Type: $currentType | Model: $currentModel | Text: $userTypedText";

                                final String? userEmail =
                                    widget.email ?? userController.userEmail;

                                String? result = await userController
                                    .giveMeHeplPlease(
                                      fullReportText,
                                      reportCategory,
                                      currentId,
                                      userEmail,
                                      userController.tempId,
                                    );

                                if (currentId != null) {
                                  final token = authController.token;
                                  if (token != null) {
                                    await vehicleController.EndRemont(
                                      currentId,
                                      token,
                                    );
                                  }
                                }

                                if (context.mounted) {
                                  Navigator.pop(
                                    context,
                                    result ?? "Report submitted successfully!",
                                  );
                                }
                              },
                              child: Text(
                                "Send",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
