// phase 10 game model
// ==============================================================
//
// this file defines the overall game state and gameplay mechanics like:
// - managing the deck and discard pile
// - tracking players and their turns
// - enforcing game rules and flow
// - handling card actions (draw, discard, play phase)
// - determining when rounds and the game end
//
// the game follows these steps:
// 1. deal 10 cards to each player
// 2. players take turns drawing, trying to complete phases, and discarding
// 3. first player to play all cards ends the round
// 4. calculate scores based on cards left in hands
// 5. winner advances to next phase
// 6. first player to complete phase 10 with lowest score wins
//
// this model acts as the core gameplay loop and coordinates the other helper models
// ==============================================================

import 'card.dart';
import 'player.dart';
import 'phase.dart';
import 'deck.dart';

// game class represents the entire game state
class Game {
  final String id; // unique identifier for the game
  List<Player> players; // all players in the game
  List<Card> deck; // cards available to draw
  List<Card> discardPile; // cards that have been discarded
  int currentPlayerIndex; // whose turn it is
  GameState state; // waiting, playing, or finished
  List<Phase> phases; // the 10 phases and their requirements
  DateTime lastUpdated; // timestamp for synchronizing 

  Deck get deckObject {
    return Deck.fromCards(deck);
  }
  
  
  Game({
    required this.id,
    required this.players,
    required this.deck,
    this.discardPile = const [],
    this.currentPlayerIndex = 0,
    this.state = GameState.waiting,
    List<Phase>? phases,
  }) : 
    this.phases = phases ?? Phase.createAllPhases(),
    this.lastUpdated = DateTime.now();
  
  // get the current player whose turn it is
  Player get currentPlayer => players[currentPlayerIndex];
  
  // create a new game with shuffled deck and dealt cards
  factory Game.newGame({required String id, required List<Player> players}) {
    // generate a standard phase 10 deck with all cards
    List<Card> deck = generateDeck();
    deck.shuffle();
    
    // deal 10 cards to each player
    for (var player in players) {
      player.hand = deck.take(10).toList();
      deck = deck.skip(10).toList();
    }
    
    // place first card from deck into discard pile to start
    return Game(
      id: id,
      players: players,
      deck: deck,
      discardPile: [deck.removeAt(0)],
      state: GameState.playing,
    );
  }
  
  // generate a standard phase 10 deck with all cards
  static List<Card> generateDeck() {
    List<Card> deck = [];
    int idCounter = 0;
    
    // add number cards (2 of each color/number combination)
    for (int copy = 0; copy < 2; copy++) {
      for (CardColor color in [CardColor.red, CardColor.blue, CardColor.green, CardColor.yellow]) {
        for (int value = 1; value <= 12; value++) {
          deck.add(Card(
            id: (idCounter++).toString(),
            type: CardType.number,
            value: value,
            color: color,
          ));
        }
      }
    }
    
    // add wild cards (8 total)
    for (int i = 0; i < 8; i++) {
      deck.add(Card(
        id: (idCounter++).toString(),
        type: CardType.wild,
        value: 0,
        color: CardColor.wild,
      ));
    }
    
    // add skip cards (4 total)
    for (int i = 0; i < 4; i++) {
      deck.add(Card(
        id: (idCounter++).toString(),
        type: CardType.skip,
        value: 0,
        color: CardColor.wild,
      ));
    }
    
    return deck;
  }
  
  // draw a card from the deck
  Card drawCard() {
    // check if deck is empty, reshuffle discard if needed
    if (deck.isEmpty) {
      // keep the top discard card separate
      final topDiscard = discardPile.removeLast();
      
      // move all other discard cards to the deck
      deck = discardPile;
      discardPile = [topDiscard];
      
      // shuffle the recycled cards
      deck.shuffle();
    }
    
    // take the top card from the deck
    final card = deck.removeAt(0);
    
    // mark that the player has drawn
    currentPlayer.hasDrawn = true;
    
    // update timestamp
    lastUpdated = DateTime.now();
    
    return card;
  }
  
  // draw a card from the discard pile
  Card drawFromDiscard() {
    // ensure discard pile isn't empty
    if (discardPile.isEmpty) {
      throw Exception('discard pile is empty');
    }
    
    // take the top card from the discard pile
    final card = discardPile.removeLast();
    
    // mark that the player has drawn
    currentPlayer.hasDrawn = true;
    
    // update timestamp
    lastUpdated = DateTime.now();
    
    return card;
  }
  
  // discard a card from the current player's hand
  void discardCard(String cardId) {
    // find the card in the player's hand
    final cardIndex = currentPlayer.hand.indexWhere((c) => c.id == cardId);
    
    // verify card exists in hand
    if (cardIndex == -1) {
      throw Exception('card not in player hand');
    }
    
    // remove card from hand and add to discard pile
    final card = currentPlayer.hand.removeAt(cardIndex);
    discardPile.add(card);

    // handle skip card effect
    if (card.type == CardType.skip) {
      // get next player
      int nextPlayerIndex = (currentPlayerIndex + 1) % players.length;
      // mark them skipped for next turn
      players[nextPlayerIndex].isSkipped = true;
    }
    
    // check if player has won the round
    if (currentPlayer.hand.isEmpty) {
      endRound();
    } else {
      nextTurn();
    }
    
    // update timestamp
    lastUpdated = DateTime.now();
  }
  
