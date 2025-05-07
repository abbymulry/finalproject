import 'package:flutter/material.dart';
import '../models/player.dart';


class Score {
  final TextEditingController _nameController = TextEditingController();

  Score(List<Player>? players) {
    if(players != null)
    {
      _players.addAll(players);
    }
  }

  final Map<Player, TextEditingController> _scoreControllers = {};
  final Map<Player, bool> _phaseCompleted = {};
  final List<Player> _players = [];
  final List<Previous> _previousEntries = [];
  bool _undoUsed = true;
  DateTime lastUpdated = DateTime.now();

  TextEditingController get nameController => _nameController;
  List<Player> get players => _players;
  Map <Player, TextEditingController> get scoreControllers => _scoreControllers;
  Map <Player, bool> get phaseCompleted => _phaseCompleted;
  bool get undoUsed => _undoUsed; 


  void addPlayer(BuildContext context) {
    final name = _nameController.text.trim();

    final newPlayer = Player(id: '0', name: name);
      _players.add((newPlayer));
      _scoreControllers[newPlayer] = TextEditingController();
      _phaseCompleted[newPlayer] = false;
      _nameController.clear();
      _previousEntries.add(Previous(playerIndex: _players.length - 1));
  }

  void submitRound(BuildContext context) {
      for(int i = 0; i < _players.length; i++)
      {
        if(_players[i].currentPhase < 11)
        {
          _previousEntries[i].currentPhase = _players[i].currentPhase;
          _previousEntries[i].score = _players[i].score;
          final scoreText = _scoreControllers[_players[i]]?.text??'';
          final score = int.tryParse(scoreText) ?? 0;
          _players[i].score += score;
          if(_phaseCompleted[_players[i]] == true)
          {
            _players[i].currentPhase += 1;
          }
          _scoreControllers[_players[i]]?.clear();
          _phaseCompleted[_players[i]] = false;
        }
      }
      _undoUsed = false;
  }

  void undoSubmit(BuildContext context){
      for(int i = 0; i < _players.length; i++)
      {
        _players[i].currentPhase = _previousEntries[i].currentPhase;
        _players[i].score = _previousEntries[i].score;
      }
      
      _undoUsed = true;
  } 

  // Find the leader among players
  Player? findLeader() {
    if (_players.isEmpty) return null;
    
    Player leader = _players[0];
    for (var player in _players) {
      if (player.currentPhase > leader.currentPhase) {
        leader = player;
      } else if (player.currentPhase == leader.currentPhase && player.score < leader.score) {
        leader = player;
      }
    }
    return leader;
  }

  Map<String, dynamic> toJson() {
      return {
        'players': _players.map((p) => p.toJson()).toList()
      };
   }

  factory Score.fromJson(Map<String, dynamic> json){
      final score = Score(null);
      if (json['players'] != null) {
      score._players.addAll(
        (json['players'] as List)
            .map((p) => Player.fromJson(p as Map<String, dynamic>))
            .toList(),
        );
      }
      return score;
  }
}

class Previous {
  final int playerIndex;
  int currentPhase;
  int score;

  Previous({
    required this.playerIndex,
    this.currentPhase = 1,
    this.score = 0,
  });
}
