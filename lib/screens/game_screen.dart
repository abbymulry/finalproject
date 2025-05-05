import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import '../models/game.dart';
import '../models/player.dart';
import '../models/card.dart' as game_card;
import '../services/game_session.dart';

class GameScreen extends StatefulWidget {
  final Game engine;
  const GameScreen({super.key, required this.engine});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late String userName;
  bool _isProcessingTurn = false;
  List<game_card.Card> _selectedCards = [];
  bool _phaseAttemptedThisTurn = false;
  bool _hasDrawnThisTurn = false;
  game_card.Card? _drawnCard;
  
  @override
  void initState() {
    super.initState();
    // set the user name to the first player in the list for testing
    userName = widget.engine.players[0].name;
    print('[PHASE10] Human player identified as: $userName');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[PHASE10] Post-frame callback executed');
      try {
        if (widget.engine.currentPlayer.name != userName) {
          print('[PHASE10] Starting AI turn from initState');
          _handleAiTurn();
        } else {
          print('[PHASE10] It is player turn, waiting for user input');
          // log player hand at the start of the game
          _logPlayerHand(userName, widget.engine.players[0].hand);
        }
      } catch (e) {
        _handleError('Error in post-frame callback', e);
      }
    });
  }

  void _log(String message) {
    print('[PHASE10] $message');
  }

  // method for consistent player logging
  void _logPlayerAction(String playerName, String action, String details) {
    print('[PHASE10-PLAYER] $playerName $action: $details');
  }

  // method for logging player hand
  void _logPlayerHand(String playerName, List<game_card.Card> hand) {
    print('[PHASE10-PLAYER] $playerName current hand: ${hand.length} cards');
    for (int i = 0; i < hand.length; i++) {
      print('[PHASE10-PLAYER]   ${i+1}. ${hand[i]}');
    }
  }

  void _handleError(String message, Object error) {
    _log('ERROR: $message: $error');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$message: $error')),
      );
    }
  }

  void _handleAiTurn() async {
    _log('Entering _handleAiTurn()');
    
    if (_isProcessingTurn) {
      _log('Turn already being processed, exiting AI turn');
      return;
    }
    
    _isProcessingTurn = true;
    _log('Setting _isProcessingTurn = true');
    
    final ai = widget.engine.currentPlayer;
    _log('AI player: ${ai.name}');
    
    // log AI hand at the start of the round
    _logPlayerHand(ai.name, ai.hand);
    
    try {
      // make sure it's actually an AI player's turn
      if (ai.name == userName) {
        _log('Not actually AI turn, it is user turn. Exiting AI turn.');
        _isProcessingTurn = false;
        return;
      }
      
      _log('AI turn delay starting');
      await Future.delayed(const Duration(seconds: 1));
      _log('AI turn delay finished');

      if (widget.engine.deck.isEmpty) {
        _handleError('Deck is empty', 'Cannot draw card');
        _isProcessingTurn = false;
        return;
      }

      // AI draws a card
      _log('AI drawing card');
      setState(() {
        _logPlayerAction(ai.name, 'drawing card from deck', '');
        
        ai.drawCard(widget.engine.deckObject);
        
        // detailed logging after AI Draws
        _logPlayerAction(ai.name, 'drew', '${ai.hand.last}');
        _logPlayerAction(ai.name, 'hand size now', '${ai.hand.length}');
        _logPlayerHand(ai.name, ai.hand);
        _logPlayerAction(ai.name, 'hasDrawn set to', 'true');
        
        _log('AI drew card: ${ai.hand.last}');
        _log('AI hasDrawn = ${ai.hasDrawn}');
      });

      _log('AI attempt phase delay starting');
      await Future.delayed(const Duration(milliseconds: 500));
      _log('AI attempt phase delay finished');

      // AI attempts to complete phase
      _log('AI attempting phase');
      setState(() {
        // logging before AI attempts a phase
        _logPlayerAction(ai.name, 'attempting phase', '');
        
        bool success = ai.attemptPhase();
        
        // logging after AI attempts a phase
        _logPlayerAction(ai.name, 'phase attempt result', success ? 'Success' : 'Failed');
        
        _log('AI phase attempt result: ${success ? 'Success' : 'Failed'}');
        _log('AI hasLaidDown = ${ai.hasLaidDown}');
      });

      _log('AI discard delay starting');
      await Future.delayed(const Duration(milliseconds: 500));
      _log('AI discard delay finished');

      // AI discards a card if it has cards left
      if (ai.hand.isNotEmpty) {
        _logPlayerAction(ai.name, 'discarding card', '${ai.hand.first}');
        
        _log('AI discarding card: ${ai.hand.first}');
        setState(() {
          ai.discard(ai.hand.first, widget.engine.discardPile);
        
          _logPlayerAction(ai.name, 'discarded card, hand size now', '${ai.hand.length}');
          _logPlayerHand(ai.name, ai.hand);
          
          _log('Top card on discard pile: ${widget.engine.discardPile.last}');
        });
      } else {
        _log('AI has no cards to discard');
      }

      // check if AI won the round
      if (ai.hasEmptyHand) {
        _log('AI has empty hand, won the round');
        _logPlayerAction(ai.name, 'has empty hand', 'won the round!');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ai.name} wins the round!'))
        );
        ai.currentPhase++;
        widget.engine.resetHands();
        _log('Hands reset after AI win');
      }

      // move to next turn
      _log('Moving to next turn');
      setState(() {
        widget.engine.nextTurn();
        _log('Current player after nextTurn: ${widget.engine.currentPlayer.name}');
        _log('hasDrawn status after nextTurn: ${widget.engine.currentPlayer.hasDrawn}');
      });
      
      // allow a small delay before processing another turn
      _log('Delay before checking next turn');
      await Future.delayed(const Duration(milliseconds: 300));
      _isProcessingTurn = false;
      _log('Setting _isProcessingTurn = false');
      
      // if it's still AI's turn, process the next AI turn
      if (widget.engine.currentPlayer.name != userName) {
        _log('Still AI turn, continuing AI turns');
        _handleAiTurn();
      } else {
        _log('Now user turn, waiting for user input');
        // reset turn state for player
        _hasDrawnThisTurn = false;
        _phaseAttemptedThisTurn = false;
        _drawnCard = null;
      }
    } catch (e) {
      _handleError('AI turn error', e);
      _isProcessingTurn = false;
      _log('Setting _isProcessingTurn = false after error');
    }
  }

  void _toggleCardSelection(game_card.Card card) {
    setState(() {
      if (_selectedCards.any((c) => c.id == card.id)) {
        _selectedCards.removeWhere((c) => c.id == card.id);
      } else {
        _selectedCards.add(card);
      }
      _log('Selected cards: ${_selectedCards.length}');
    });
  }

  void _drawFromDeck(Player player) {
    if (_hasDrawnThisTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You already drew a card this turn'))
      );
      return;
    }
    
    try {
      if (widget.engine.deck.isEmpty) {
        _handleError('Deck is empty', 'Cannot draw card');
        return;
      }
      
      // log before draw
      _logPlayerAction(player.name, 'drawing card', 'from deck');
      _logPlayerHand(player.name, player.hand);
      
      setState(() {
        _drawnCard = widget.engine.drawCard();
        player.hand.add(_drawnCard!);
        _hasDrawnThisTurn = true;
        
        // log after draw
        _logPlayerAction(player.name, 'drew card', '$_drawnCard from deck');
        _logPlayerAction(player.name, 'hand size now', '${player.hand.length}');
        _logPlayerHand(player.name, player.hand);
        _logPlayerAction(player.name, 'hasDrawn set to', 'true');
        
        _log('Drew card from deck: $_drawnCard');
      });
    } catch (e) {
      _handleError('Error drawing from deck', e);
    }
  }

  bool _canTakeFromDiscard() {
    if (_hasDrawnThisTurn || widget.engine.discardPile.isEmpty) {
      return false;
    }
    
    // check if top card is a skip to disable picking it up
    final topCard = widget.engine.discardPile.last;
    return topCard.type != game_card.CardType.skip;
  }

  void _drawFromDiscard(Player player) {
    if (!_canTakeFromDiscard()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot take card from discard pile'))
      );
      return;
    }
    
    try {
      // log before draw from discard
      _logPlayerAction(player.name, 'drawing card', 'from discard pile');
      _logPlayerHand(player.name, player.hand);
      
      setState(() {
        _drawnCard = widget.engine.drawFromDiscard();
        player.hand.add(_drawnCard!);
        _hasDrawnThisTurn = true;
        
        // log after draw from discard
        _logPlayerAction(player.name, 'drew card', '$_drawnCard from discard');
        _logPlayerAction(player.name, 'hand size now', '${player.hand.length}');
        _logPlayerHand(player.name, player.hand);
        _logPlayerAction(player.name, 'hasDrawn set to', 'true');
        
        _log('Drew card from discard: $_drawnCard');
      });
    } catch (e) {
      _handleError('Error drawing from discard', e);
    }
  }

  bool _canAttemptPhase(Player player) {
    return _hasDrawnThisTurn && 
           !player.hasLaidDown && 
           _selectedCards.isNotEmpty && 
           !_phaseAttemptedThisTurn;
  }

  void _attemptPhase(Player player) {
    if (!_canAttemptPhase(player)) {
      String reason = !_hasDrawnThisTurn ? "Draw a card first" : 
                     player.hasLaidDown ? "You've already completed your phase" :
                     _selectedCards.isEmpty ? "Select cards first" :
                     "You've already attempted a phase this turn";
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reason))
      );
      return;
    }
    
    try {
      // log before phase attempt
      _logPlayerAction(player.name, 'attempting phase', 'with ${_selectedCards.length} cards');
      _logPlayerAction(player.name, 'selected cards', _selectedCards.map((c) => c.toString()).join(', '));
      
      // group cards for phase attempt
      List<List<String>> cardGroups = [_selectedCards.map((c) => c.id).toList()];
      
      bool success = widget.engine.playPhase(cardGroups);
      
      // log after phase attempt
      _logPlayerAction(player.name, 'phase attempt result', success ? 'Success' : 'Failed');
      _logPlayerAction(player.name, 'hasLaidDown', '${player.hasLaidDown}');
      
      if (success) {
        setState(() {
          _phaseAttemptedThisTurn = true;
          _selectedCards.clear();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Phase completed!'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Phase attempt failed. Check requirements.'))
        );
      }
    } catch (e) {
      _handleError('Error attempting phase', e);
    }
  }

  bool _canEndTurn(Player player) {
    return _hasDrawnThisTurn;
  }

  void _endTurn(Player player, game_card.Card cardToDiscard) {
    if (!_canEndTurn(player)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must draw a card before ending your turn'))
      );
      return;
    }
    
    if (_isProcessingTurn) {
      _log('Turn already processing, ignoring end turn');
      return;
    }
    
    _isProcessingTurn = true;
    
    try {
      // log before discard
      _logPlayerAction(player.name, 'discarding card', cardToDiscard.toString());
      _logPlayerHand(player.name, player.hand);
      
      setState(() {
        // discard the selected card
        player.discard(cardToDiscard, widget.engine.discardPile);
        
        // log after discard
        _logPlayerAction(player.name, 'discarded card, hand size now', '${player.hand.length}');
        _logPlayerHand(player.name, player.hand);
        _logPlayerAction(player.name, 'top card on discard pile', '${widget.engine.discardPile.last}');
        
        // check if player won the round
        if (player.hasEmptyHand) {
          _logPlayerAction(player.name, 'has empty hand', 'won the round!');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${player.name} wins the round!'))
          );
          player.currentPhase++;
          widget.engine.resetHands();
          _logPlayerAction(player.name, 'hands reset after win', '');
        }
        
        // reset state for next turn
        _hasDrawnThisTurn = false;
        _phaseAttemptedThisTurn = false;
        _drawnCard = null;
        _selectedCards.clear();
        
        _logPlayerAction(player.name, 'ending turn', '');
        
        // move to next player
        widget.engine.nextTurn();
        
        _logPlayerAction(widget.engine.currentPlayer.name, 'starting turn', '');
      });
      
      // allow some time for the UI to update
      Future.delayed(const Duration(milliseconds: 300), () {
        _isProcessingTurn = false;
        
        // check if AI's turn after user plays
        if (widget.engine.currentPlayer.name != userName) {
          _handleAiTurn();
        }
      });
    } catch (e) {
      _handleError('Error ending turn', e);
      _isProcessingTurn = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.engine.currentPlayer;
    final isUserTurn = player.name == userName;
    
    return Scaffold(
      appBar: AppBar(
        title: Text("${player.name}'s Turn"),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isUserTurn ? Icons.person : Icons.computer,
                  color: isUserTurn ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  isUserTurn ? "Your Turn" : "AI Turn",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isUserTurn ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Current Phase: ${player.currentPhase}",
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              "Phase Completed: ${player.hasLaidDown ? 'Yes' : 'No'}",
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              "Cards Drawn This Turn: ${_hasDrawnThisTurn ? 'Yes' : 'No'}",
              style: const TextStyle(fontSize: 16),
            ),
            if (_selectedCards.isNotEmpty)
              Text(
                "Selected Cards: ${_selectedCards.length}",
                style: const TextStyle(fontSize: 16, color: Colors.blue),
              ),
            const SizedBox(height: 20),
            
            // draw and Discard Areas
            Row(
              children: [
                // deck area
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text("Draw Deck", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text("Cards: ${widget.engine.deck.length}"),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: isUserTurn && !_hasDrawnThisTurn ? 
                            () => _drawFromDeck(player) : null,
                          child: const Text("Draw Card"),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // discard pile area
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text("Discard Pile", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          widget.engine.discardPile.isNotEmpty 
                            ? widget.engine.discardPile.last.toString()
                            : "Empty",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: isUserTurn && _canTakeFromDiscard() ? 
                            () => _drawFromDiscard(player) : null,
                          child: const Text("Take Card"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // phase Actions
            if (isUserTurn)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _canAttemptPhase(player) ? 
                      () => _attemptPhase(player) : null,
                    child: const Text("Attempt Phase"),
                  ),
                  ElevatedButton(
                    onPressed: _selectedCards.isNotEmpty ? 
                      () => setState(() => _selectedCards.clear()) : null,
                    child: const Text("Clear Selection"),
                  ),
                ],
              ),
            
            const SizedBox(height: 20),
            
            // player Hand
            const Text("Your Hand:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: player.hand.map((card) {
                    final isSelected = _selectedCards.any((c) => c.id == card.id);
                    final isNewCard = _drawnCard?.id == card.id;
                    
                    return GestureDetector(
                      onTap: isUserTurn ? () {
                        // if we've drawn a card this turn
                        if (_hasDrawnThisTurn) {
                          // if card is already selected, deselect it
                          if (isSelected) {
                            _toggleCardSelection(card);
                          } 
                          // if no cards are selected, this might be a discard action
                          else if (_selectedCards.isEmpty) {
                            // show discard confirmation
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Card Action'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('What do you want to do with ${card.toString()}?'),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _toggleCardSelection(card);
                                      },
                                      child: const Text('Select for Phase'),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _endTurn(player, card);
                                      },
                                      child: const Text('Discard & End Turn'),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              ),
                            );
                          }
                          // otherwise, select the card
                          else {
                            _toggleCardSelection(card);
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Draw a card first'))
                          );
                        }
                      } : null,
                      child: Container(
                        width: 70,
                        height: 100,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade200 : 
                                isNewCard ? Colors.green.shade100 : Colors.white,
                          border: Border.all(
                            color: isSelected ? Colors.blue : 
                                  isNewCard ? Colors.green : Colors.grey,
                            width: isSelected || isNewCard ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            card.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: isSelected || isNewCard ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}