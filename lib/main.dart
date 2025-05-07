// =====================================================
// Phase 10 Flutter Game Implementation
// =====================================================
// Contributors:
// Erich Krueger
// Dillon Summers
// Thomas Woodcum
// Andrew Holden (AllenSyn20)
// Abby Mulry
// Mark Herpin
// Jianan Niu
// Dylan Miller
// Joseph (Ashton) Berret
// =====================================================

// Core package imports for Flutter UI framework
import 'package:flutter/material.dart';
// Import for mathematical operations
import 'dart:math';
// Firebase integration for backend services
import 'package:firebase_core/firebase_core.dart';
// Provider package for state management
import 'package:provider/provider.dart';
// Custom project imports
import 'providers/auth_provider.dart';   // Authentication logic
import 'screens/login_screen.dart';      // Login UI screen
import 'models/user_model.dart';         // User data model
import 'screens/game_screen.dart';       // Main game screen
import 'screens/play_screen.dart';       // Play interface screen
import 'screens/help_screen.dart';       // Help/instructions screen
import 'screens/score_screen.dart';      // Scoreboard screen
import 'services/game_session.dart';     // Game session management
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; //Language Support


// =====================================================
// Color Palette Definition
// =====================================================
// Project-wide color scheme for consistent UI design
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
  

// =====================================================
// FLUTTER UI IMPLEMENTATION
// =====================================================

// Application entry point - initializes Firebase and sets up providers
void main() async {
  // Ensure Flutter bindings are initialized before using platform channels
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialize Firebase for authentication and backend services
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase initialization error: $e');
    // continue running the app even if Firebase fails
  }
  // Launch the application with AuthProvider for state management
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// Root application widget with state management
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

// State management for the root application widget
class _MyAppState extends State<MyApp> {
  // Flag to ensure user check happens only once on startup
  bool _hasCheckedUser = false;

  @override
  Widget build(BuildContext context) {
    // Access the auth provider for user authentication state
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Check current user on startup only once to prevent infinite loops
    if (!_hasCheckedUser) {
      _hasCheckedUser = true;
      // Schedule after the frame is rendered to avoid build phase issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print("Checking user once at app startup");
        authProvider.checkCurrentUser();
      });
    }

    // Define the MaterialApp with theme and routing
    return MaterialApp(
      title: 'Phase 10 Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 7, 100, 186),
        ),
        useMaterial3: true,
      ),
      // Conditional rendering based on authentication state
      home: authProvider.isAuthenticated ? const MyHomePage() : const LoginScreen(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}

// Main homepage with navigation after successful login
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// State management for the main homepage
class _MyHomePageState extends State<MyHomePage> {
  // Track the currently selected page index for bottom navigation
  int pageIndex = 0;
  
  // Define the pages accessible through the bottom navigation bar
  static const List<Widget> _pages = <Widget>[
    PlayPage(),       // Game play interface
    ScorePage(),      // Score tracking and history
    HelpPage(),       // Game rules and instructions
  ];
  
  // Handle bottom navigation bar item selection
  void _onItemTapped(int index) {
    setState(() {
      pageIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Main scaffold with app bar, body, and bottom navigation
    return Scaffold(
      appBar: AppBar(
        title: const Text("Phase 10"),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        actions: [
          // Logout button in the app bar
          TextButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Logout', style: TextStyle(color: Colors.white)),
            onPressed: () {
              // Sign out the user through the auth provider
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              authProvider.signOut();
            },
          ),
        ],
      ),
      // Display the currently selected page
      body: Container(color: Colors.white, child: _pages[pageIndex]),
      // Bottom navigation for switching between app sections
      bottomNavigationBar: BottomNavigationBar(
        showUnselectedLabels: true,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.play_circle), label: 'Play'),
          BottomNavigationBarItem(icon: Icon(Icons.scoreboard), label: 'Score'),
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