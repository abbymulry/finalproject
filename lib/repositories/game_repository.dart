// phase 10 game repository
// ==============================================================
//
// this file manages game persistence using Firebase Firestore
//
// the repository is responsible for:
// - saving game state to the database
// - loading game state from the database
// - handling user-specific game data
// - providing CRUD operations for game state
//
// this enables features like:
// - continuing games across app sessions
// - associating games with specific users
// - supporting multiplayer functionality
// ==============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game.dart';

class GameRepository {
  // firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // collection name in Firestore
  static const String _gamesCollection = 'games';
  
  // get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  // save a game for the current user
  Future<void> saveGame(Game game) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('No authenticated user');
    }
    
    try {
      // store game state in Firestore using userId as document ID
      await _firestore.collection(_gamesCollection).doc(userId).set(game.toJson());
    } catch (e) {
      print('Error saving game: $e');
      throw Exception('Failed to save game: $e');
    }
  }
  
  // get the current user's saved game
  Future<Game?> getGame() async {
    final userId = currentUserId;
    if (userId == null) return null;
    
    try {
      final doc = await _firestore.collection(_gamesCollection).doc(userId).get();
      
      if (doc.exists && doc.data() != null) {
        return Game.fromJson(doc.data()!);
      }
      
      return null;
    } catch (e) {
      print('Error retrieving game: $e');
      return null;
    }
  }
  
  // delete the current user's saved game
  Future<void> deleteGame() async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('No authenticated user');
    }
    
    try {
      await _firestore.collection(_gamesCollection).doc(userId).delete();
    } catch (e) {
      print('Error deleting game: $e');
      throw Exception('Failed to delete game: $e');
    }
  }
  
  // check if the current user has a saved game
  Future<bool> hasGame() async {
    final userId = currentUserId;
    if (userId == null) return false;
    
    try {
      final doc = await _firestore.collection(_gamesCollection).doc(userId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking for game: $e');
      return false;
    }
  }
}