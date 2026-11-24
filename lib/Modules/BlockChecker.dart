import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mainapp/Controllers/AuthController.dart';
import 'package:mainapp/Controllers/UserController.dart';
import 'package:provider/provider.dart';

import '../ViewModels/Blocked.dart';

class BlockChecker {
  // Kod zwracany przez serwer (HTTP 403, pole errorCode), gdy konto jest zablokowane.
  static const String blockedErrorCode = 'account_blocked';

  // Zwraca powód blokady, jeśli odpowiedź serwera oznacza zablokowane konto, w przeciwnym razie null.
  static String? blockedReasonFrom(int statusCode, String body) {
    if (statusCode != 403) return null;
    try {
      final data = json.decode(body);
      if (data is Map && data['errorCode'] == blockedErrorCode) {
        return (data['blockedReason'] as String?) ?? '';
      }
    } catch (_) {}
    return null;
  }

  // Otwiera istniejącą stronę blokady i usuwa poprzednie ekrany, aby użytkownik nie mógł wrócić dalej.
  static void openBlockedPage(BuildContext context, String? reason) {
    final userController = Provider.of<UserController>(context, listen: false);
    userController.isBlocked = true;
    userController.banReason = reason;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Blocked()),
      (route) => false,
    );
  }

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
