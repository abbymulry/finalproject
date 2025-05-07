import 'package:flutter/material.dart';
import '../models/score.dart';
import '../services/score_session.dart';

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
  var scoreInstance = Score(null);
  final _scoreSession = ScoreSession();
  late AnimationController _animController;
  late Animation<double> _animation;
  bool _newScoreSheet = false;
  bool _oldScoreSheet = false;
  bool _isLoading = false;
  bool _hasScore = false;
  
  @override
  void initState() {
    super.initState();
    _checkForSavedScore();
    
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
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkForSavedScore() async {
    setState(() {
      _isLoading = true;
    });

    bool hasScore = await _scoreSession.loadScoreForCurrentUser();

    setState(() {
      _hasScore = hasScore;
      _isLoading = false;
    });
  }

  Future<void> _saveScore() async {
    try{
      setState(() {
        _isLoading = true;
      });

      await _scoreSession.createNewScore(scoreInstance.players);

      setState((){
        _hasScore = true;
        _isLoading = false;
      });
    }
    catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving score: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isLoading = false;
        });
    }
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
    return Scaffold(
      appBar: AppBar(
        title: _newScoreSheet 
            ? Text(
              'New Score Sheet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Phase10Colors.darkText,
              ),
            )
            : _oldScoreSheet
            ? Text("Previous Score Sheet")
            : null,
            centerTitle: true,
      leading: (_newScoreSheet || _oldScoreSheet) ?  IconButton(
        onPressed: () {
        setState(() {
          _newScoreSheet = false;
          _oldScoreSheet = false;
        });
        }, 
        icon: Icon(Icons.arrow_back))
        : null,
      ),
      backgroundColor: Phase10Colors.backgroundGrey,
      body: SafeArea(
        child: Center(
          child: _newScoreSheet
          ? _buildScoreSheet()
          : _oldScoreSheet 
          ? _viewOldScoreSheet()
          : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _newScoreSheet = true;
                      // _hasScore = true;
                    });
                  },
                  style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        Colors.lightBlue[100],
                      ),
                    ),
                  child: Text("Open Score Sheet"),
                ),
                ElevatedButton(
                  onPressed: () {
                    // if(_hasScore)
                    // {
                      setState(() {
                        _oldScoreSheet = true;
                      });
                    // }
                  },
                  style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        Colors.lightBlue[100],
                      ),
                    ),
                  child: Text("View Previous Score Sheet"),
                )
          ],
        ),
        ),
      ),
    );
  }

  Widget _viewOldScoreSheet()
  {
    return Column(
      children: [],
    );
  }

  Widget _buildScoreSheet() {
    final leader = scoreInstance.findLeader(); // Ensure leader is defined here
    return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                              margin: EdgeInsets.only(bottom: 10),
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
                                                  if (player.currentPhase <= 10)
                                                  Container(
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
                          onPressed: () {
                            if (scoreInstance.nameController.text.trim().isEmpty) {
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
                            } 
                            else {
                              setState(() {
                                _animController.reset();
                                scoreInstance.addPlayer(context);
                                _animController.forward();
                              });
                            }
                          },
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
              
              // Bottom action buttons
              if (scoreInstance.players.isNotEmpty)
                Container(
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
                        onPressed: () {
                          if (!scoreInstance.undoUsed) {
                            setState(() {
                              scoreInstance.undoSubmit(context);
                            });
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
                          else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please submit a round before pressing undo'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !scoreInstance.undoUsed
                          ? Phase10Colors.primaryBlue
                          : Colors.white,
                          foregroundColor: !scoreInstance.undoUsed
                          ? Colors.white
                          : Colors.red,
                          disabledForegroundColor: Colors.grey.withOpacity(0.5),
                          disabledBackgroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: (!scoreInstance.undoUsed) 
                                ? Phase10Colors.primaryBlue
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
                        onPressed: () => {
                          setState((){
                            scoreInstance.submitRound(context);
                            }),
                            ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Round submitted successfully!'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        },
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
                      ElevatedButton(onPressed: (){
                        _saveScore();
                      }, 
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
                            Icon(Icons.save, size: 18),
                            SizedBox(width: 8),
                            Text("Save"),
                          ],
                        ),),
                    ],
                  ),
                ),
            ],
          );
  }
}