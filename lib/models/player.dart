// =====================================================
// Phase 10 Game - Player Class Implementation
// =====================================================
// This file defines the Player class that represents a player 
// in the Phase 10 card game, including their hand, completed phases,
// game state, and actions they can perform during gameplay.

// Import game-specific card and deck models
import 'package:finalproject/models/card.dart';  // Card representation for the game
import 'package:finalproject/models/deck.dart';  // Deck management for drawing cards

/// Player class represents a single player in the Phase 10 game
/// Handles player state, card management, and game actions
class Player {
  // =====================================================
  // Player Properties
  // =====================================================
  final String id;                  // Unique identifier for the player
  final String name;                // Display name of the player
  List<Card> hand;                  // Cards currently held by the player
  List<List<Card>> completedPhases; // Phases that the player has completed (organized by card groupings)
  int currentPhase;                 // The phase number the player is currently attempting (1-10)
  int score;                        // Player's cumulative score (lower is better in Phase 10)
  bool hasDrawn;                    // Flag indicating if the player has drawn a card this turn
  bool isSkipped;                   // Flag indicating if the player's turn is skipped
  bool hasLaidDown;                 // Flag indicating if the player has laid down cards for their phase this round
  bool isHost;

  // =====================================================
  // Constructor with named parameters and default values
  // =====================================================
  Player({
    required this.id,               // Player ID must be provided
    required this.name,             // Player name must be provided
    List<Card>? hand,               // Optional initial hand
    List<List<Card>>? completedPhases, // Optional completed phases
    this.currentPhase = 1,          // Players start at phase 1 by default
    this.score = 0,                 // Players start with 0 score
    this.hasDrawn = false,          // Player hasn't drawn yet at start of turn
    this.isSkipped = false,         // Player isn't skipped by default
    this.hasLaidDown = false,       // Player hasn't laid down cards by default
    this.isHost = false,
  }) : hand = hand ?? [],           // Initialize empty hand if not provided
       completedPhases = completedPhases ?? []; // Initialize empty completed phases if not provided

  // =====================================================
  // Factory constructor to create a Player from JSON data
  // =====================================================
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],               // Get player ID from JSON
      name: json['name'],           // Get player name from JSON
      // Convert JSON card list to Card objects
      hand: (json['hand'] as List<dynamic>).map((c) => Card.fromJson(c)).toList(),
      // Convert nested JSON structure to List<List<Card>> for completed phases
      completedPhases: (json['completedPhases'] as List<dynamic>)
          .map((phase) => (phase as List<dynamic>)
              .map((c) => Card.fromJson(c))
              .toList())
          .toList(),
      currentPhase: json['currentPhase'],  // Get current phase number
      score: json['score'],                // Get player score
      hasDrawn: json['hasDrawn'],          // Get drawn status
      isSkipped: json['isSkipped'] ?? false, // Get skipped status (default false)
      hasLaidDown: json['hasLaidDown'] ?? false, // Get laid down status (default false)
      isHost: json['isHost'] ?? false,
    );
  }

  // =====================================================
  // Convert Player object to JSON for storage/networking
  // =====================================================
  Map<String, dynamic> toJson() {
    return {
      'id': id,                     // Store player ID
      'name': name,                 // Store player name
      // Convert hand cards to JSON
      'hand': hand.map((c) => c.toJson()).toList(),
      // Convert completed phases (nested structure) to JSON
      'completedPhases': completedPhases
          .map((phase) => phase.map((c) => c.toJson()).toList())
          .toList(),
      'currentPhase': currentPhase, // Store current phase number
      'score': score,               // Store player score
      'hasDrawn': hasDrawn,         // Store drawn status
      'isSkipped': isSkipped,       // Store skipped status
      'hasLaidDown': hasLaidDown,   // Store laid down status
      'isHost': isHost,
    };
  }

  // =====================================================
  // Calculate the point value of cards in player's hand
  // =====================================================
  // In Phase 10, lower score is better (points are penalties)
  int calculateHandScore() {
    return hand.fold(0, (sum, card) {
      if (card.type == CardType.skip) return sum + 15;   // Skip cards worth 15 points
      if (card.type == CardType.wild) return sum + 25;   // Wild cards worth 25 points
      return sum + card.value;                          // Number cards worth their face value
    });
  }

  // =====================================================
  // Check if player has completed their current phase
  // =====================================================
  bool hasCompletedCurrentPhase() {
    return currentPhase <= completedPhases.length;
  }
    
  // =====================================================
  // Draw a card from the deck and add to player's hand
  // =====================================================
  void drawCard(Deck deck) {
    print('[PHASE10-PLAYER] ${name} drawing card from deck with ${deck.length} cards');
    
    try {
      // draw card from deck
      final card = deck.draw();
      print('[PHASE10-PLAYER] ${name} drew ${card}');
      
      // add to hand
      hand.add(card);
      print('[PHASE10-PLAYER] ${name} hand size now: ${hand.length}');
      
      // set draw status
      hasDrawn = true;
      print('[PHASE10-PLAYER] ${name} hasDrawn set to true');
    } catch (e) {
      print('[PHASE10-PLAYER] ERROR: ${name} failed to draw card: $e');
      rethrow;
    }
  }

  // =====================================================
  // Discard a card from player's hand to the discard pile
  // =====================================================
  void discard(Card card, List<Card> discardPile) {
    print('[PHASE10] ${name} discarding card: ${card}');
    // Find the card index in the player's hand
    final index = hand.indexWhere((c) => c.id == card.id);
    if (index == -1) {
      // Card not found in player's hand - error condition
      print('[PHASE10] Error: Card not found in hand!');
      throw Exception('Card not in hand');
    }
    // Remove card from hand and add to discard pile
    final removedCard = hand.removeAt(index);
    discardPile.add(removedCard);
    print('[PHASE10] ${name} discarded card, hand size now: ${hand.length}');
  }

  // =====================================================
  // Attempt to complete a phase using cards in hand
  // =====================================================
  // This implementation appears to be a simplified version that
  // only checks for sets (3 or more of same value)
  bool attemptPhase() {
    var freq = <int, int>{};        // Map to count frequency of each card value
    for (var card in hand) {
      if (card.type == CardType.number) {
        // Count occurrence of each card value
        freq[card.value] = (freq[card.value] ?? 0) + 1;
      }
    }
    // Check if any value appears 3 or more times (a set)
    if (freq.values.any((count) => count >= 3)) {
      hasLaidDown = true;           // Mark that player has laid down cards
      return true;                  // Phase attempt successful
    }
    return false;                   // Phase attempt failed
  }

  // =====================================================
  // Getter to check if player's hand is empty (game end condition)
  // =====================================================
  bool get hasEmptyHand => hand.isEmpty;
}