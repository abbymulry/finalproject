// phase 10 play screen
// ==============================================================
//
// this file defines the play screen which serves as the main menu for the game
//
// the play screen allows users to:
// - start a new game
// - continue a previously saved game
// - join multiplayer games (future feature)
//
// it acts as the entry point to gameplay and manages the transition to
// active game screens
// ==============================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/game_session.dart';
import '../models/player.dart';
import 'game_screen.dart';

// Color palette for the updated UI
class Phase10Colors {
  static const Color primaryBlue = Color(0xFF2D6BE0);
  static const Color accentOrange = Color(0xFFF7A928);
  static const Color backgroundGrey = Color(0xFFF8F9FA);
  static const Color darkText = Color(0xFF212529);
}

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> with SingleTickerProviderStateMixin {
  final GameSession _gameSession = GameSession();
  bool _isLoading = false;
  bool _hasGame = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _checkForSavedGame();

    // Animation setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut)
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkForSavedGame() async {
    setState(() {
      _isLoading = true;
    });

    bool hasGame = await _gameSession.loadGameForCurrentUser();

    setState(() {
      _hasGame = hasGame;
      _isLoading = false;
    });
  }

  Future<void> _startNewGame() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // get the current user
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'player1';
      final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Unknown';
      
      // create players (user and AI)
      final players = [
        Player(
          id: currentUserId,
          name: userEmail.split('@')[0], // use part before @ as name
        ),
        Player(
          id: 'ai',
          name: 'AI Opponent',
        )
      ];

      // start a new game
      await _gameSession.createNewGame(players);

      setState(() {
        _hasGame = true;
        _isLoading = false;
      });

      // navigate to game screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(engine: _gameSession.currentGame!),
          ),
        ).then((_) => _checkForSavedGame()); // refresh on return
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting game: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _continueGame() async {
    try {
      if (_gameSession.hasGame) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(engine: _gameSession.currentGame!),
          ),
        ).then((_) => _checkForSavedGame()); // refresh on return
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("No game in progress."),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error continuing game: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildGameOption(String title, String description, IconData icon, Color color, VoidCallback onTap, bool enabled) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.6,
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled ? [
            BoxShadow(
              color: color.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ] : null,
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
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 30,
                    ),
                  ),
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
                  Icon(
                    Icons.arrow_forward_ios,
                    color: enabled ? color : Colors.grey.shade400,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'Player';
    
    return Scaffold(
      backgroundColor: Phase10Colors.backgroundGrey,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Phase10Colors.primaryBlue),
                  SizedBox(height: 16),
                  Text(
                    'Loading your game...',
                    style: TextStyle(
                      color: Phase10Colors.darkText,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with logo and welcome message
                        Row(
                          children: [
                            Image.asset('assets/Phase10Logo.png', height: 60),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, $userName!',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Phase10Colors.darkText,
                                    ),
                                  ),
                                  Text(
                                    'Ready to play Phase 10?',
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
                        
                        // Game status container
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _hasGame 
                                ? Colors.green.withOpacity(0.3) 
                                : Colors.grey.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _hasGame 
                                    ? Colors.green.withOpacity(0.15)
                                    : Colors.grey.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _hasGame ? Icons.videogame_asset : Icons.videogame_asset_off,
                                  color: _hasGame ? Colors.green : Colors.grey,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _hasGame ? 'Game in Progress' : 'No Active Game',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _hasGame ? Colors.green : Colors.grey.shade700,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _hasGame 
                                        ? 'You can continue your saved game'
                                        : 'Start a new game to begin playing',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 32),
                        
                        Text(
                          'Game Options',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Phase10Colors.darkText,
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Game options
                        _buildGameOption(
                          'New Game',
                          'Start a fresh game of Phase 10',
                          Icons.add_circle,
                          Phase10Colors.primaryBlue,
                          _startNewGame,
                          true,
                        ),
                        
                        _buildGameOption(
                          'Continue Game',
                          'Resume your saved game',
                          Icons.play_circle,
                          Phase10Colors.accentOrange,
                          _continueGame,
                          _hasGame,
                        ),
                        
                        _buildGameOption(
                          'Join Game',
                          'Play with friends online',
                          Icons.group,
                          Colors.purple,
                          () {},
                          false, // Disabled for now
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Phase explanation
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Phase10Colors.primaryBlue.withOpacity(0.05),
                                Phase10Colors.accentOrange.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Phase10Colors.primaryBlue),
                                  SizedBox(width: 8),
                                  Text(
                                    'About Phase 10',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Phase10Colors.darkText,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Phase 10 is a card game where players attempt to complete 10 phases in order. Each phase requires a specific combination of cards like runs and sets.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Phase10Colors.darkText.withOpacity(0.7),
                                  height: 1.5,
                                ),
                              ),
                              SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () {
                                  // Could navigate to help screen or show tutorial
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Phase10Colors.primaryBlue,
                                  side: BorderSide(color: Phase10Colors.primaryBlue),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text('Learn More'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}