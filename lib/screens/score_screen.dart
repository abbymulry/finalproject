import 'package:flutter/material.dart';
import '../models/score.dart';
import '../services/score_session.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; 

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
  final _currentScoreInstance = Score(null);
  var _previousScoreInstance;
  final _scoreSession = ScoreSession();
  late AnimationController _animController;
  late Animation<double> _animation;
  late Animation<double> _scaleAnimation;
  bool _newScoreSheet = false;
  bool _oldScoreSheet = false;
  
  @override
  void initState() {
    super.initState();
    
    // Setup animation for UI elements
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut)
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
    bool hasScore = await _scoreSession.loadScoreForCurrentUser();
    _previousScoreInstance = _scoreSession.currentScore;
  }

  Future<void> _saveScore() async {
    try{
      await _scoreSession.createNewScore(_currentScoreInstance.players);
    }
    catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving score: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
        return AppLocalizations.of(context).phasecomplete;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (_newScoreSheet || _oldScoreSheet) 
      ? AppBar(
              title: _newScoreSheet 
                  ? Text(
                    AppLocalizations.of(context).newscoresheet,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Phase10Colors.darkText,
                    ),
                  )
                  : _oldScoreSheet
                  ? Text(
                    AppLocalizations.of(context).viewsocresheet,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Phase10Colors.darkText,
                    ),
                    )
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
            )
            :null,
      backgroundColor: Phase10Colors.backgroundGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: AnimatedBuilder(
            animation: _animController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    );
                  },
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _newScoreSheet
              ? _buildScoreSheet()
              : _oldScoreSheet 
              ? _viewOldScoreSheet()
              : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Image.asset('assets/Phase10Logo.png', height: 60),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).scoretracker,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Phase10Colors.darkText,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context).creatorview,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 32),
          
                buildScoreOption(
                  title: AppLocalizations.of(context).openscoresheet,
                  description: AppLocalizations.of(context).startscoresheet,
                  icon: Icons.paste,
                  color: Phase10Colors.primaryBlue,
                  onTap: _openScoreSheet,
                ),
          
                buildScoreOption(
                  title: AppLocalizations.of(context).viewprescoresheet,
                  description: AppLocalizations.of(context).seeprescoresheet,
                  icon: Icons.history,
                  color: Phase10Colors.accentOrange,
                  onTap: _viewPreviousScoreSheet,
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  void _openScoreSheet() {
  setState(() {
    _newScoreSheet = true;
    _oldScoreSheet = false;
  });
}

Future<void> _viewPreviousScoreSheet() async {
  await _checkForSavedScore();
  setState(() {
    if (_previousScoreInstance != null) {
      _oldScoreSheet = true;
      _newScoreSheet = false;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).nosavedscoresheet),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  });
}

  Widget buildScoreOption({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.6,
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onTap : null,
            splashColor: color.withOpacity(0.1),
            highlightColor: color.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 32),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Phase10Colors.darkText,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: color, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _viewOldScoreSheet() {
  if (_previousScoreInstance == null) {
    return Center(child: Text(AppLocalizations.of(context).nosavedscoresheet));
  }
  final leader = _previousScoreInstance.findLeader();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        AppLocalizations.of(context).prescoresheet,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Phase10Colors.darkText,
        ),
      ),
      SizedBox(height: 16),
      ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: _previousScoreInstance.players.length,
        itemBuilder: (context, index) {
          final player = _previousScoreInstance.players[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(player.name.substring(0, 1).toUpperCase()),
            ),
            title: Text(player.name),
            subtitle: Text('Phase: ${player.currentPhase} | Score: ${player.score}'),
            trailing: player == leader
                ? Icon(Icons.emoji_events, color: Phase10Colors.accentOrange)
                : null,
          );
        },
      ),
    ],
  );
}
  
  Widget _buildScoreSheet() {
    final leader = _currentScoreInstance.findLeader(); // Ensure leader is defined here
    return Column(
            children: [
               _currentScoreInstance.players.isEmpty
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
                              AppLocalizations.of(context).noplayeryet,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Phase10Colors.mediumGrey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context).addplayertrack,
                              style: TextStyle(
                                fontSize: 14,
                                color: Phase10Colors.mediumGrey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _currentScoreInstance.players.length,
                        itemBuilder: (_, index) {
                          final player = _currentScoreInstance.players[index];
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
                                              controller: _currentScoreInstance.scoreControllers[player],
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(
                                                hintText: AppLocalizations.of(context).entersocreforround,
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
                                                value: _currentScoreInstance.phaseCompleted[player],
                                                onChanged: (value) {
                                                  setState(() {
                                                    _currentScoreInstance.phaseCompleted[player] = value ?? false;
                                                  });
                                                },
                                                activeColor: Phase10Colors.primaryBlue,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  AppLocalizations.of(context).phasecomplete1,
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
                      AppLocalizations.of(context).addplayer,
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
                              controller: _currentScoreInstance.nameController,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context).enterplayername,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                              ),
                              onSubmitted: (_) => _currentScoreInstance.addPlayer,
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
                            if (_currentScoreInstance.nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context).plsenterplayername),
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
                                _currentScoreInstance.addPlayer(context);
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
                          child: Text(AppLocalizations.of(context).add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Bottom action buttons
              if (_currentScoreInstance.players.isNotEmpty)
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
                          if (!_currentScoreInstance.undoUsed) {
                            setState(() {
                              _currentScoreInstance.undoSubmit(context);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context).lastgameundone),
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
                                  content: Text(AppLocalizations.of(context).beforeundo),
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
                          backgroundColor: !_currentScoreInstance.undoUsed
                          ? Phase10Colors.primaryBlue
                          : Colors.white,
                          foregroundColor: !_currentScoreInstance.undoUsed
                          ? Colors.white
                          : Colors.red,
                          disabledForegroundColor: Colors.grey.withOpacity(0.5),
                          disabledBackgroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: (!_currentScoreInstance.undoUsed) 
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
                            SizedBox(width: 4),
                            Text("Undo"),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => {
                          setState((){
                            _currentScoreInstance.submitRound(context);
                            }),
                            ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context).roundsubmittedsucces),
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
                            SizedBox(width: 4),
                            Text(AppLocalizations.of(context).submit),
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
                            SizedBox(width: 4),
                            Text(AppLocalizations.of(context).save),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
  }
}