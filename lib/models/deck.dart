// phase 10 deck model
// ==============================================================
//
// this file defines the deck class which manages the collection of cards used in the game
//
// the deck is responsible for:
// - initializing all cards for a standard phase 10 deck
// - shuffling cards for randomized gameplay
// - providing card drawing functionality
// - tracking the remaining cards
// - serialization for persistence and networking
//
// the deck structure follows the standard phase 10 rules with:
// - number cards (1-12) in four colors, two of each combination
// - wild cards that can substitute for any card
// - skip cards that cause the next player to lose their turn
//
// includes serialization methods to support:
// - game state persistence to database
// - transmitting deck state during networked gameplay
// ==============================================================

import 'dart:math' as Math;
import 'card.dart';

class Deck {
  // private collection of cards in the deck
  final List<Card> _cards = [];
  
  // standard colors in the game
  final List<CardColor> colors = [
    CardColor.red, 
    CardColor.blue, 
    CardColor.green, 
    CardColor.yellow
  ];
  
  // deck ID for debugging
  final String _deckId;

  // create a new deck with all standard cards
  Deck() : _deckId = DateTime.now().millisecondsSinceEpoch.toString() {
    print('[PHASE10-DECK] Creating new deck with ID: $_deckId');
    _initializeCards();
    print('[PHASE10-DECK] Cards initialized, calling shuffle');
    shuffle();
  }

  // initialize with predefined cards (for deserialization)
  Deck.fromCards(List<Card> cards) : _deckId = DateTime.now().millisecondsSinceEpoch.toString() {
    print('[PHASE10-DECK] Creating deck from cards with ID: $_deckId');
    _cards.clear();
    _cards.addAll(cards);
    print('[PHASE10-DECK] Created deck from ${cards.length} cards');
  }

  // toString for easier debugging
  @override
  String toString() {
    return 'Deck $_deckId with ${_cards.length} cards';
  }

