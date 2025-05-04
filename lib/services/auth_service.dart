import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

// handles all authentication operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // get current user
  User? get currentUser => _auth.currentUser;

  // get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // get user profile from firestore
  Future<UserModel?> getUserProfile(String uid) async {
  try {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return UserModel.fromMap(data);
    } else {
      // create a basic profile if it doesn't exist
      UserModel newUser = UserModel(
        uid: uid,
        email: _auth.currentUser?.email ?? '',
        displayName: _auth.currentUser?.email?.split('@')[0] ?? '',
      );
      
      // save the new profile
      await createUserProfile(newUser);
      return newUser;
    }
  } catch (e) {
    print('error getting user profile: $e');
    return null;
  }
}

  // create user in firestore
  Future<void> createUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      print('error creating user profile: $e');
    }
  }

  // sign in with email and password
Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
  try {
    // attempt to sign in
    UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    User? user = result.user;
    
    if (user != null) {
      // create a basic user model directly from the Firebase user -> avoids the type cast error by not depending on Firestore initially
      UserModel basicUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
      );
      
      // try to get the full profile, but don't fail if it's not available
      try {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }
      } catch (e) {
        print('error getting user profile: $e');
        // continue with the basic user model
      }
      
      return basicUser;
    }
    return null;
  } catch (e) {
    print('error signing in: $e');
    return null;
  }
}

  // register with email and password
  Future<UserModel?> registerWithEmailAndPassword(String email, String password) async {
    try {
      // attempt to create user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      
      if (user != null) {
        // create new user model
        UserModel newUser = UserModel.fromFirebaseUser(user.uid, user.email ?? '');
        
        // create user profile in firestore
        await createUserProfile(newUser);
        
        return newUser;
      }
      return null;
    } catch (e) {
      print('error registering: $e');
      return null;
    }
  }

  // sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('error signing out: $e');
    }
  }
}