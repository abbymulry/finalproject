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
import '../services/sound_player.dart';

// game class represents the entire game state
class Game {
  final String id; // unique identifier for the game
  List<Player> players; // all players in the game
  Deck _deckObject; // cards available to draw
  List<Card> discardPile; // cards that have been discarded
  int currentPlayerIndex; // whose turn it is
  GameState state; // waiting, playing, or finished
  List<Phase> phases; // the 10 phases and their requirements
  DateTime lastUpdated; // timestamp for synchronizing 

  Deck get deckObject => _deckObject;
  
  List<Card> get deck => _deckObject.cards;
  
  Game({
    required this.id,
    required this.players,
    required Deck deck,
    this.discardPile = const [],
    this.currentPlayerIndex = 0,
    this.state = GameState.waiting,
    List<Phase>? phases,
  }) : 
    this._deckObject = deck,
    this.phases = phases ?? Phase.createAllPhases(),
    this.lastUpdated = DateTime.now();
  
  // get the current player whose turn it is
  Player get currentPlayer => players[currentPlayerIndex];
  
  // create a new game with shuffled deck and dealt cards
  factory Game.newGame({required String id, required List<Player> players}) {
    // Generate a standard phase 10 deck with all cards
    print('[PHASE10-GAME] Creating new game with id: $id');
    
    // Create a new deck (which automatically shuffles in its constructor)
    Deck gameDeck = Deck();
    print('[PHASE10-GAME] New deck created with ${gameDeck.length} cards');
    
    // Deal 10 cards to each player
    print('[PHASE10-GAME] Dealing cards to ${players.length} players');
    for (var player in players) {
      print('[PHASE10-GAME] Dealing 10 cards to ${player.name}');
      player.hand = [];
      for (int i = 0; i < 10; i++) {
        player.hand.add(gameDeck.draw());
      }
      print('[PHASE10-GAME] ${player.name} now has ${player.hand.length} cards');
    }
    
    // Create the discard pile with the top card
    print('[PHASE10-GAME] Setting up discard pile');
    Card initialDiscard = gameDeck.draw();
    print('[PHASE10-GAME] Initial discard: $initialDiscard');
    
    return Game(
      id: id,
      players: players,
      deck: gameDeck,
      discardPile: [initialDiscard],
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
    print('[PHASE10-GAME] Drawing card from deck with ${_deckObject.length} cards');
    
    // Check if deck is empty, reshuffle discard if needed
    if (_deckObject.isEmpty) {
      print('[PHASE10-GAME] Deck is empty, reshuffling discard pile');
      // Keep the top discard card separate
      final topDiscard = discardPile.removeLast();
      
      // Move all other discard cards to the deck
      _deckObject.addCards(discardPile);
      discardPile = [topDiscard];
      
      // Shuffle the recycled cards
      print('[PHASE10-GAME] Shuffling recycled cards');
      _deckObject.shuffle();
    }
    
    // Take the top card from the deck
    final card = _deckObject.draw();
    print('[PHASE10-GAME] Drew card: $card, ${_deckObject.length} cards remaining');
    
    // Mark that the player has drawn
    currentPlayer.hasDrawn = true;
    
    // Update timestamp
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
    
    currentPlayer.hasLaidDown = true;
    print('[PHASE10-GAME] Player ${currentPlayer.name} has completed phase ${currentPlayer.currentPhase}');
    SoundPlayer.playPhaseCompleteSound();

    // update timestamp
    lastUpdated = DateTime.now();
    
    return true;
  }
  
  // end the current round and calculate scores
  void endRound() {
    print('[PHASE10-GAME] Ending round and calculating scores');
    
    // calculate scores for each player
    for (var player in players) {
      if (player.hand.isEmpty) {
        // winning player advances to next phase
        player.currentPhase++;
        print('[PHASE10-GAME] ${player.name} advances to phase ${player.currentPhase}');
        player.hasLaidDown = false;
      } else {
        // other players get penalty points
        int score = player.calculateHandScore();
        player.score += score;
        print('[PHASE10-GAME] ${player.name} gets ${score} penalty points, total now: ${player.score}');
      }
      // remove skipped effect on all players at end of round
      player.isSkipped = false;
    }
    
    // check if game is over (any player completed phase 10)
    if (players.any((p) => p.currentPhase > 10)) {
      state = GameState.finished;
      print('[PHASE10-GAME] Game is finished!');
    } else {
      // set up next round
      print('[PHASE10-GAME] Setting up next round');
      
      // create a new Deck object instead of List<Card>
      print('[PHASE10-GAME] Creating new deck for next round');
      _deckObject = Deck(); // this will internally call shuffle
      
      // reset player hands
      for (var player in players) {
        // deal cards from the Deck object
        print('[PHASE10-GAME] Dealing new hand to ${player.name}');
        player.hand = [];
        for (int i = 0; i < 10; i++) {
          player.hand.add(_deckObject.draw());
        }
        
        // reset draw status
        player.hasDrawn = false;
        
        // clear completed phases for the new round
        player.completedPhases = [];
        print('[PHASE10-GAME] ${player.name} ready for next round with ${player.hand.length} cards');
      }
      
      // use the deck object for the discard pile
      print('[PHASE10-GAME] Setting up discard pile for new round');
      discardPile = [_deckObject.draw()];
      print('[PHASE10-GAME] Initial discard: ${discardPile.last}');
      
      // winner of previous round goes first
      currentPlayerIndex = players.indexWhere((p) => p.currentPhase > p.completedPhases.length);
      if (currentPlayerIndex == -1) currentPlayerIndex = 0;
      print('[PHASE10-GAME] ${players[currentPlayerIndex].name} goes first in the new round');
    }
    
    // update timestamp
    lastUpdated = DateTime.now();
    print('[PHASE10-GAME] Round end complete');
  }

  void resetHands() {
    print('[PHASE10-GAME] Resetting hands for all players');
    
    try {
      for (var p in players) {
        print('[PHASE10-GAME] Clearing hand for ${p.name}');
        p.hand.clear();
        
        // draw directly from the deck object
        print('[PHASE10-GAME] Dealing 10 new cards to ${p.name}');
        for (int i = 0; i < 10; i++) {
          Card drawnCard = _deckObject.draw();
          p.hand.add(drawnCard);
          print('[PHASE10-GAME] Dealt card ${i+1}: ${drawnCard}');
        }
        
        p.hasLaidDown = false;
        print('[PHASE10-GAME] Reset hasLaidDown status for ${p.name}');
      }
      
      print('[PHASE10-GAME] Clearing discard pile');
      discardPile.clear();
      
      if (_deckObject.isEmpty) {
        throw StateError('Deck is empty, cannot reset hands');
      }
      
      // draw from the deck object for discard pile
      Card discardCard = _deckObject.draw();
      discardPile.add(discardCard);
      print('[PHASE10-GAME] New top card on discard pile: ${discardCard}');
    } catch (e) {
      print('[PHASE10-GAME] Error resetting hands: $e');
      throw Exception('Failed to reset hands: $e');
    }
  }
  
  // convert game to json for network transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'players': players.map((p) => p.toJson()).toList(),
      'deck': _deckObject.cards.map((c) => c.toJson()).toList(),
      'discardPile': discardPile.map((c) => c.toJson()).toList(),
      'currentPlayerIndex': currentPlayerIndex,
      'state': state.index,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
  
  // create game from json for network transmission
  factory Game.fromJson(Map<String, dynamic> json) {
    // create a deck object from the cards
    List<Card> deckCards = (json['deck'] as List).map((c) => Card.fromJson(c as Map<String, dynamic>)).toList();

    Deck deck = Deck.fromCards(deckCards);

    return Game(
      id: json['id'],
      players: (json['players'] as List).map((p) => Player.fromJson(p as Map<String, dynamic>)).toList(),
      deck: deck,
      discardPile: (json['discardPile'] as List).map((c) => Card.fromJson(c as Map<String, dynamic>)).toList(),
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