// =====================================================
// Phase 10 Game - Game Model Unit Tests
// =====================================================
// This test file validates the Game model implementation for Phase 10,
// ensuring proper initialization, state management, and game actions.
// Location: test/models/game_model_test.dart

import 'package:flutter_test/flutter_test.dart';     // Flutter testing framework
import 'package:finalproject/models/card.dart';      // Card model with types and colors
import 'package:finalproject/models/player.dart';    // Player model for game participants
import 'package:finalproject/models/phase.dart';     // Phase definitions for game rules
import 'package:finalproject/models/game.dart';

import '../../lib/main.dart';      // Game model being tested

/// Main test entry point - contains all test groups for Game model
void main() {
  // =====================================================
  // Game Creation Tests
  // =====================================================
  // This group focuses on testing proper game initialization
  // and creation through different constructors
  group('Game Creation Tests', () {
    // Test basic Game constructor with minimal setup
    test('Game should initialize correctly', () {
      // Create test players
      final player1 = Player(id: 'p1', name: 'Player 1');
      final player2 = Player(id: 'p2', name: 'Player 2');
      
      // Create a basic deck with minimal cards for testing
      final testDeck = [
        Card(id: '1', type: CardType.number, value: 5, color: CardColor.red),
        Card(id: '2', type: CardType.number, value: 6, color: CardColor.blue),
      ];
      
      // Initialize game with test data
      final game = Game(
        id: 'test-game',
        players: [player1, player2],
        deck: testDeck,
      );
      
      // Verify game properties are correctly initialized
      expect(game.id, 'test-game');                // Game ID matches provided value
      expect(game.players.length, 2);              // Both players are added
      expect(game.deck.length, 2);                 // Deck contains test cards
      expect(game.currentPlayerIndex, 0);          // First player is active
      expect(game.state, GameState.waiting);       // Game starts in waiting state
    });
    
    // Test factory constructor that sets up a complete game
    test('Game.newGame() should create a game with proper setup', () {
      // Create test players
      final player1 = Player(id: 'p1', name: 'Player 1');
      final player2 = Player(id: 'p2', name: 'Player 2');
      
      // Use factory constructor to create and setup game
      final game = Game.newGame(
        id: 'new-game',
        players: [player1, player2],
      );
      
      // Verify game state is set to playing (not waiting)
      expect(game.state, GameState.playing);
      
      // Verify each player has been dealt 10 cards (full hand)
      expect(game.players[0].hand.length, 10);
      expect(game.players[1].hand.length, 10);
      
      // Verify discard pile has been initialized with one card
      expect(game.discardPile.length, 1);
      
      // Verify deck still has cards after dealing
      expect(game.deck.isNotEmpty, true);
    });
  });
  
  // =====================================================
  // Game Action Tests
  // =====================================================
  // This group focuses on testing game mechanics and player actions
  // such as drawing cards and manipulating the discard pile
  group('Game Action Tests', () {
    // Test variables accessible to all tests in this group
    late Game game;
    late Player player1;
    late Player player2;
    
    // Setup runs before each test to create a fresh game state
    setUp(() {
      // Create test players
      player1 = Player(id: 'p1', name: 'Player 1');
      player2 = Player(id: 'p2', name: 'Player 2');
      
      // Create new game with factory constructor
      game = Game.newGame(
        id: 'action-test',
        players: [player1, player2],
      );
    });
    
    // Test drawing card from deck action
    test('drawCard() should return a card and mark player as having drawn', () {
      // Store initial deck size for comparison
      final initialDeckSize = game.deck.length;
      
      // Execute the action being tested
      final drawnCard = game.drawCard();
      
      // Verify deck size decreased by one
      expect(game.deck.length, initialDeckSize - 1);
      
      // Verify player state is updated to reflect card draw
      expect(game.currentPlayer.hasDrawn, true);
      
      // Verify a valid card was returned
      expect(drawnCard, isA<Card>());
      
      // Simulate adding card to player's hand (normally handled by game logic)
      game.currentPlayer.hand.add(drawnCard);
      
      // Verify hand size increased after adding drawn card
      expect(game.currentPlayer.hand.length, 11);
    });

    // Test drawing card from discard pile action
    test('drawFromDiscard() should return top discard card', () {
      // Store initial player hand size for comparison
      final initialHandSize = game.currentPlayer.hand.length;
      
      // Store the top discard card for verification later
      final topDiscard = game.discardPile.last;
      
      // Execute the action being tested
      final drawnCard = game.drawFromDiscard();
      
      // Verify card returned matches the expected discard card
      expect(drawnCard, equals(topDiscard));
      
      // Verify discard pile is now empty after drawing
      expect(game.discardPile.length, 0);
      
      // Verify player state is updated to reflect card draw
      expect(game.currentPlayer.hasDrawn, true);
      
      // Simulate adding card to player's hand (normally handled by game logic)
      game.currentPlayer.hand.add(drawnCard);
      
      // Verify hand size increased by 1 after adding drawn card
      expect(game.currentPlayer.hand.length, initialHandSize + 1);
    });
  });
  

}