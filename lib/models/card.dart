// phase 10 card model
// ==============================================================
//
// this file defines the card class which represents the individual playing cards in our phase 10 game
//
// phase 10 uses a deck with:
// - number cards (1-12) in four colors (red, blue, green, yellow)
// - wild cards that can substitute for any card
// - skip cards that cause the next player to lose their turn
//
// in case we want to add multiplayer functionality I tried adding some card conversion
// - fromJson: converts network data into card objects
// - toJson: prepares card objects for network transmission
//
// the card conversion hopefully allows cards to be:
// 1. stored in the database as json
// 2. sent between clients during gameplay
// 3. reconstructed into objects on the receiving end
// 
// the card properties are final to prevent accidental state changes during the game
// ==============================================================




// card class represents a single card in the phase 10 game
class Card {
  final String id;
  final CardType type;
  final int value;
  final CardColor color;

  Card({
    required this.id,
    required this.type,
    required this.value,
    required this.color,
  });

  // create a card from json data for network transmission
  factory Card.fromJson(Map<String, dynamic> json) {
    return Card(
      id: json['id'],
      type: CardType.values[json['type']],
      value: json['value'],
      color: CardColor.values[json['color']],
    );
  }

  // convert card to json for network transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'value': value,
      'color': color.index,
    };
  }
  
  // helper function to check if two cards match in value
  bool matchesValue(Card other) {
    return value == other.value || type == CardType.wild || other.type == CardType.wild;
  }
  
  // helper function to check if two cards match in color
  bool matchesColor(Card other) {
    return color == other.color || color == CardColor.wild || other.color == CardColor.wild;
  }
  
  // string representation for debugging
  @override
  String toString() {
    return '${color.name} ${type == CardType.number ? value.toString() : type.name}';
  }
}

// types of cards in the game
enum CardType { number, wild, skip }

// colors available for cards
enum CardColor { red, blue, green, yellow, wild }