import 'package:finalproject/models/card.dart';
import 'package:finalproject/models/deck.dart';

class Player {
  final String id;
  final String name;
  List<Card> hand;
  List<List<Card>> completedPhases;
  int currentPhase;
  int score;
  bool hasDrawn;
  bool isSkipped;
  bool hasLaidDown;  

  Player({
    required this.id,
    required this.name,
    List<Card>? hand,
    List<List<Card>>? completedPhases,
    this.currentPhase = 1,
    this.score = 0,
    this.hasDrawn = false,
    this.isSkipped = false,
    this.hasLaidDown = false,  
  }) : hand = hand ?? [],
       completedPhases = completedPhases ?? [];

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      name: json['name'],
      hand: (json['hand'] as List<dynamic>).map((c) => Card.fromJson(c)).toList(),
      completedPhases: (json['completedPhases'] as List<dynamic>)
          .map((phase) => (phase as List<dynamic>)
              .map((c) => Card.fromJson(c))
              .toList())
          .toList(),
      currentPhase: json['currentPhase'],
      score: json['score'],
      hasDrawn: json['hasDrawn'],
      isSkipped: json['isSkipped'] ?? false,
      hasLaidDown: json['hasLaidDown'] ?? false,  
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hand': hand.map((c) => c.toJson()).toList(),
      'completedPhases': completedPhases
          .map((phase) => phase.map((c) => c.toJson()).toList())
          .toList(),
      'currentPhase': currentPhase,
      'score': score,
      'hasDrawn': hasDrawn,
      'isSkipped': isSkipped,
      'hasLaidDown': hasLaidDown,  
    };
  }

  int calculateHandScore() {
    return hand.fold(0, (sum, card) {
      if (card.type == CardType.skip) return sum + 15;
      if (card.type == CardType.wild) return sum + 25;
      return sum + card.value;
    });
  }

  bool hasCompletedCurrentPhase() {
    return currentPhase <= completedPhases.length;
  }
    
  Card drawCard(Deck deck) {
    print('[PHASE10] ${name} drawing card from deck');
    final card = deck.draw();
    hand.add(card);
    print('[PHASE10] ${name} drew ${card}');
    print('[PHASE10] ${name} hand size now: ${hand.length}');
    hasDrawn = true;  // Make sure this is being set!
    print('[PHASE10] ${name} hasDrawn set to ${hasDrawn}');
    return card;
}

  void discard(Card card, List<Card> discardPile) {
    print('[PHASE10] ${name} discarding card: ${card}');
    final index = hand.indexWhere((c) => c.id == card.id);
    if (index == -1) {
      print('[PHASE10] Error: Card not found in hand!');
      throw Exception('Card not in hand');
    }
    final removedCard = hand.removeAt(index);
    discardPile.add(removedCard);
    print('[PHASE10] ${name} discarded card, hand size now: ${hand.length}');
  }

  bool attemptPhase() {
    var freq = <int, int>{};
    for (var card in hand) {
      if (card.type == CardType.number) {
        freq[card.value] = (freq[card.value] ?? 0) + 1;
      }
    }
    if (freq.values.any((count) => count >= 3)) {
      hasLaidDown = true;
      return true;
    }
    return false;
  }

  bool get hasEmptyHand => hand.isEmpty;
}