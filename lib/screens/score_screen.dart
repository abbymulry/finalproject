import 'package:flutter/material.dart';
import '../models/player.dart';

// Color palette for the updated UI
class Phase10Colors {
  static const Color primaryBlue = Color(0xFF2D6BE0);
  static const Color accentOrange = Color(0xFFF7A928); 
  static const Color backgroundGrey = Color(0xFFF8F9FA);
  static const Color darkText = Color(0xFF212529);
  static const Color lightGrey = Color(0xFFE9ECEF);
  static const Color mediumGrey = Color(0xFFADB5BD);
}

class ScorePage extends StatefulWidget {
  const ScorePage({super.key});
  
  @override
  _ScorePageState createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final Map<Player, TextEditingController> _scoreControllers = {};
  final Map<Player, bool> _phaseCompleted = {};
  final List<Player> _players = [];
  final List<Previous> _previousEntries = [];
  bool undoUsed = true;
  
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    // Setup animation for UI elements
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutQuad,
    );
    
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var c in _scoreControllers.values) {
      c.dispose();
    }
    _animController.dispose();
    super.dispose();
  }

  void _addPlayer() {
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
    
    // Reset animation for nice visual effect when adding new player
    _animController.reset();
    
    setState(() {
      final newPlayer = Player(id: '0', name: name);
      _players.add(newPlayer);
      _scoreControllers[newPlayer] = TextEditingController();
      _phaseCompleted[newPlayer] = false;
      _nameController.clear();
      _previousEntries.add(Previous(playerIndex: _players.length - 1));
    });
    
    _animController.forward();
  }

  void _submitRound() {
    // Validate inputs
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
    
    setState(() {
      for(int i = 0; i < _players.length; i++) {
        if(_players[i].currentPhase < 11) {
          _previousEntries[i].currentPhase = _players[i].currentPhase;
          _previousEntries[i].score = _players[i].score;
          final scoreText = _scoreControllers[_players[i]]?.text??'';
          final score = int.tryParse(scoreText) ?? 0;
          _players[i].score += score;
          if(_phaseCompleted[_players[i]] == true) {
            _players[i].currentPhase += 1;
          }
          _scoreControllers[_players[i]]?.clear();
          _phaseCompleted[_players[i]] = false;
        }
      }
      undoUsed = false;
    });
    
    // Show success message
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

  void _undoSubmit() {
    setState(() {
      for(int i = 0; i < _players.length; i++) {
        _players[i].currentPhase = _previousEntries[i].currentPhase;
        _players[i].score = _previousEntries[i].score;
      }
      undoUsed = true;
    });
    
    // Show undo message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Last round undone'),
        backgroundColor: Phase10Colors.accentOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  // Get phase description
  String _getPhaseDescription(int phaseNumber) {
    switch (phaseNumber) {
      case 1:
        return "2 sets of 3";
      case 2:
        return "1 set of 3 + 1 run of 4";
      case 3:
        return "1 set of 4 + 1 run of 4";
      case 4:
        return "1 run of 7";
      case 5:
        return "1 run of 8";
      case 6:
        return "1 run of 9";
      case 7:
        return "2 sets of 4";
      case 8:
        return "7 cards of one color";
      case 9:
        return "1 set of 5 + 1 set of 2";
      case 10:
        return "1 set of 5 + 1 set of 3";
      default:
        return "All phases complete!";
    }
  }

  // Find the leader among players
  Player? _findLeader() {
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

  @override
  Widget build(BuildContext context) {
    final leader = _findLeader();
    
    return Scaffold(
      backgroundColor: Phase10Colors.backgroundGrey,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.scoreboard, color: Phase10Colors.primaryBlue, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Phase 10 Score Tracker',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Phase10Colors.darkText,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    leader != null 
                      ? Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Phase10Colors.accentOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Phase10Colors.accentOrange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.emoji_events,
                                color: Phase10Colors.accentOrange,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      color: Phase10Colors.darkText,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '${leader.name} ',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: 'is in the lead with Phase ${leader.currentPhase}',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : SizedBox.shrink(),
                  ],
                ),
              ),
              
              SizedBox(height: 16),
              
              // Add player section
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Player',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Phase10Colors.darkText,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Phase10Colors.backgroundGrey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: 'Enter player name',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                              ),
                              onSubmitted: (_) => _addPlayer(),
                              style: TextStyle(
                                fontSize: 16,
                                color: Phase10Colors.darkText,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _addPlayer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Phase10Colors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          child: Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 16),
              
              // Player List
              Expanded(
                child: _players.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_alt_outlined,
                              size: 64,
                              color: Phase10Colors.mediumGrey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No players yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Phase10Colors.mediumGrey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add players to start tracking scores',
                              style: TextStyle(
                                fontSize: 14,
                                color: Phase10Colors.mediumGrey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _players.length,
                        itemBuilder: (_, index) {
                          final player = _players[index];
                          return AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: Offset(0.1, 0),
                                    end: Offset.zero,
                                  ).animate(_animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Player header section
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: player == leader
                                          ? Phase10Colors.accentOrange.withOpacity(0.1)
                                          : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                      border: player == leader
                                          ? Border.all(
                                              color: Phase10Colors.accentOrange.withOpacity(0.3),
                                              width: 1,
                                            )
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Phase10Colors.primaryBlue.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              player.name.substring(0, 1).toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Phase10Colors.primaryBlue,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                player.name,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Phase10Colors.darkText,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Phase10Colors.primaryBlue.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      'Phase ${player.currentPhase}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: Phase10Colors.primaryBlue,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Phase10Colors.accentOrange.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      'Score: ${player.score}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: Phase10Colors.accentOrange,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (player.currentPhase <= 10)
                                                Container(
                                                  margin: EdgeInsets.only(top: 8),
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Phase10Colors.lightGrey,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    _getPhaseDescription(player.currentPhase),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Phase10Colors.darkText.withOpacity(0.7),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (player == leader)
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Phase10Colors.accentOrange,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.emoji_events,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Score input section
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Phase10Colors.backgroundGrey,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: TextField(
                                              controller: _scoreControllers[player],
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(
                                                hintText: 'Enter score for this round',
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                              ),
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Phase10Colors.darkText,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          flex: 2,
                                          child: Row(
                                            children: [
                                              Checkbox(
                                                value: _phaseCompleted[player],
                                                onChanged: (value) {
                                                  setState(() {
                                                    _phaseCompleted[player] = value ?? false;
                                                  });
                                                },
                                                activeColor: Phase10Colors.primaryBlue,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  "Phase Complete",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Phase10Colors.darkText,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              
              // Bottom action buttons
              if (_players.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(top: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: (!undoUsed) ? () => _undoSubmit() : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Phase10Colors.accentOrange,
                          disabledForegroundColor: Colors.grey.withOpacity(0.5),
                          disabledBackgroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: (!undoUsed) 
                                ? Phase10Colors.accentOrange
                                : Colors.grey.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.undo, size: 18),
                            SizedBox(width: 8),
                            Text("Undo"),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _submitRound(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Phase10Colors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 18),
                            SizedBox(width: 8),
                            Text("Submit Round"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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