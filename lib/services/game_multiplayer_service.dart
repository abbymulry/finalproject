// phase 10 multiplayer service
// ==============================================================
//
// this file provides a service that manages multiplayer game sessions
//
// the multiplayer service is responsible for:
// - generating game codes for new games
// - creating multiplayer games that others can join
// - joining existing games using a code
// - synchronizing game state across devices
//
// this service works with the existing GameSession for local game state
// ==============================================================

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game.dart';
import '../models/player.dart';
import 'game_session.dart';

class GameMultiplayerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GameSession _gameSession = GameSession();
  
  // generate a unique 6-character game code
  String _generateGameCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = Random();
    String code = '';
    
    for (int i = 0; i < 6; i++) {
      code += chars[random.nextInt(chars.length)];
    }
    
    return code;
  }
  
  // create a new multiplayer game and return the game code
  Future<String> createMultiplayerGame() async {
    // ensure user has an account
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must have a registered account to create a game');
    }
    
    // create a unique game code
    String gameCode = _generateGameCode();
    
    // check if code already exists just in case
    bool codeExists = await _isGameCodeInUse(gameCode);
    
    // generate a new code if it already exists
    while (codeExists) {
      gameCode = _generateGameCode();
      codeExists = await _isGameCodeInUse(gameCode);
    }
    
    // create host player
    final hostPlayer = Player(
      id: currentUser.uid,
      name: currentUser.email?.split('@')[0] ?? 'Host',
      isHost: true,
    );
    
    // create a new game with the host player
    final newGame = Game.newGame(
      id: gameCode,
      players: [hostPlayer],
    );
    
    // save to Firestore
    await _firestore.collection('games').doc(gameCode).set({
      'gameState': newGame.toJson(),
      'hostId': currentUser.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'active': true,
      'maxPlayers': 2,
      'players': [hostPlayer.toJson()],
    });
    
    // set as current game in game session
    _gameSession.setCurrentGame(newGame);
    
    return gameCode;
  }
  
  // check if a game code is already in use
  Future<bool> _isGameCodeInUse(String code) async {
    final doc = await _firestore.collection('games').doc(code).get();
    return doc.exists;
  }
  
  // check if a game code is valid (if it exists and is active)
  Future<bool> isGameCodeValid(String code) async {
    final doc = await _firestore.collection('games').doc(code).get();
    if (!doc.exists) return false;
    
    final data = doc.data();
    return data != null && data['active'] == true;
  }
  
  // join an existing game with a code
  Future<Game?> joinGameWithCode(String code) async {
    // ensure user is registered
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must have a registered account to join a game');
    }
    
    // get the game document from database
    final gameDoc = await _firestore.collection('games').doc(code).get();
    
    // check if game exists
    if (!gameDoc.exists) {
      throw Exception('Game not found with code: $code');
    }
    
    final gameData = gameDoc.data()!;
    
    // check if game is active
    if (gameData['active'] != true) {
      throw Exception('This game is no longer active');
    }
    
    // check player count (max of 2 for now)
    final playersList = gameData['players'] as List<dynamic>;
    if (playersList.length >= (gameData['maxPlayers'] ?? 2)) {
      throw Exception('Game is full');
    }
    
    // check if user is already in this game
    bool alreadyJoined = false;
    for (final player in playersList) {
      if (player['id'] == currentUser.uid) {
        alreadyJoined = true;
        break;
      }
    }
    
    // parse the game state
    final Game game = Game.fromJson(gameData['gameState']);
    
    // create and add new player if not already in game
    if (!alreadyJoined) {
      final newPlayer = Player(
        id: currentUser.uid,
        name: currentUser.email?.split('@')[0] ?? 'Player',
        isHost: false,
      );
      
      // add to game object
      game.players.add(newPlayer);
      
      // update Firestore with new player
      await _firestore.collection('games').doc(code).update({
        'gameState': game.toJson(),
        'players': FieldValue.arrayUnion([newPlayer.toJson()]),
      });
    }
    
    // set as current game in game session
    _gameSession.setCurrentGame(game);
    
    return game;
  }
  
  // listen for changes to a multiplayer game
  Stream<Game> listenToGame(String gameCode) {
    return _firestore
        .collection('games')
        .doc(gameCode)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('Game no longer exists');
      }
      
      final data = snapshot.data()!;
      return Game.fromJson(data['gameState']);
    });
  }
  
  // update the game state in Firestore
  Future<void> updateGameState(Game game) async {
    await _firestore.collection('games').doc(game.id).update({
      'gameState': game.toJson(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
}