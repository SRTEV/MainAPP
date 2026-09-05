import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class UserResultModel {
  final int id;
  final int userId;
  final int competitionId;
  final int score;
  final int rank;
  final int rewardAmount;
  final String rewardName;
  final String rewardUnit;
  final String challengeTypeName; // Додано
  final String vehicleTypeName; // Додано
  final String? startDate;
  final String? endDate;

  UserResultModel({
    required this.id,
    required this.userId,
    required this.competitionId,
    required this.score,
    required this.rank,
    required this.rewardAmount,
    required this.rewardName,
    required this.rewardUnit,
    required this.challengeTypeName,
    required this.vehicleTypeName,
    this.startDate,
    this.endDate,
  });

  factory UserResultModel.fromJson(Map<String, dynamic> json) {
    return UserResultModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      competitionId: json['competitionId'] ?? 0,
      score: json['score'] ?? 0,
      rank: json['rank'] ?? 0,
      rewardAmount: json['rewardAmount'] ?? 0,
      rewardName: json['rewardName'] ?? 'No reward',
      rewardUnit: json['rewardUnit'] ?? '0',
      challengeTypeName: json['challengeTypeName'] ?? 'Challenge',
      vehicleTypeName: json['vehicleTypeName'] ?? '',
      startDate: json['startDate'],
      endDate: json['endDate'],
    );
  }
}

class Challangecontroller extends ChangeNotifier {
  String get serverApi => dotenv.env['SERVER']!;

  bool isLoading = false;
  String message = '';
  int? competitionId;
  String? startDate;
  String? endDate;
  String? description;
  int? goalValue;
  int? vehicleTypeId;
  String? vehicleTypeName;
  String? challengeTypeName;
  bool isEnded = false;

  List<dynamic> goalTypes = [];
  List<dynamic> rewardTypes = [];
  List<dynamic> leaderboard = [];

  UserResultModel? currentUserResult;
  List<UserResultModel> allUserResults = [];

  Future<void> fetchLatestChallenge(int vehicleTypeId, String token) async {
    isLoading = true;
    message = '';
    notifyListeners();

    final url = Uri.parse('$serverApi/api/Competition/latest/$vehicleTypeId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        competitionId = data['id'];
        startDate = data['startDate'];
        endDate = data['endDate'];
        description = data['description'];
        goalValue = data['goalValue'];
        this.vehicleTypeId = data['vehicleTypeId'];
        vehicleTypeName = data['vehicleTypeName'];
        isEnded = data['isEnded'] ?? false;
        goalTypes = data['goalTypes'] ?? [];
        rewardTypes = data['rewardTypes'] ?? [];

        if (goalTypes.isNotEmpty && goalTypes[0] is Map) {
          challengeTypeName = goalTypes[0]['name'];
        } else {
          challengeTypeName = "Challenge";
        }

        message = '';
        if (competitionId != null) {
          await _fetchLeaderboardInternal(competitionId!, token);
        }
      } else if (response.statusCode == 404) {
        _clearCompetitionData();
        message = "No challenges yet";
      } else {
        message = "Failed to load competition: ${response.statusCode}";
      }
    } catch (e) {
      message = "Network error fetching competition: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLeaderboard(int competitionId, String token) async {
    await _fetchLeaderboardInternal(competitionId, token);
    notifyListeners();
  }

  Future<void> _fetchLeaderboardInternal(int competitionId,
      String token) async {
    final url = Uri.parse(
      '$serverApi/api/UsersResult/leaderboard/$competitionId',
    );
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        leaderboard = data;
      } else if (response.statusCode == 404) {
        leaderboard = [];
      } else {
        leaderboard = [];
        message = "Failed to load leaderboard: ${response.statusCode}";
      }
    } catch (e) {
      leaderboard = [];
      message = ("Network error fetching leaderboard: $e");
    }
  }

  Future<void> fetchAllUserResults(String token, int userId) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$serverApi/api/Competition/UserResults/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        allUserResults =
            data.map((item) => UserResultModel.fromJson(item)).toList();

        // Сортування: спочатку невикористані (rewardAmount > 0), потім за свіжішою датою
        allUserResults.sort((a, b) {
          final bool isUnusedA = a.rewardAmount > 0;
          final bool isUnusedB = b.rewardAmount > 0;

          // Якщо одна нагорода використана, а інша ні — невикористана йде вище
          if (isUnusedA != isUnusedB) {
            return isUnusedB ? 1 : -1;
          }

          // Якщо статус однаковий — сортуємо за датою (найновіші перші)
          final dateA = DateTime.tryParse(a.startDate ?? '') ?? DateTime(2000);
          final dateB = DateTime.tryParse(b.startDate ?? '') ?? DateTime(2000);

          return dateB.compareTo(dateA);
        });

      } else {
        allUserResults = [];
        print("Failed to load user results: ${response.statusCode}");
      }
    } catch (e) {
      allUserResults = [];
      print("Error fetching user results: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  void _clearCompetitionData() {
    competitionId = null;
    startDate = null;
    endDate = null;
    description = null;
    goalValue = null;
    vehicleTypeId = null;
    vehicleTypeName = null;
    challengeTypeName = null;
    isEnded = false;
    goalTypes = [];
    rewardTypes = [];
    leaderboard = [];
    currentUserResult = null;
    allUserResults = [];
  }
}