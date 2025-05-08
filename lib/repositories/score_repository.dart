import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/score.dart';

class ScoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _scoresCollection = 'scores';

  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> saveScore(Score score) async
  {
        final userId = currentUserId;
        if (userId == null) {
          throw Exception('No authenticated user');
        }
        
        try {
          // store score state in Firestore using userId as document ID
          await _firestore.collection(_scoresCollection).doc(userId).set(score.toJson());
        } catch (e) {
          print(';;;;Error saving score: $e');
          throw Exception('Failed to save score: $e');
        }
   }
  
  Future<Score?> getScore() async {
    final userId = currentUserId;
    if (userId == null) return null;
    
    try {
      final doc = await _firestore.collection(_scoresCollection).doc(userId).get();
      
      if (doc.exists && doc.data() != null) {
        return Score.fromJson(doc.data()!);
      }
      
      return null;
    } catch (e) {
      print('Error retrieving game: $e');
      return null;
    }
  }

  Future<bool> hasScore() async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      final doc = await _firestore.collection(_scoresCollection).doc(userId).get();
      return doc.exists;
    }
    catch (e) {
      print('Error checking for score: $e');
      return false;
    }

  }
}