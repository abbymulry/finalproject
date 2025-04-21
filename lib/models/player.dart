// phase 10 player model
// ==============================================================
//
// this file defines the player class that represents each player
//
// in phase 10, each player:
// - has a hand of cards
// - works through 10 different phases in sequence
// - completes phases by playing specific card combinations
// - scores points based on cards left in hand at the end of rounds
// - aims to complete all phases with the lowest score
//
// the json serialization is an attempt to support multiplayer functionality:
// - it allows player state to be synchronized across devices
// - allows persistent storage of game progress
// - allows real-time updates during gameplay
// 
// player objects track:
// 1. identity (id, name)
// 2. game progress (current phase, completed phases)
// 3. current state (hand, score, turn status)
//
// to demonstrate the nested structures/formats below, this is what the object lists and jsons list would look like 
//
//          JSON:
// {
//  "id": "player1",
//  "name": "Ashton",
//  "hand": [
//    {"id": "card1", "type": 0, "value": 7, "color": 2},
//    {"id": "card2", "type": 1, "value": 3, "color": 4}
//  ],
//  "completedPhases": [
//    [
//      {"id": "card3", "type": 0, "value": 2, "color": 1},
//      {"id": "card4", "type": 0, "value": 2, "color": 0},
//      {"id": "card5", "type": 0, "value": 2, "color": 3}
//    ],
//    [
//      {"id": "card6", "type": 0, "value": 8, "color": 0},
//      {"id": "card7", "type": 0, "value": 8, "color": 2},
//      {"id": "card8", "type": 0, "value": 8, "color": 3}
//    ]
// ],
//  "currentPhase": 3,
//  "score": 15,
//  "hasDrawn": false
//}
//
//          LIST:
//
// completedPhases = [
//  [
//    {id: "card3", type: 0, value: 2, color: 1},
//    {id: "card4", type: 0, value: 2, color: 0},
//    {id: "card5", type: 0, value: 2, color: 3}
//  ],
//  [
//    {id: "card6", type: 0, value: 8, color: 0},
//    {id: "card7", type: 0, value: 8, color: 2},
//    {id: "card8", type: 0, value: 8, color: 3}
//  ]
//]
//
// ==============================================================

// player class tracks a single player's state in the game
class Player {
  final String id;                 // unique identifier
  final String name;               // display name
  List<Card> hand;                 // cards currently held
  List<List<Card>> completedPhases; // phases the player has completed
  int currentPhase;                // phase the player is working on (1-10)
  int score;                       // cumulative score (lower is better)
  bool hasDrawn;                   // tracks if player has drawn a card this turn
  
  Player({
    required this.id,
    required this.name,
    this.hand = const [],
    this.completedPhases = const [],
    this.currentPhase = 1,
    this.score = 0,
    this.hasDrawn = false,
  });
  
  // create player from json for network transmission
  // this reconstructs a player object from data received over the network
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      name: json['name'],
      // cast the json value containing the player's hand to a list
      hand: (json['hand'] as List).map((c) => Card.fromJson(c)).toList(),
      // nested structure where there is a list of phases, and each phase has a list of cards 
      completedPhases: (json['completedPhases'] as List) // outer list
          .map((phase) => (phase as List) // for each phase in the outer list, cast it to the inner list
              .map((c) => Card.fromJson(c)) // convert the card json to a card object
              .toList()) // the card objects are then placed in a list which represents a phase
          .toList(), // working backwards, we now put all the phse objects into a list
      currentPhase: json['currentPhase'],
      score: json['score'],
      hasDrawn: json['hasDrawn'],
    );
  }
  
  // convert player to json for network transmission
  // this prepares player data to be sent over the network
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      // for each card in the hand, call the toJson function to convert each card to json 
      'hand': hand.map((c) => c.toJson()).toList(),
      // again working with a nested structure where: 
      'completedPhases': completedPhases // start with a list of completed phases
          .map((phase) => phase.map((c) => c.toJson()).toList()) // for each phase (list of cards), convert each card to json
          .toList(), // convert all phases into a list to be converted to json format
      'currentPhase': currentPhase,
      'score': score,
      'hasDrawn': hasDrawn,
    };
  }
  
  // calculate the score from remaining cards in hand
  // score is calculated at the end of each round based on the value of cards remaining in a player's hand:
  // - number cards: face value
  // - skip cards: 15 points
  // - wild cards: 25 points
  // lower scores are better
  int calculateHandScore() {
    return hand.fold(0, (sum, card) {
      if (card.type == CardType.skip) return sum + 15;
      if (card.type == CardType.wild) return sum + 25;
      return sum + card.value;
    });
  }
  
  // check if player has completed their current phase to determine if a player can start playing on the next phase
  bool hasCompletedCurrentPhase() {
    return currentPhase <= completedPhases.length;
  }
}