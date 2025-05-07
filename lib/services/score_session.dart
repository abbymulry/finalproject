import '../models/score.dart';
import '../models/player.dart';
import '../repositories/score_repository.dart';

class ScoreSession {
  static final ScoreSession _instance = ScoreSession._internal();
  factory ScoreSession() => _instance;

  ScoreSession._internal();

  Score? _currentScore;
  final ScoreRepository _repository = ScoreRepository();
  String? _currentUserId;
  bool _isLoading = false;

  Score? get currentScore => _currentScore;
  bool get isLoading => _isLoading;
  bool? get hasScore => _currentScore != null;

  Future<Score> createNewScore(List<Player> players) async {
    final userId = _repository.currentUserId;
    if (userId == null) {
      throw Exception('No authenticated user');
    }

    _currentScore = Score(players);

    await _repository.saveScore(_currentScore!);
    _currentUserId = userId;

    return _currentScore!;
  }

  Future<bool> loadScoreForCurrentUser() async {
    _isLoading = true;

    try {
      final userId = _repository.currentUserId;

      if(userId == _currentUserId && _currentScore != null)
      {
        _isLoading = false;
        return true;
      }

      final score = await _repository.getScore();

      if(score != null)
      {
        _currentScore = score;
        _currentUserId = userId;
        _isLoading = false;
        return true;
      }
      else{
        _currentScore = null;
        _isLoading = false;
        return false;
      }
    }
    catch(e){
      print('Error loading score:  $e');
      _currentScore = null;
      _isLoading = false;
      return false; 
    }
  }

  Future<bool> saveCurrentScore() async {
    if(_currentScore == null) return false;

    try {
      await _repository.saveScore(_currentScore!);
      return true;
    }
    catch(e)
    {
      print('Error saving score: $e');
      return false;
    }
  }

  Future<bool> updateAfterAction() async {
    if(_currentScore != null)
    {
      _currentScore!.lastUpdated = DateTime.now();
      return await saveCurrentScore();
    }
    return false;
  }

  void clearScore() {
    _currentScore = null;
    _currentUserId = null;
  }

  Future<bool> checkForSavedScore() async {
    return await _repository.hasScore();
  }
}