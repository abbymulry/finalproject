import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/score.dart';

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
  bool undoUsed = true;
  var scoreInstance = Score();
  
  @override
  void initState() {
    super.initState();
    
    // Setup animation for UI elements
    scoreInstance.animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    scoreInstance.animation = CurvedAnimation(
      parent: scoreInstance.animController,
      curve: Curves.easeOutQuad,
    );
    
    scoreInstance.animController.forward();
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

  @override
  Widget build(BuildContext context) {
    final leader = scoreInstance.findLeader();
    
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
                              controller: scoreInstance.nameController,
                              decoration: InputDecoration(
                                hintText: 'Enter player name',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                              ),
                              onSubmitted: (_) => scoreInstance.addPlayer,
                              style: TextStyle(
                                fontSize: 16,
                                color: Phase10Colors.darkText,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => setState((){
                            scoreInstance.addPlayer(context);
                          }),
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
                child: scoreInstance.players.isEmpty
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
                        itemCount: scoreInstance.players.length,
                        itemBuilder: (_, index) {
                          final player = scoreInstance.players[index];
                          return AnimatedBuilder(
                            animation: scoreInstance.animation,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: scoreInstance.animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: Offset(0.1, 0),
                                    end: Offset.zero,
                                  ).animate(scoreInstance.animation),
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
                                              controller: scoreInstance.scoreControllers[player],
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
                                                value: scoreInstance.phaseCompleted[player],
                                                onChanged: (value) {
                                                  setState(() {
                                                    scoreInstance.phaseCompleted[player] = value ?? false;
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
              if (scoreInstance.players.isNotEmpty)
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
                        onPressed: (!undoUsed) ? () => setState((){
                          scoreInstance.undoSubmit(context);
                          undoUsed = true;
                        }) : null,
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
                        onPressed: () => setState(() {
                          scoreInstance.submitRound(context);
                        }),
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