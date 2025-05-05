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

import 'dart:math';
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

  // create a new deck with all standard cards
  Deck() {
    _initializeCards();
    shuffle();
  }

  // initialize with predefined cards (for deserialization)
  Deck.fromCards(List<Card> cards) {
    _cards.clear();
    _cards.addAll(cards);
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

  // randomize the order of cards
  void shuffle() {
    _cards.shuffle(Random());
  }
  
  // draw a card from the top of the deck
  Card draw() {
    if (_cards.isEmpty) {
      throw StateError('Cannot draw from an empty deck');
    }
    return _cards.removeLast();
  }
  
  // check if the deck is empty
  bool get isEmpty => _cards.isEmpty;
  
  // get number of remaining cards
  int get cardsRemaining => _cards.length;
  
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