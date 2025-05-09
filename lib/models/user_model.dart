// represents a user in our application
// stores basic user information for authentication and profile
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final int currentPhase;
  final int gamesPlayed;
  final int gamesWon;

  // constructor with required fields and optional ones with defaults
  UserModel({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.currentPhase = 1,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
  });

  // create a user from firebase user data
  factory UserModel.fromFirebaseUser(String uid, String email) {
    return UserModel(
      uid: uid,
      email: email,
    );
  }

  // convert user model to map for firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'currentPhase': currentPhase,
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
    };
  }

  // create user model from firestore data
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      currentPhase: map['currentPhase'] ?? 1,
      gamesPlayed: map['gamesPlayed'] ?? 0,
      gamesWon: map['gamesWon'] ?? 0,
    );
  }

  // create updated user model with new values
  UserModel copyWith({
    String? displayName,
    int? currentPhase,
    int? gamesPlayed,
    int? gamesWon,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      currentPhase: currentPhase ?? this.currentPhase,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
    );
  }
}