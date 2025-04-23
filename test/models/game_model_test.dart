// test/models/game_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:finalproject/models/card.dart';
import 'package:finalproject/models/player.dart';
import 'package:finalproject/models/phase.dart';
import 'package:finalproject/models/game.dart';

void main() {
  group('Game Creation Tests', () {
    test('Game should initialize correctly', () {
      final player1 = Player(id: 'p1', name: 'Player 1');
      final player2 = Player(id: 'p2', name: 'Player 2');
      
      // create a basic deck for testing
      final testDeck = [
        Card(id: '1', type: CardType.number, value: 5, color: CardColor.red),
        Card(id: '2', type: CardType.number, value: 6, color: CardColor.blue),
      ];
      
      final game = Game(
        id: 'test-game',
        players: [player1, player2],
        deck: testDeck,
      );
      
      expect(game.id, 'test-game');
      expect(game.players.length, 2);
      expect(game.deck.length, 2);
      expect(game.currentPlayerIndex, 0);
      expect(game.state, GameState.waiting);
    });
    
    test('Game.newGame() should create a game with proper setup', () {
      final player1 = Player(id: 'p1', name: 'Player 1');
      final player2 = Player(id: 'p2', name: 'Player 2');
      
      final game = Game.newGame(
        id: 'new-game',
        players: [player1, player2],
      );
      
      // check game state
      expect(game.state, GameState.playing);
      
      // check player hands
      expect(game.players[0].hand.length, 10);
      expect(game.players[1].hand.length, 10);
      
      // check deck and discard
      expect(game.discardPile.length, 1);
      
      // deck should have cards remaining
      expect(game.deck.isNotEmpty, true);
    });
  });
  
  group('Game Action Tests', () {
    late Game game;
    late Player player1;
    late Player player2;
    
    setUp(() {
      player1 = Player(id: 'p1', name: 'Player 1');
      player2 = Player(id: 'p2', name: 'Player 2');
      game = Game.newGame(
        id: 'action-test',
        players: [player1, player2],
      );
    });
    
    test('drawCard() should return a card and mark player as having drawn', () {
    final initialDeckSize = game.deck.length;
    
    final drawnCard = game.drawCard();
    
    // the card should be removed from the deck
    expect(game.deck.length, initialDeckSize - 1);
    // player should be marked as having drawn
    expect(game.currentPlayer.hasDrawn, true);
    // a card should be returned
    expect(drawnCard, isA<Card>());
    
    // now we need to manually add the card to the player's hand
    game.currentPlayer.hand.add(drawnCard);
    // now the hand size should increase
    expect(game.currentPlayer.hand.length, 11);
    });

    test('drawFromDiscard() should return top discard card', () {
    final initialHandSize = game.currentPlayer.hand.length;
    final topDiscard = game.discardPile.last;
    
    final drawnCard = game.drawFromDiscard();
    
    // the card should match the top discard
    expect(drawnCard, equals(topDiscard));
    // discard pile should be empty
    expect(game.discardPile.length, 0);
    // player should be marked as having drawn
    expect(game.currentPlayer.hasDrawn, true);
    
    // now we need to manually add the card to the player's hand
    game.currentPlayer.hand.add(drawnCard);
    // now the hand count should increase
    expect(game.currentPlayer.hand.length, initialHandSize + 1);
    });
  });
  

}