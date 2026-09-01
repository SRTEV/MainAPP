import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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
  bool isEnded = false;

  List<dynamic> goalTypes = [];
  List<dynamic> rewardTypes = [];
  List<dynamic> leaderboard = [];

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

  Future<void> _fetchLeaderboardInternal(
    int competitionId,
    String token,
  ) async {
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

  void _clearCompetitionData() {
    competitionId = null;
    startDate = null;
    endDate = null;
    description = null;
    goalValue = null;
    vehicleTypeId = null;
    vehicleTypeName = null;
    isEnded = false;
    goalTypes = [];
    rewardTypes = [];
    leaderboard = [];
  }
}
