// Erich Krueger
// Dillon Summers
// Thomas Woodcum
// Andrew Holden
// Abby Mulry
// Mark Herpin
// Jianan Niu
// Dylan Miller
// Joseph (Ashton) Berret
// Game

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'models/user_model.dart';
import 'screens/game_screen.dart';
import 'screens/play_screen.dart';
import 'screens/help_screen.dart';
import 'services/game_session.dart';



class ProjectPalette {
  Color darkGray = Color.fromARGB(255, 47, 47, 60);
  Color lightGray = Color.fromARGB(255, 206, 206, 255);
  Color white = Color.fromARGB(255, 255, 255, 255);
  Color black = Color.fromARGB(255, 0, 0, 0);
  Color red = Color.fromARGB(255, 255, 0, 87);
  Color orange = Color.fromARGB(255, 255, 183, 0);
  Color green = Color.fromARGB(255, 0, 255, 73);
  Color blue = Color.fromARGB(255, 0, 228, 255);
}
  

// FLUTTER UI

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase initialization error: $e');
    // continue running the app even if Firebase fails
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _hasCheckedUser = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // check current user on startup only once
    if (!_hasCheckedUser) {
      _hasCheckedUser = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print("Checking user once at app startup");
        authProvider.checkCurrentUser();
      });
    }

    return MaterialApp(
      title: 'Phase 10 Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 7, 100, 186),
        ),
        useMaterial3: true,
      ),
      home: authProvider.isAuthenticated ? const MyHomePage() : const LoginScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int pageIndex = 0;
  
  static const List<Widget> _pages = <Widget>[
    PlayPage(),
    HelpPage(),
    // ScorePage()
  ];
  
  void _onItemTapped(int index) {
    setState(() {
      pageIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Phase 10"),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        actions: [
          // add logout button
          TextButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Logout', style: TextStyle(color: Colors.white)),
            onPressed: () {
              // sign out the user
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              authProvider.signOut();
            },
          ),
        ],
      ),
      body: Container(color: Colors.white, child: _pages[pageIndex]),
      bottomNavigationBar: BottomNavigationBar(
        showUnselectedLabels: true,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.play_circle), label: 'Play'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Help'),
        ],
        currentIndex: pageIndex,
        onTap: _onItemTapped,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
// class ScorePage extends StatelessWidget{
// const ScorePage({super.key});
// @override
// Widget build(BuildContext context)
// {
// return Scaffold(
// appBar: AppBar(
// title: Text("Score Page"),
// ),
// body: Center(),
// );
// }
// }

