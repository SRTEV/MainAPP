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
    this.startDate,
    this.endDate,
  });

  factory UserResultModel.fromJson(Map<String, dynamic> json) {
    return UserResultModel(
      id: json['id'],
      userId: json['userId'],
      competitionId: json['competitionId'],
      score: json['score'],
      rank: json['rank'],
      rewardAmount: json['rewardAmount'],
      rewardName: json['rewardName'],
      rewardUnit: json['rewardUnit'],
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
  String? challengeTypeName; // Додано для типу челенджу з goalTypes (наприклад, Marathon)
  bool isEnded = false;

  List<dynamic> goalTypes = [];
  List<dynamic> rewardTypes = [];
  List<dynamic> leaderboard = [];

  UserResultModel? currentUserResult;

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

        // Витягуємо назву типу челенджу з масиву goalTypes
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
      String token,) async {
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

  Future<void> fetchUserResult(String token, int userId,
      int challengeId) async {
    try {
      final response = await http.get(
        Uri.parse('$serverApi/api/Competition/UserResult/$userId/$challengeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        currentUserResult = UserResultModel.fromJson(data);
        notifyListeners();
      } else {
        currentUserResult = null;
        print("Failed to load user result: ${response.statusCode}");
      }
    } catch (e) {
      currentUserResult = null;
      print("Error fetching user result: $e");
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
  }
}