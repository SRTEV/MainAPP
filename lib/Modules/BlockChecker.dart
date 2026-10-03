import 'package:flutter/material.dart';
import 'package:mainapp/Controllers/AuthController.dart';
import 'package:mainapp/Controllers/UserController.dart';
import 'package:provider/provider.dart';

import '../ViewModels/Blocked.dart';

class BlockChecker {
  static Future<bool> check(BuildContext context) async {
    final userController = Provider.of<UserController>(context, listen: false);

    final authController = Provider.of<AuthController>(context, listen: false);

    final userId = authController.userId;
    final token = authController.token;

    if (userId == null || token == null) {
      return false;
    }

    try {
      await userController.fetchUserName(userId, token);

      if (userController.isBlocked == true) {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Blocked()),
          );
        }

        return true;
      }
    } catch (e) {
      debugPrint('Block status check error: $e');
    }

    return false;
  }
}