  // set up all cards in a standard phase 10 deck
  void _initializeCards() {
    int idCounter = 0;
    
    // add number cards (2 of each color/number combination)
    for (int copy = 0; copy < 2; copy++) {
      for (CardColor color in colors) {
        for (int value = 1; value <= 12; value++) {
          _cards.add(Card(
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
      _cards.add(Card(
        id: (idCounter++).toString(),
        type: CardType.wild,
        value: 0,
        color: CardColor.wild,
      ));
    }
    
    // add skip cards (4 total)
    for (int i = 0; i < 4; i++) {
      _cards.add(Card(
        id: (idCounter++).toString(),
        type: CardType.skip,
        value: 0,
        color: CardColor.wild,
      ));
    }
  }

  // randomize the order of cards -> Fisher-Yates algo
  void shuffle() {
    print('\n[PHASE10-SHUFFLE] Shuffling deck with ${_cards.length} cards');

    // check card distribution before shuffle operations
    _logCardDistribution('BEFORE');
    
    // show a few cards before shuffle
    if (_cards.isNotEmpty) {
      print('[PHASE10-SHUFFLE] First few cards before shuffle:');
      for (int i = 0; i < Math.min(5, _cards.length); i++) {
        print('[PHASE10-SHUFFLE]   ${i+1}. ${_cards[i]}');
      }
    }

    // timestamp for shuffle debugging
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    print('[PHASE10-SHUFFLE] Shuffle operation stated at: $timestamp');
    
    // create a simple random instance
    final random = Math.Random();
    
    // Fisher-Yates shuffle
    for (int i = _cards.length - 1; i > 0; i--) {
      int n = random.nextInt(i + 1);
      // add swap logging for debugging
      print('[PHASE10-SHUFFLE] Swapping index $i (${_cards[i]}) with index $n (${_cards[n]})');
      Card temp = _cards[i];
      _cards[i] = _cards[n];
      _cards[n] = temp;
    }
    
    // show a few cards after shuffle
    if (_cards.isNotEmpty) {
      print('[PHASE10-SHUFFLE] First few cards after shuffle:');
      for (int i = 0; i < Math.min(5, _cards.length); i++) {
        print('[PHASE10-SHUFFLE]   ${i+1}. ${_cards[i]}');
      }
    }

    // last card logging to verify full deck shuffle
    print('[PHASE10-SHUFFLE] Last few cards after shuffle:');
    for (int i = Math.max(0, _cards.length - 5); i < _cards.length; i++) {
      print('[PHASE10-SHUFFLE]  ${i+1}. ${_cards[i]}');
    }
    
    // log card distribution after shuffle
    _logCardDistribution('AFTER');

    print('[PHASE10-SHUFFLE] Shuffle complete\n');
  }

  void _logCardDistribution(String stage) {
    print('[PHASE10-SHUFFLE] Card distribution $stage shuffle:');
    
    // Count by type
    int numberCards = 0;
    int wildCards = 0;
    int skipCards = 0;
    
    // Count by color
    Map<CardColor, int> colorCounts = {};
    for (CardColor color in colors) {
      colorCounts[color] = 0;
    }
    colorCounts[CardColor.wild] = 0;
    
    // Count by value (for number cards)
    Map<int, int> valueCounts = {};
    for (int i = 1; i <= 12; i++) {
      valueCounts[i] = 0;
    }
    
    // Count cards
    for (Card card in _cards) {
      if (card.type == CardType.number) {
        numberCards++;
        colorCounts[card.color] = (colorCounts[card.color] ?? 0) + 1;
        valueCounts[card.value] = (valueCounts[card.value] ?? 0) + 1;
      } else if (card.type == CardType.wild) {
        wildCards++;
        colorCounts[CardColor.wild] = (colorCounts[CardColor.wild] ?? 0) + 1;
      } else if (card.type == CardType.skip) {
        skipCards++;
        colorCounts[CardColor.wild] = (colorCounts[CardColor.wild] ?? 0) + 1;
      }
    }
    
    // Log counts
    print('[PHASE10-SHUFFLE]   Card types: number=$numberCards, wild=$wildCards, skip=$skipCards');
    print('[PHASE10-SHUFFLE]   Colors: ${colorCounts.toString()}');
    print('[PHASE10-SHUFFLE]   Values: ${valueCounts.toString()}');
  }

  // draw a card from the top of the deck
  Card draw() {
    if (_cards.isEmpty) {
      throw StateError('Cannot draw from an empty deck');
    }

    final card = _cards.removeAt(0);
    print('[PHASE10-DRAW] Drawing card: $card from deck, ${_cards.length} cards remaining.');

    if (_cards.isNotEmpty) {
      print('[PHASE10-DRAW] Next card in deck: ${_cards[0]}');
    }

    return card;

  }

  // check if the deck is empty
  bool get isEmpty => _cards.isEmpty;
  
  // get number of remaining cards
  int get length => _cards.length;
  
  // convert deck to json for persistence/network
  Map<String, dynamic> toJson() {
    return {
      'cards': _cards.map((card) => card.toJson()).toList(),
    };
  }
  
  // create deck from json for persistence/network
  factory Deck.fromJson(Map<String, dynamic> json) {
    final List<dynamic> cardsData = json['cards'] as List<dynamic>;
    final List<Card> cards = cardsData
        .map((cardData) => Card.fromJson(cardData as Map<String, dynamic>))
        .toList();
    
    return Deck.fromCards(cards);
  }
  
  // add multiple cards to the deck (for recycling discard pile)
  void addCards(List<Card> cards) {
    _cards.addAll(cards);
  }
  
  // peek at the top card without removing it
  Card? peek() {
    if (_cards.isEmpty) return null;
    return _cards.last;
  }
  
  // get all cards (for debugging or serialization)
  List<Card> get cards => List.unmodifiable(_cards);
}