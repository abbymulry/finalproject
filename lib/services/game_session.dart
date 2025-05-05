// phase 10 game session service
// ==============================================================
//
// this file provides a singleton service that manages the current game session
//
// the game session is responsible for:
// - maintaining the current game state in memory
// - creating new games
// - loading saved games
// - saving game state after changes
// - handling user transitions
//
// this service acts as a bridge between the UI and the game repository
// ==============================================================

import '../models/game.dart';
import '../models/player.dart';
import '../repositories/game_repository.dart';

class GameSession {
  // singleton instance
  static final GameSession _instance = GameSession._internal();
  factory GameSession() => _instance;
  
  // private constructor
  GameSession._internal();
  
  // game state
  Game? _currentGame;
  final GameRepository _repository = GameRepository();
  bool _isLoading = false;
  String? _currentUserId;
  
  // getters
  Game? get currentGame => _currentGame;
  bool get isLoading => _isLoading;
  bool get hasGame => _currentGame != null;
  
  // create a new game
  Future<Game> createNewGame(List<Player> players) async {
    final userId = _repository.currentUserId;
    if (userId == null) {
      throw Exception('No authenticated user');
    }
    
    // create new game
    _currentGame = Game.newGame(
      id: userId, // use userId as the game ID
      players: players,
    );
    
    // save to Firestore
    await _repository.saveGame(_currentGame!);
    _currentUserId = userId;
    
    return _currentGame!;
  }
  
  // load game for current user
  Future<bool> loadGameForCurrentUser() async {
    _isLoading = true;
    
    try {
      final userId = _repository.currentUserId;
      
      // skip if already loaded for this user
      if (userId == _currentUserId && _currentGame != null) {
        _isLoading = false;
        return true;
      }
      
      // attempt to load the game
      final game = await _repository.getGame();
      
      if (game != null) {
        _currentGame = game;
        _currentUserId = userId;
        _isLoading = false;
        return true;
      } else {
        _currentGame = null;
        _isLoading = false;
        return false;
      }
    } catch (e) {
      print('Error loading game: $e');
      _currentGame = null;
      _isLoading = false;
      return false;
    }
  }
  
  // save current game
  Future<bool> saveCurrentGame() async {
    if (_currentGame == null) return false;
    
    try {
      await _repository.saveGame(_currentGame!);
      return true;
    } catch (e) {
      print('Error saving game: $e');
      return false;
    }
  }
  
  // update game after action
  Future<bool> updateAfterAction() async {
    if (_currentGame != null) {
      _currentGame!.lastUpdated = DateTime.now();
      return await saveCurrentGame();
    }
    return false;
  }
  
  // clear game on logout
  void clearGame() {
    _currentGame = null;
    _currentUserId = null;
  }
  
  // delete saved game
  Future<bool> deleteGame() async {
    try {
      await _repository.deleteGame();
      _currentGame = null;
      return true;
    } catch (e) {
      print('Error deleting game: $e');
      return false;
    }
  }
  
  // check if the current user has a saved game in Firestore
  Future<bool> checkForSavedGame() async {
    return await _repository.hasGame();
  }
}