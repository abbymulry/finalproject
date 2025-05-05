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

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  final GameSession _gameSession = GameSession();
  bool _isLoading = false;
  bool _hasGame = false;

  @override
  void initState() {
    super.initState();
    _checkForSavedGame();
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
          SnackBar(content: Text('Error starting game: $e')),
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
            const SnackBar(content: Text("No game in progress.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error continuing game: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        Colors.lightBlue[100],
                      ),
                    ),
                    onPressed: _startNewGame,
                    child: const Text("Start New Game"),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        Colors.lightBlue[100],
                      ),
                    ),
                    onPressed: _hasGame ? _continueGame : null,
                    child: const Text("Continue Game"),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        Colors.lightBlue[100],
                      ),
                    ),
                    onPressed: () {},
                    child: const Text("Join Game"),
                  ),
                ],
              ),
      ),
    );
  }
}