  // move to the next player's turn
  void nextTurn() {
    print('[PHASE10] nextTurn called');
    print('[PHASE10] Current player before: ${players[currentPlayerIndex].name}');
    print('[PHASE10] Current player hasDrawn before: ${players[currentPlayerIndex].hasDrawn}');
    
    // Reset current player's draw status
    currentPlayer.hasDrawn = false;
    print('[PHASE10] Reset hasDrawn to false for ${currentPlayer.name}');
    
    // Move to next player
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    print('[PHASE10] New current player: ${players[currentPlayerIndex].name}');
    
    // Check if next player has a skip effect
    if (currentPlayer.isSkipped) {
      print('[PHASE10] ${currentPlayer.name} is skipped!');
      // Reset skip status
      currentPlayer.isSkipped = false;
      print('[PHASE10] Reset isSkipped to false');

      // Skip player's turn by moving to next player's index
      currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
      print('[PHASE10] Skipped to next player: ${players[currentPlayerIndex].name}');
    }

    print('[PHASE10] Current player hasDrawn after: ${players[currentPlayerIndex].hasDrawn}');
    // update timestamp
    lastUpdated = DateTime.now();
  }
  
  // attempt to play a phase from the current player's hand
  bool playPhase(List<List<String>> cardGroups) {
    // verify player hasn't already completed this phase
    if (currentPlayer.hasCompletedCurrentPhase()) {
      return false;
    }
    
    // convert card ids to actual cards
    List<List<Card>> cardGroupObjects = [];
    
    // process each group of cards
    for (var group in cardGroups) {
      List<Card> groupCards = [];
      
      // find each card in the player's hand
      for (var cardId in group) {
        final cardIndex = currentPlayer.hand.indexWhere((c) => c.id == cardId);
        
        // ensure all cards are in the player's hand
        if (cardIndex == -1) {
          return false; // card not in hand
        }
        
        // add to the group
        groupCards.add(currentPlayer.hand[cardIndex]);
      }
      
      // add the group to our processed list
      cardGroupObjects.add(groupCards);
    }
    
    // get the current phase requirements
    final currentPhaseObj = phases[currentPlayer.currentPhase - 1];
    
    // check if cards satisfy the current phase
    if (!currentPhaseObj.isValidPhase(cardGroupObjects)) {
      return false;
    }
    
    // remove cards from hand and add to completed phases
    for (var group in cardGroupObjects) {
      for (var card in group) {
        // remove from hand
        currentPlayer.hand.removeWhere((c) => c.id == card.id);
      }
      // add to completed phases
      currentPlayer.completedPhases.add(group);
    }
    
    // update timestamp
    lastUpdated = DateTime.now();
    
    return true;
  }
  
  // end the current round and calculate scores
  void endRound() {
    // calculate scores for each player
    for (var player in players) {
      if (player.hand.isEmpty) {
        // winning player advances to next phase
        player.currentPhase++;
      } else {
        // other players get penalty points
        player.score += player.calculateHandScore();
      }
      // remove skipped effect on all players at end of round
      player.isSkipped = false;

    }
    
    // check if game is over (any player completed phase 10)
    if (players.any((p) => p.currentPhase > 10)) {
      state = GameState.finished;
    } else {
      // set up next round
      
      // create and shuffle a new deck
      List<Card> newDeck = generateDeck();
      newDeck.shuffle();
      
      // reset player hands
      for (var player in players) {
        // deal 10 new cards
        player.hand = newDeck.take(10).toList();
        newDeck = newDeck.skip(10).toList();
        
        // reset draw status
        player.hasDrawn = false;
        
        // clear completed phases for the new round
        player.completedPhases = [];
      }
      
      // set up new deck and discard pile
      deck = newDeck;
      discardPile = [deck.removeAt(0)];
      
      // winner of previous round goes first
      currentPlayerIndex = players.indexWhere((p) => p.hand.isEmpty);
      if (currentPlayerIndex == -1) currentPlayerIndex = 0;
    }
    
    // update timestamp
    lastUpdated = DateTime.now();
  }

  void resetHands() {
    try {
      for (var p in players) {
        p.hand.clear();
        for (int i = 0; i < 10; i++) {
          p.drawCard(deckObject);
        }
        p.hasLaidDown = false;
      }
      discardPile.clear();
      if (deck.isEmpty) {
        throw StateError('Deck is empty, cannot reset hands');
      }
      discardPile.add(deckObject.draw());
    } catch (e) {
      print('Error resetting hands: $e');
      throw Exception('Failed to reset hands: $e');
    }
  }
  
  // convert game to json for network transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'players': players.map((p) => p.toJson()).toList(),
      'deck': deck.map((c) => c.toJson()).toList(),
      'discardPile': discardPile.map((c) => c.toJson()).toList(),
      'currentPlayerIndex': currentPlayerIndex,
      'state': state.index,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
  
  // create game from json for network transmission
  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      players: (json['players'] as List).map((p) => Player.fromJson(p)).toList(),
      deck: (json['deck'] as List).map((c) => Card.fromJson(c)).toList(),
      discardPile: (json['discardPile'] as List).map((c) => Card.fromJson(c)).toList(),
      currentPlayerIndex: json['currentPlayerIndex'],
      state: GameState.values[json['state']],
    );
  }
  
  // find the winner of the game
  Player? findWinner() {
    // game must be finished
    if (state != GameState.finished) return null;
    
    // get players who completed phase 10
    List<Player> finishers = players.where((p) => p.currentPhase > 10).toList();
    
    // if no one finished, return null
    if (finishers.isEmpty) return null;
    
    // return the finisher with the lowest score
    finishers.sort((a, b) => a.score.compareTo(b.score));
    return finishers.first;
  }
}

extension on Object? {
  get id => null;
}

// possible states for the game
enum GameState { 
  waiting,   // before the game starts
  playing,   // game in progress
  finished   // game has ended
}