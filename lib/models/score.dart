import 'package:flutter/material.dart';
import '../models/player.dart';

class Score{
  final TextEditingController _nameController = TextEditingController();
  final Map<Player, TextEditingController> _scoreControllers = {};
  final Map<Player, bool> _phaseCompleted = {};
  final List<Player> _players = [];
  final List<Previous> _previousEntries = [];
  late AnimationController _animController;
  late Animation<double> _animation;

  TextEditingController get nameController => _nameController;
  List<Player> get players => _players;
  Map <Player, TextEditingController> get scoreControllers => _scoreControllers;
  Map <Player, bool> get phaseCompleted => _phaseCompleted;
  AnimationController get animController => _animController;
  Animation<double> get animation => _animation;  

  set animController(AnimationController controller) => _animController = controller;
  set animation(Animation<double> animation) => _animation = animation;


  void addPlayer(BuildContext context) {
    final name = _nameController.text.trim();
    if(name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a player name'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    _animController.reset();

    final newPlayer = Player(id: '0', name: name);
      _players.add((newPlayer));
      _scoreControllers[newPlayer] = TextEditingController();
      _phaseCompleted[newPlayer] = false;
      _nameController.clear();
      _previousEntries.add(Previous(playerIndex: _players.length - 1));

      _animController.forward();
  }

  void submitRound(BuildContext context) {
      bool allValid = true;
      for (var player in _players) {
        final scoreText = _scoreControllers[player]?.text ?? '';
        if (scoreText.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please enter a score for ${player.name}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          allValid = false;
          break;
        }
    }
    
    if (!allValid) return;
    
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
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Round submitted successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void undoSubmit(BuildContext context){
      for(int i = 0; i < _players.length; i++)
      {
        _players[i].currentPhase = _previousEntries[i].currentPhase;
        _players[i].score = _previousEntries[i].score;
      }

      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Last round undone'),
        backgroundColor: Color(0xFFF7A928),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
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

  // convert game to json for network transmission
  // Map<String, dynamic> toJson() {
  //   return {
  //     'id': id,
  //     'players': players.map((p) => p.toJson()).toList(),
  //     'deck': _deckObject.cards.map((c) => c.toJson()).toList(),
  //     'discardPile': discardPile.map((c) => c.toJson()).toList(),
  //     'currentPlayerIndex': currentPlayerIndex,
  //     'state': state.index,
  //     'lastUpdated': lastUpdated.toIso8601String(),
  //   };
  // }
  
  // // create game from json for network transmission
  // factory Game.fromJson(Map<String, dynamic> json) {
  //   // create a deck object from the cards
  //   List<Card> deckCards = (json['deck'] as List).map((c) => Card.fromJson(c as Map<String, dynamic>)).toList();

  //   Deck deck = Deck.fromCards(deckCards);

  //   return Game(
  //     id: json['id'],
  //     players: (json['players'] as List).map((p) => Player.fromJson(p as Map<String, dynamic>)).toList(),
  //     deck: deck,
  //     discardPile: (json['discardPile'] as List).map((c) => Card.fromJson(c as Map<String, dynamic>)).toList(),
  //     currentPlayerIndex: json['currentPlayerIndex'],
  //     state: GameState.values[json['state']],
  //   );
  // }
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
