import 'package:flutter/material.dart';
import '../services/game_multiplayer_service.dart';
import 'game_screen.dart';

class JoinGameScreen extends StatefulWidget {
  const JoinGameScreen({super.key});

  @override
  State<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends State<JoinGameScreen> {
  final TextEditingController _codeController = TextEditingController();
  final GameMultiplayerService _multiplayerService = GameMultiplayerService();
  bool _isJoining = false;
  
  // colors to match play screen
  static const Color primaryBlue = Color(0xFF2D6BE0);
  static const Color accentOrange = Color(0xFFF7A928);
  static const Color backgroundGrey = Color(0xFFF8F9FA);
  static const Color darkText = Color(0xFF212529);

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // Add join game functionality
  Future<void> _joinGame() async {
    // Validate code
    if (_codeController.text.isEmpty || _codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid 6-character code')),
      );
      return;
    }

    final code = _codeController.text.toUpperCase();
    
    setState(() {
      _isJoining = true;
    });
    
    try {
      // Check if code is valid
      final isValid = await _multiplayerService.isGameCodeValid(code);
      
      if (!isValid) {
        throw Exception('Invalid game code or game no longer active');
      }
      
      // Join the game
      final game = await _multiplayerService.joinGameWithCode(code);
      
      if (game == null) {
        throw Exception('Failed to join game');
      }
      
      setState(() {
        _isJoining = false;
      });
      
      // Navigate to game screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(engine: game),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isJoining = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        backgroundColor: backgroundGrey,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: darkText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Join Game',
          style: TextStyle(
            color: darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Image.asset('assets/Phase10Logo.png', height: 60),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Join a Game',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: darkText,
                            ),
                          ),
                          Text(
                            'Enter a game code to join',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 40),
                
                // code entry section
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Game Code',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Enter the 6-character code shared by the game host',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 24),
                      TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 6,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                          color: darkText,
                        ),
                        decoration: InputDecoration(
                          counterText: "",
                          hintText: "XXXXXX",
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            letterSpacing: 8,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryBlue, width: 2),
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isJoining ? null : _joinGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isJoining
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white),
                              )
                            : Text(
                                'Join Game',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
                
                // brief explanation section
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryBlue.withOpacity(0.05),
                        accentOrange.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: primaryBlue),
                          SizedBox(width: 8),
                          Text(
                            'How It Works',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkText,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Game codes are shared by the host player. Once you join, you\'ll be able to see the same game as your friends and play together in real-time.',
                        style: TextStyle(
                          fontSize: 14,
                          color: darkText.withOpacity(0.7),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}