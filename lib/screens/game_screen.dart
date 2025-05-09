import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import '../models/game.dart';
import '../models/player.dart';
import '../models/card.dart' as game_card;
import '../services/game_session.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:async'; // For StreamSubscription
import '../services/game_multiplayer_service.dart'; // For GameMultiplayerService
import '../services/sound_player.dart';
import 'package:finalproject/screens/ai_brain.dart';

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
  File? _uploadedImage;
  List<game_card.Card> _manualCardEntries = [];
  final ImagePicker _picker = ImagePicker();

  // multiplayer functionality
  StreamSubscription<Game>? _gameSubscription;
  final GameMultiplayerService _multiplayerService = GameMultiplayerService();
  bool _isMultiplayerGame = false;

  @override
  void initState() {
    super.initState();

    // Determine if this is a multiplayer game by checking the game ID format
    _isMultiplayerGame =
        widget.engine.id.length == 6 &&
        widget.engine.id.toUpperCase() == widget.engine.id;

    // Set up multiplayer listener if this is a multiplayer game
    if (_isMultiplayerGame) {
      _setupMultiplayerListener();
    }

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

  // multiplayer listener setup
  void _setupMultiplayerListener() {
    print(
      '[PHASE10] Setting up multiplayer listener for game: ${widget.engine.id}',
    );
    _gameSubscription = _multiplayerService
        .listenToGame(widget.engine.id)
        .listen(
          (updatedGame) {
            // Only update if the game state has changed
            if (updatedGame.lastUpdated.isAfter(widget.engine.lastUpdated)) {
              print('[PHASE10] Received updated game state from server');
              setState(() {
                // Instead of trying to replace the entire engine, update its properties
                // Copy values from updatedGame to widget.engine
                // This is a workaround since we can't directly replace widget.engine

                // Update players (except for the local player's hand)
                final localPlayerIndex = widget.engine.players.indexWhere(
                  (p) => p.name == userName,
                );

                // Save the local player's hand if found
                List<game_card.Card>? localPlayerHand;
                if (localPlayerIndex >= 0) {
                  localPlayerHand = List.from(
                    widget.engine.players[localPlayerIndex].hand,
                  );
                }

                // Update game properties
                widget.engine.discardPile = updatedGame.discardPile;
                widget.engine.currentPlayerIndex =
                    updatedGame.currentPlayerIndex;
                widget.engine.state = updatedGame.state;

                // Update players
                for (int i = 0; i < widget.engine.players.length; i++) {
                  // For the local player, preserve their hand
                  if (i == localPlayerIndex && localPlayerHand != null) {
                    widget.engine.players[i].currentPhase =
                        updatedGame.players[i].currentPhase;
                    widget.engine.players[i].score =
                        updatedGame.players[i].score;
                    widget.engine.players[i].hasDrawn =
                        updatedGame.players[i].hasDrawn;
                    widget.engine.players[i].isSkipped =
                        updatedGame.players[i].isSkipped;
                    widget.engine.players[i].hasLaidDown =
                        updatedGame.players[i].hasLaidDown;
                    widget.engine.players[i].completedPhases =
                        updatedGame.players[i].completedPhases;
                    // Keep the existing hand
                  } else {
                    // For other players, update everything
                    widget.engine.players[i] = updatedGame.players[i];
                  }
                }

                // Reset game state variables after remote update
                _isProcessingTurn = false;
                _hasDrawnThisTurn =
                    widget.engine.currentPlayer.name == userName &&
                    widget.engine.currentPlayer.hasDrawn;
                _phaseAttemptedThisTurn = false;
                _drawnCard = null;
                _selectedCards.clear();

                print('[PHASE10] Game state updated from server');
                print(
                  '[PHASE10] Current player: ${widget.engine.currentPlayer.name}',
                );

                // If it's AI's turn after the update, handle it
                if (widget.engine.currentPlayer.name != userName) {
                  _handleAiTurn();
                }
              });
            }
          },
          onError: (error) {
            print('[PHASE10] Error listening to game updates: $error');
            _handleError('Multiplayer sync error', error);
          },
        );
  }

  // helper method for syncing game state
  Future<void> _syncGameState() async {
    if (_isMultiplayerGame) {
      try {
        print('[PHASE10] Syncing game state with server');
        await _multiplayerService.updateGameState(widget.engine);
        print('[PHASE10] Game state synced successfully');
      } catch (e) {
        _handleError('Failed to sync game state', e);
      }
    }
  }

  // cleanup for multiplayer subscription
  @override
  void dispose() {
    // cancel the subscription when the screen is disposed
    _gameSubscription?.cancel();
    super.dispose();
  }

  Future<void> _pickCardImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _uploadedImage = File(pickedFile.path);
        _manualCardEntries = [];
      });
    }
  }

  void _replaceHandWithManualEntries(Player player) {
    if (_manualCardEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add at least one card to replace your hand.'),
        ),
      );
      return;
    }

    setState(() {
      player.hand = List.from(_manualCardEntries);
      _uploadedImage = null;
      _manualCardEntries.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Your hand has been updated!')));
  }

  String getPhaseDescription(int phase) {
    switch (phase) {
      case 1:
        return "Two sets of 3 cards with the same number.";
      case 2:
        return "One set of 3 + one run of 4 consecutive numbers.";
      case 3:
        return "One set of 4 + one run of 4 consecutive numbers.";
      case 4:
        return "Run of 7 consecutive numbers.";
      case 5:
        return "Run of 8 consecutive numbers.";
      case 6:
        return "Run of 9 consecutive numbers.";
      case 7:
        return "Two sets of 4 cards with the same number.";
      case 8:
        return "7 cards all of the same color.";
      case 9:
        return "One set of 5 + one set of 2 cards.";
      case 10:
        return "One set of 5 + one set of 3 cards.";
      default:
        return "All phases completed!";
    }
  }

  String _getCardImagePath(game_card.Card card) {
    if (card.type == game_card.CardType.skip) return 'assets/skip.png';
    if (card.type == game_card.CardType.wild) return 'assets/wild.png';

    final color = card.color.name.toLowerCase();
    final value = _numberToWord(card.value);
    return 'assets/${color}${value}.png';
  }

  String _numberToWord(int number) {
    const words = [
      "zero",
      "one",
      "two",
      "three",
      "four",
      "five",
      "six",
      "seven",
      "eight",
      "nine",
      "ten",
      "eleven",
      "twelve",
    ];
    return (number >= 0 && number <= 12) ? words[number] : number.toString();
  }

  void _log(String message) {
    print('[PHASE10] $message');
  }

  // method to choose the best card to discard
  game_card.Card _chooseBestDiscard(List<game_card.Card> hand) {
    final nonWilds =
        hand.where((c) => c.type == game_card.CardType.number).toList();

    if (nonWilds.isEmpty) return hand.first;

    // Find least frequent number value
    Map<int, int> freq = {};
    for (var c in nonWilds) {
      freq[c.value] = (freq[c.value] ?? 0) + 1;
    }

    nonWilds.sort((a, b) => freq[a.value]!.compareTo(freq[b.value]!));
    return nonWilds.first;
  }

  // method for consistent player logging
  void _logPlayerAction(String playerName, String action, String details) {
    print('[PHASE10-PLAYER] $playerName $action: $details');
  }

  // method for logging player hand
  void _logPlayerHand(String playerName, List<game_card.Card> hand) {
    print('[PHASE10-PLAYER] $playerName current hand: ${hand.length} cards');
    for (int i = 0; i < hand.length; i++) {
      print('[PHASE10-PLAYER]   ${i + 1}. ${hand[i]}');
    }
  }

  void _handleError(String message, Object error) {
    _log('ERROR: $message: $error');
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$message: $error')));
    }
  }
// method to check if AI can attempt a phase but replaced with AI logic
/*  
  bool _attemptPhaseForAI(Player ai) {
    final phase = ai.currentPhase;
    final hand = List<game_card.Card>.from(ai.hand);

    List<List<game_card.Card>>? selectedGroups;

    switch (phase) {
      case 1: // Two sets of 3
        selectedGroups = _findSets(hand, [3, 3]);
        break;
      case 2: // One set of 3 + run of 4
        final sets = _findSets(hand, [3]);
        if (sets.isNotEmpty) {
          final remaining = _removeUsedCards(
            hand,
            sets.expand((e) => e).toList(),
          );
          final run = _findRun(remaining, 4);
          if (run != null) selectedGroups = [sets.first, run];
        }
        break;
      case 4: // Run of 7
        final run = _findRun(hand, 7);
        if (run != null) selectedGroups = [run];
        break;
      // Add other phases similarly...
      default:
        _log('AI logic not implemented for phase $phase');
    }

    if (selectedGroups == null) return false;

    final groupIds =
        selectedGroups.map((g) => g.map((c) => c.id).toList()).toList();
    final success = widget.engine.playPhase(groupIds);

    if (success) {
      _log('AI completed phase $phase with groups: $groupIds');
      
    }

    return success;
  }  */

  List<List<game_card.Card>> _findSets(
    List<game_card.Card> hand,
    List<int> sizes,
  ) {
    final Map<int, List<game_card.Card>> grouped = {};
    final wilds = hand.where((c) => c.type == game_card.CardType.wild).toList();
    final naturals = hand.where((c) => c.type == game_card.CardType.number);

    for (var card in naturals) {
      grouped.putIfAbsent(card.value, () => []).add(card);
    }

    final results = <List<game_card.Card>>[];

    for (final size in sizes) {
      bool found = false;
      for (final group in grouped.values) {
        if (group.length + wilds.length >= size) {
          final combined = List<game_card.Card>.from(group);
          while (combined.length < size && wilds.isNotEmpty) {
            combined.add(wilds.removeLast());
          }
          results.add(combined);
          found = true;
          break;
        }
      }
      if (!found) return [];
    }

    return results.length == sizes.length ? results : [];
  }

  List<game_card.Card> _removeUsedCards(
    List<game_card.Card> hand,
    List<game_card.Card> used,
  ) {
    final remaining = List<game_card.Card>.from(hand);
    for (var c in used) {
      remaining.remove(c);
    }
    return remaining;
  }

  List<game_card.Card>? _findRun(List<game_card.Card> hand, int runLength) {
    final wilds = hand.where((c) => c.type == game_card.CardType.wild).toList();
    final naturals =
        hand.where((c) => c.type == game_card.CardType.number).toSet().toList()
          ..sort((a, b) => a.value.compareTo(b.value));

    for (int i = 1; i <= 12 - runLength + 1; i++) {
      final run = <game_card.Card>[];
      final usedValues = <int>{};
      int needed = runLength;

      for (var v = i; v < i + runLength; v++) {
        final card = naturals.firstWhere(
          (c) => c.value == v && !usedValues.contains(c.value),
          orElse: () => throw Exception('Card not found'),
        );

        if (card != null) {
          run.add(card);
          usedValues.add(card.value);
          needed--;
        }
      }

      while (needed > 0 && wilds.isNotEmpty) {
        run.add(wilds.removeLast());
        needed--;
      }

      if (run.length == runLength) {
        return run;
      }
    }

    return null;
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

        final topDiscard =
            widget.engine.discardPile.isNotEmpty
                ? widget.engine.discardPile.last
                : null;

        bool shouldTakeDiscard =
            topDiscard != null &&
            topDiscard.type == game_card.CardType.number &&
            ai.hand.any(
              (card) =>
                  card.value == topDiscard.value ||
                  card.color == topDiscard.color,
            );

        if (shouldTakeDiscard) {
          ai.hand.add(widget.engine.drawFromDiscard());
          _log('AI drew from discard: $topDiscard');
        } else {
          ai.drawCard(widget.engine.deckObject);
          _log('AI drew from deck');
        }

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

        bool success = AIBrain.attemptPhase(widget.engine, ai);

        // logging after AI attempts a phase
        _logPlayerAction(
          ai.name,
          'phase attempt result',
          success ? 'Success' : 'Failed',
        );

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
          final discardCard = _chooseBestDiscard(ai.hand);
          ai.discard(discardCard, widget.engine.discardPile);
          _log('AI discarded: $discardCard');

          _logPlayerAction(
            ai.name,
            'discarded card, hand size now',
            '${ai.hand.length}',
          );
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

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${ai.name} wins the round!')));
        ai.currentPhase++;
        widget.engine.resetHands();
        _log('Hands reset after AI win');
      }

      // move to next turn
      _log('Moving to next turn');
      setState(() {
        widget.engine.nextTurn();
        _log(
          'Current player after nextTurn: ${widget.engine.currentPlayer.name}',
        );
        _log(
          'hasDrawn status after nextTurn: ${widget.engine.currentPlayer.hasDrawn}',
        );
      });

      // sync after AI actions are complete
      _syncGameState().then((_) {
        // allow a small delay before processing another turn
        _log('Delay before checking next turn');
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
      });
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
        SnackBar(content: Text('You already drew a card this turn')),
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
      // synch changes to firestore
      _syncGameState();
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
        SnackBar(content: Text('Cannot take card from discard pile')),
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

      _syncGameState();
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
      String reason =
          !_hasDrawnThisTurn
              ? "Draw a card first"
              : player.hasLaidDown
              ? "You've already completed your phase"
              : _selectedCards.isEmpty
              ? "Select cards first"
              : "You've already attempted a phase this turn";

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(reason)));
      return;
    }

    // log selected cards before attempt
    _logPlayerAction(
      player.name,
      'attempting phase',
      'with ${_selectedCards.length} cards',
    );
    for (var card in _selectedCards) {
      _logPlayerAction(player.name, 'selected card', card.toString());
    }

    try {
      // get the current phase number
      int phaseNumber = player.currentPhase;
      _logPlayerAction(player.name, 'current phase', phaseNumber.toString());

      // handle phase 1 specifically
      if (phaseNumber == 1) {
        _logPlayerAction(
          player.name,
          'phase 1 requirements',
          'two sets of three cards',
        );

        // group cards by their value
        Map<int, List<game_card.Card>> valueGroups = {};
        List<game_card.Card> wildCards = [];

        // separate wilds and group cards by value
        for (var card in _selectedCards) {
          if (card.type == game_card.CardType.wild) {
            wildCards.add(card);
            _logPlayerAction(
              player.name,
              'identified wild card',
              card.toString(),
            );
          } else {
            if (!valueGroups.containsKey(card.value)) {
              valueGroups[card.value] = [];
            }
            valueGroups[card.value]!.add(card);
          }
        }

        _logPlayerAction(
          player.name,
          'found unique values',
          valueGroups.keys.join(', '),
        );
        _logPlayerAction(
          player.name,
          'found wild cards',
          wildCards.length.toString(),
        );

        // identify values that could form sets
        List<int> validSetValues = [];
        Map<int, int> wildsNeededForSet = {};

        valueGroups.forEach((value, cards) {
          _logPlayerAction(
            player.name,
            'value $value has cards',
            cards.length.toString(),
          );

          if (cards.length >= 3) {
            // complete set without wilds
            validSetValues.add(value);
            wildsNeededForSet[value] = 0;
            _logPlayerAction(
              player.name,
              'value $value forms complete set',
              'no wilds needed',
            );
          } else if (cards.length + wildCards.length >= 3) {
            // could form a set with wilds
            int wildsNeeded = 3 - cards.length;
            validSetValues.add(value);
            wildsNeededForSet[value] = wildsNeeded;
            _logPlayerAction(
              player.name,
              'value $value could form set',
              'using $wildsNeeded wilds',
            );
          }
        });

        // sort values by fewest wilds needed
        validSetValues.sort(
          (a, b) => wildsNeededForSet[a]!.compareTo(wildsNeededForSet[b]!),
        );

        // check if we have at least two valid sets
        if (validSetValues.length >= 2) {
          _logPlayerAction(
            player.name,
            'identified valid sets',
            validSetValues.join(', '),
          );

          // create card groups for the phase
          List<List<String>> cardGroups = [];
          List<game_card.Card> remainingWilds = [...wildCards];

          // take the best two sets (needing fewest wilds)
          for (int i = 0; i < 2; i++) {
            int setValue = validSetValues[i];
            List<game_card.Card> setCards = [...valueGroups[setValue]!];

            // add wilds if needed
            int wildsNeeded = wildsNeededForSet[setValue]!;
            for (int w = 0; w < wildsNeeded && remainingWilds.isNotEmpty; w++) {
              setCards.add(remainingWilds.removeAt(0));
            }

            // convert to card IDs
            cardGroups.add(setCards.map((c) => c.id).toList());
            _logPlayerAction(
              player.name,
              'created set',
              'value $setValue with ${setCards.length} cards',
            );
          }

          // attempt to play the phase
          _logPlayerAction(
            player.name,
            'submitting phase',
            '${cardGroups.length} groups',
          );
          bool success = widget.engine.playPhase(cardGroups);

          if (success) {
            setState(() {
              _phaseAttemptedThisTurn = true;
              _selectedCards.clear();
            });

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Phase completed!')));
            print(
              'About to play success sound...',
            ); //Can delete this before submission
            SoundPlayer.playPhaseCompleteSound(); //Not working
            _logPlayerAction(player.name, 'phase attempt result', 'Success');
            _syncGameState();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Phase attempt failed. Check requirements.'),
              ),
            );
            _logPlayerAction(player.name, 'phase attempt result', 'Failed');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Need 2 sets of 3 cards each with the same numbers.',
              ),
            ),
          );
          _logPlayerAction(
            player.name,
            'phase attempt failed',
            'not enough valid sets',
          );
        }
        return;
      } else if (phaseNumber == 2) {
        _logPlayerAction(
          player.name,
          'phase 2 requirements',
          'one set of three and one run of four',
        );

        // separate number and wild cards
        Map<int, List<game_card.Card>> valueGroups = {};
        List<game_card.Card> wildCards = [];

        for (var card in _selectedCards) {
          if (card.type == game_card.CardType.wild) {
            wildCards.add(card);
            _logPlayerAction(
              player.name,
              'identified wild card',
              card.toString(),
            );
          } else {
            if (!valueGroups.containsKey(card.value)) {
              valueGroups[card.value] = [];
            }
            valueGroups[card.value]!.add(card);
          }
        }

        _logPlayerAction(
          player.name,
          'found unique values',
          valueGroups.keys.join(', '),
        );
        _logPlayerAction(
          player.name,
          'found wild cards',
          wildCards.length.toString(),
        );

        // find potential sets, same logic as phase 1
        List<int> potentialSetValues = [];
        Map<int, int> wildsNeededForSet = {};

        valueGroups.forEach((value, cards) {
          _logPlayerAction(
            player.name,
            'value $value has cards',
            cards.length.toString(),
          );

          if (cards.length >= 3) {
            // complete set without wilds
            potentialSetValues.add(value);
            wildsNeededForSet[value] = 0;
            _logPlayerAction(
              player.name,
              'value $value forms complete set',
              'no wilds needed',
            );
          } else if (cards.length + wildCards.length >= 3) {
            // could form a set with wilds
            int wildsNeeded = 3 - cards.length;
            potentialSetValues.add(value);
            wildsNeededForSet[value] = wildsNeeded;
            _logPlayerAction(
              player.name,
              'value $value could form set',
              'using $wildsNeeded wilds',
            );
          }
        });

        // new logic, finding potential runs
        bool foundValidRun = false;
        List<game_card.Card> runCards = [];

        // sort values to check for runs
        List<int> sortedValues = valueGroups.keys.toList()..sort();
        _logPlayerAction(
          player.name,
          'checking for runs with values',
          sortedValues.join(', '),
        );

        // try to find a run of 4 consecutive cards
        if (sortedValues.length + wildCards.length >= 4) {
          // find longest run
          int bestRunLength = 0;
          List<int> bestRunValues = [];
          int bestWildsNeeded =
              1000; // placeholder high number higher than the number of cards in the deck

          // try each value as a potential starting point
          for (int startValue in sortedValues) {
            List<int> currentRun = [];
            int wildsNeeded = 0;

            // check up to 10 consecutive values since the highest run required is 9
            for (int i = 0; i < 10; i++) {
              int expectedValue = startValue + i;

              if (valueGroups.containsKey(expectedValue)) {
                // we have this value
                currentRun.add(expectedValue);
              } else if (wildsNeeded < wildCards.length) {
                // use a wild card
                currentRun.add(expectedValue);
                wildsNeeded++;
              } else {
                // cant continue the run
                break;
              }
            }

            // check if this is a valid run of 4 or more cards
            if (currentRun.length >= 4) {
              _logPlayerAction(
                player.name,
                'found potential run',
                'starting at $startValue with length ${currentRun.length}, needing $wildsNeeded wilds',
              );

              // check if this is a better run than the previously stored run
              if (wildsNeeded < bestWildsNeeded ||
                  (wildsNeeded == bestWildsNeeded &&
                      currentRun.length > bestRunLength)) {
                bestRunLength = currentRun.length;
                bestRunValues = List.from(currentRun);
                bestWildsNeeded = wildsNeeded;
              }
            }
          }

          // check if we found a valid run
          if (bestRunLength >= 4) {
            // take just 4 card values for the run
            List<int> runValues = bestRunValues.sublist(0, 4);
            _logPlayerAction(
              player.name,
              'using run values',
              runValues.join(', '),
            );

            // create the run with the real cards and wild cards if needed (uses spread operator which essentially just copies from the wildCards list)
            List<game_card.Card> remainingWilds = [...wildCards];

            for (int value in runValues) {
              if (valueGroups.containsKey(value) &&
                  valueGroups[value]!.isNotEmpty) {
                // add a value card
                runCards.add(valueGroups[value]!.removeAt(0));
              } else {
                // add a wild card
                runCards.add(remainingWilds.removeAt(0));
              }
            }

            foundValidRun = true;
            _logPlayerAction(
              player.name,
              'created valid run',
              'with ${runCards.length} cards',
            );
          }
        }

        // check if we have both a set and a run
        if (potentialSetValues.isNotEmpty && foundValidRun) {
          // use the set that requires the fewest wild cards
          potentialSetValues.sort(
            (a, b) => wildsNeededForSet[a]!.compareTo(wildsNeededForSet[b]!),
          );
          int bestSetValue = potentialSetValues[0];

          // create the set
          List<game_card.Card> setCards = [];
          List<game_card.Card> remainingWilds = [...wildCards];

          // remove wilds that are already used in the run
          for (var card in runCards) {
            if (card.type == game_card.CardType.wild) {
              remainingWilds.remove(card);
            }
          }

          // add value cards to the set
          if (valueGroups.containsKey(bestSetValue)) {
            setCards.addAll(valueGroups[bestSetValue]!);
          }

          // add wilds if needed
          int wildsNeeded = Math.max(0, 3 - setCards.length);
          for (int i = 0; i < wildsNeeded && remainingWilds.isNotEmpty; i++) {
            setCards.add(remainingWilds.removeAt(0));
          }

          // create card groups for the phase
          List<List<String>> cardGroups = [
            setCards.map((c) => c.id).toList(),
            runCards.map((c) => c.id).toList(),
          ];

          _logPlayerAction(
            player.name,
            'created set',
            'value $bestSetValue with ${setCards.length} cards',
          );
          _logPlayerAction(
            player.name,
            'created run',
            'with ${runCards.length} cards',
          );

          // attempt to actually play the phase
          _logPlayerAction(
            player.name,
            'submitting phase',
            '${cardGroups.length} groups',
          );
          bool success = widget.engine.playPhase(cardGroups);

          if (success) {
            setState(() {
              _phaseAttemptedThisTurn = true;
              _selectedCards.clear();
            });

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Phase Completed!')));
            print(
              'About to play success sound...',
            ); //Can delete this before submission
            SoundPlayer.playPhaseCompleteSound();
            _logPlayerAction(player.name, 'phase attempt result', 'Success');
            _syncGameState();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Phase attempt failed, check requirements'),
              ),
            );
            _logPlayerAction(player.name, 'phase attempt result', 'Failed');
          }
        } else {
          if (!potentialSetValues.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Need a set of 3 cards with the same number'),
              ),
            );
            _logPlayerAction(
              player.name,
              'phase attempt failed',
              'no valid set found',
            );
          } else if (!foundValidRun) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Need a run of 4 consecutive cards')),
            );
            _logPlayerAction(
              player.name,
              'phase attempt failed',
              'no valid run found',
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Need both a set of 3 and a run of 4')),
            );
            _logPlayerAction(
              player.name,
              'phase attempt failed',
              'missing required groups',
            );
          }
        }
        return;
      } else if (phaseNumber == 3) {
        _logPlayerAction(
          player.name,
          'phase 3 requirements',
          'one set of four and one run of four',
        );

        // separate number and wild cards
        Map<int, List<game_card.Card>> valueGroups = {};
        List<game_card.Card> wildCards = [];

        for (var card in _selectedCards) {
          if (card.type == game_card.CardType.wild) {
            wildCards.add(card);
            _logPlayerAction(
              player.name,
              'identified wild card',
              card.toString(),
            );
          } else {
            if (!valueGroups.containsKey(card.value)) {
              valueGroups[card.value] = [];
            }
            valueGroups[card.value]!.add(card);
          }
        }

        _logPlayerAction(
          player.name,
          'found unique values',
          valueGroups.keys.join(', '),
        );
        _logPlayerAction(
          player.name,
          'found wild cards',
          wildCards.length.toString(),
        );

        // check for natural runs of 4 (runs that don't need wild cards)
        bool foundNaturalRun = false;
        List<int> naturalRunValues = [];
        List<game_card.Card> runCards = [];

        // sort values to check for runs
        List<int> sortedValues = valueGroups.keys.toList()..sort();
        _logPlayerAction(
          player.name,
          'checking for runs with values',
          sortedValues.join(', '),
        );

        // first, try to find runs that don't need wild cards
        for (int i = 0; i < sortedValues.length - 3; i++) {
          if (sortedValues[i] + 1 == sortedValues[i + 1] &&
              sortedValues[i] + 2 == sortedValues[i + 2] &&
              sortedValues[i] + 3 == sortedValues[i + 3]) {
            // we found a natural run of 4 consecutive values
            naturalRunValues = [
              sortedValues[i],
              sortedValues[i + 1],
              sortedValues[i + 2],
              sortedValues[i + 3],
            ];
            foundNaturalRun = true;
            _logPlayerAction(
              player.name,
              'found natural run',
              naturalRunValues.join(', '),
            );
            break;
          }
        }

        // if we found a natural run, use it and then try to form a set with remaining cards
        if (foundNaturalRun) {
          // create the run cards
          for (int value in naturalRunValues) {
            runCards.add(valueGroups[value]!.removeAt(0));
          }
          _logPlayerAction(
            player.name,
            'created natural run',
            'with ${runCards.length} cards',
          );

          // now try to form a set with remaining cards
          List<game_card.Card> setCards = [];
          int bestSetValue = -1;
          int fewestWildsNeeded = 5; // more than we could possibly need

          // find the value that can form a set with the fewest wild cards
          valueGroups.forEach((value, cards) {
            if (cards.length >= 4) {
              // complete set without wilds
              bestSetValue = value;
              fewestWildsNeeded = 0;
              _logPlayerAction(
                player.name,
                'found natural set of 4',
                'value $value',
              );
            } else if (cards.length + wildCards.length >= 4 &&
                (4 - cards.length) < fewestWildsNeeded) {
              // could form a set with wilds
              bestSetValue = value;
              fewestWildsNeeded = 4 - cards.length;
              _logPlayerAction(
                player.name,
                'found potential set',
                'value $value needs $fewestWildsNeeded wilds',
              );
            }
          });

          if (bestSetValue >= 0 && fewestWildsNeeded <= wildCards.length) {
            // add value cards to the set
            setCards.addAll(valueGroups[bestSetValue]!);

            // add wild cards if needed
            for (int i = 0; i < fewestWildsNeeded; i++) {
              setCards.add(wildCards[i]);
            }

            _logPlayerAction(
              player.name,
              'created set',
              'value $bestSetValue with ${setCards.length} cards',
            );

            // we have a valid phase!
            List<List<String>> cardGroups = [
              setCards.map((c) => c.id).toList(),
              runCards.map((c) => c.id).toList(),
            ];

            _logPlayerAction(
              player.name,
              'submitting phase',
              '${cardGroups.length} groups',
            );
            bool success = widget.engine.playPhase(cardGroups);

            if (success) {
              setState(() {
                _phaseAttemptedThisTurn = true;
                _selectedCards.clear();
              });

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Phase Completed!')));
              print(
                'About to play success sound...',
              ); //Can delete this before submission
              SoundPlayer.playPhaseCompleteSound();
              _logPlayerAction(player.name, 'phase attempt result', 'Success');
              _syncGameState();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Phase attempt failed, check requirements'),
                ),
              );
              _logPlayerAction(player.name, 'phase attempt result', 'Failed');
            }
            return;
          }
        }

        // if we don't have a natural run or couldn't form a set, try the normal approach
        // find potential runs, including ones that need wild cards
        bool foundValidRun = false;
        List<int> bestRunValues = [];
        int bestRunWildsNeeded = 1000;

        // try each value as a potential starting point
        for (int startValue in sortedValues) {
          List<int> currentRun = [];
          int wildsNeeded = 0;

          // check up to 10 consecutive values
          for (int i = 0; i < 10; i++) {
            int expectedValue = startValue + i;

            if (valueGroups.containsKey(expectedValue)) {
              // we have this value
              currentRun.add(expectedValue);
            } else if (wildsNeeded < wildCards.length) {
              // use a wild card
              currentRun.add(expectedValue);
              wildsNeeded++;
            } else {
              // cant continue the run
              break;
            }
          }

          // check if this is a valid run of 4 or more cards
          if (currentRun.length >= 4) {
            _logPlayerAction(
              player.name,
              'found potential run',
              'starting at $startValue with length ${currentRun.length}, needing $wildsNeeded wilds',
            );

            // check if this is a better run than previously found
            if (wildsNeeded < bestRunWildsNeeded) {
              bestRunWildsNeeded = wildsNeeded;
              bestRunValues = currentRun.sublist(0, 4);
              foundValidRun = true;
            }
          }
        }

        // find potential sets
        List<int> potentialSetValues = [];
        Map<int, int> wildsNeededForSet = {};

        valueGroups.forEach((value, cards) {
          if (cards.length >= 4) {
            // complete set without wilds
            potentialSetValues.add(value);
            wildsNeededForSet[value] = 0;
            _logPlayerAction(
              player.name,
              'value $value forms complete set',
              'no wilds needed',
            );
          } else if (cards.length + wildCards.length >= 4) {
            // could form a set with wilds
            int wildsNeeded = 4 - cards.length;
            potentialSetValues.add(value);
            wildsNeededForSet[value] = wildsNeeded;
            _logPlayerAction(
              player.name,
              'value $value could form set',
              'using $wildsNeeded wilds',
            );
          }
        });

        // check if we have both a run and a set that work with our wild cards
        if (foundValidRun && potentialSetValues.isNotEmpty) {
          // sort sets by fewest wilds needed
          potentialSetValues.sort(
            (a, b) => wildsNeededForSet[a]!.compareTo(wildsNeededForSet[b]!),
          );

          for (int setValue in potentialSetValues) {
            int setWildsNeeded = wildsNeededForSet[setValue]!;

            // check if we have enough wild cards for both the set and run
            if (setWildsNeeded + bestRunWildsNeeded <= wildCards.length) {
              // great! we can form both
              _logPlayerAction(
                player.name,
                'found valid combination',
                'set $setValue and run with ${bestRunValues.length} cards',
              );

              // create the set
              List<game_card.Card> setCards = [];
              List<game_card.Card> remainingWilds = List.from(wildCards);

              // add cards to the set
              if (valueGroups.containsKey(setValue)) {
                setCards.addAll(valueGroups[setValue]!);
              }

              // add wilds to the set
              for (int i = 0; i < setWildsNeeded; i++) {
                setCards.add(remainingWilds.removeAt(0));
              }

              // create the run
              List<game_card.Card> runCards = [];
              for (int value in bestRunValues) {
                if (valueGroups.containsKey(value) &&
                    valueGroups[value]!.isNotEmpty) {
                  // use a value card
                  runCards.add(valueGroups[value]!.removeAt(0));
                } else {
                  // use a wild card
                  runCards.add(remainingWilds.removeAt(0));
                }
              }

              // we have a valid phase!
              List<List<String>> cardGroups = [
                setCards.map((c) => c.id).toList(),
                runCards.map((c) => c.id).toList(),
              ];

              _logPlayerAction(
                player.name,
                'created set',
                'value $setValue with ${setCards.length} cards',
              );
              _logPlayerAction(
                player.name,
                'created run',
                'with ${runCards.length} cards',
              );

              _logPlayerAction(
                player.name,
                'submitting phase',
                '${cardGroups.length} groups',
              );
              bool success = widget.engine.playPhase(cardGroups);

              if (success) {
                setState(() {
                  _phaseAttemptedThisTurn = true;
                  _selectedCards.clear();
                });

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Phase Completed!')));
                print(
                  'About to play success sound...',
                ); //Can delete this before submission
                SoundPlayer.playPhaseCompleteSound();
                _logPlayerAction(
                  player.name,
                  'phase attempt result',
                  'Success',
                );
                _syncGameState();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Phase attempt failed, check requirements'),
                  ),
                );
                _logPlayerAction(player.name, 'phase attempt result', 'Failed');
              }
              return;
            }
          }
        }

        // if we get here, we couldn't form a valid phase
        if (potentialSetValues.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Need a set of 4 cards with the same number'),
            ),
          );
          _logPlayerAction(
            player.name,
            'phase attempt failed',
            'no valid set found',
          );
        } else if (!foundValidRun) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Need a run of 4 consecutive cards')),
          );
          _logPlayerAction(
            player.name,
            'phase attempt failed',
            'no valid run found',
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cannot form both a set of 4 and a run of 4 with selected cards',
              ),
            ),
          );
          _logPlayerAction(
            player.name,
            'phase attempt failed',
            'not enough cards for both requirements',
          );
        }
        return;
      } else if (phaseNumber == 4) {
        _logPlayerAction(
          player.name,
          'phase 4 requirements',
          'one run of seven',
        );

        // separate number and wild cards
        Map<int, List<game_card.Card>> valueGroups = {};
        List<game_card.Card> wildCards = [];

        for (var card in _selectedCards) {
          if (card.type == game_card.CardType.wild) {
            wildCards.add(card);
            _logPlayerAction(
              player.name,
              'identified wild card',
              card.toString(),
            );
          } else {
            if (!valueGroups.containsKey(card.value)) {
              valueGroups[card.value] = [];
            }
            valueGroups[card.value]!.add(card);
          }
        }

        _logPlayerAction(
          player.name,
          'found unique values',
          valueGroups.keys.join(', '),
        );
        _logPlayerAction(
          player.name,
          'found wild cards',
          wildCards.length.toString(),
        );

        // same logic as phase 2 finding potential runs
        bool foundValidRun = false;
        List<game_card.Card> runCards = [];

        // sort values to check for runs
        List<int> sortedValues = valueGroups.keys.toList()..sort();
        _logPlayerAction(
          player.name,
          'checking for runs with values',
          sortedValues.join(', '),
        );

        // try to find a run of 7 consecutive cards
        if (sortedValues.length + wildCards.length >= 7) {
          // find longest run
          int bestRunLength = 0;
          List<int> bestRunValues = [];
          int bestWildsNeeded =
              1000; // placeholder high number higher than the number of cards in the deck

          // try each value as a potential starting point
          for (int startValue in sortedValues) {
            List<int> currentRun = [];
            int wildsNeeded = 0;

            // check up to 10 consecutive values
            for (int i = 0; i < 10; i++) {
              int expectedValue = startValue + i;

              if (valueGroups.containsKey(expectedValue)) {
                // we have this value
                currentRun.add(expectedValue);
              } else if (wildsNeeded < wildCards.length) {
                // use a wild card
                currentRun.add(expectedValue);
                wildsNeeded++;
              } else {
                // cant continue the run
                break;
              }
            }

            // check if this is a valid run of 7 or more cards
            if (currentRun.length >= 7) {
              _logPlayerAction(
                player.name,
                'found potential run',
                'starting at $startValue with length ${currentRun.length}, needing $wildsNeeded wilds',
              );

              // check if this is a better run than the previously stored run
              if (wildsNeeded < bestWildsNeeded ||
                  (wildsNeeded == bestWildsNeeded &&
                      currentRun.length > bestRunLength)) {
                bestRunLength = currentRun.length;
                bestRunValues = List.from(currentRun);
                bestWildsNeeded = wildsNeeded;
              }
            }
          }

          // check if we found a valid run
          if (bestRunLength >= 7) {
            // take just 7 card values for the run
            List<int> runValues = bestRunValues.sublist(0, 7);
            _logPlayerAction(
              player.name,
              'using run values',
              runValues.join(', '),
            );

            // create the run with the real cards and wild cards if needed
            List<game_card.Card> remainingWilds = [...wildCards];

            for (int value in runValues) {
              if (valueGroups.containsKey(value) &&
                  valueGroups[value]!.isNotEmpty) {
                // add a value card
                runCards.add(valueGroups[value]!.removeAt(0));
              } else {
                // add a wild card
                runCards.add(remainingWilds.removeAt(0));
              }
            }

            foundValidRun = true;
            _logPlayerAction(
              player.name,
              'created valid run',
              'with ${runCards.length} cards',
            );
          }
        }

        if (foundValidRun) {
          // create card groups for the phase
          List<List<String>> cardGroups = [runCards.map((c) => c.id).toList()];

          // attempt to play the phase
          _logPlayerAction(
            player.name,
            'submitting phase',
            '${cardGroups.length} groups',
          );
          bool success = widget.engine.playPhase(cardGroups);

          if (success) {
            setState(() {
              _phaseAttemptedThisTurn = true;
              _selectedCards.clear();
            });

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Phase Completed!')));
            print(
              'About to play success sound...',
            ); //Can delete this before submission
            SoundPlayer.playPhaseCompleteSound();
            _logPlayerAction(player.name, 'phase attempt result', 'Success');
            _syncGameState();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Phase attempt failed, check requirements'),
              ),
            );
            _logPlayerAction(player.name, 'phase attempt result', 'Failed');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Need a run of 7 consecutive cards')),
          );
          _logPlayerAction(
            player.name,
            'phase attempt failed',
            'no valid run found',
          );
        }
        return;
      } else if (phaseNumber == 5) {
        _logPlayerAction(
          player.name,
          'phase 5 requirements',
          'one run of eight',
        );

        // separate number and wild cards
        Map<int, List<game_card.Card>> valueGroups = {};
        List<game_card.Card> wildCards = [];

        for (var card in _selectedCards) {
          if (card.type == game_card.CardType.wild) {
            wildCards.add(card);
            _logPlayerAction(
              player.name,
              'identified wild card',
              card.toString(),
            );
          } else {
            if (!valueGroups.containsKey(card.value)) {
              valueGroups[card.value] = [];
            }
            valueGroups[card.value]!.add(card);
          }
        }

        _logPlayerAction(
          player.name,
          'found unique values',
          valueGroups.keys.join(', '),
        );
        _logPlayerAction(
          player.name,
          'found wild cards',
          wildCards.length.toString(),
        );

        // same logic as phase 4 finding potential runs
        bool foundValidRun = false;
        List<game_card.Card> runCards = [];

        // sort values to check for runs
        List<int> sortedValues = valueGroups.keys.toList()..sort();
        _logPlayerAction(
          player.name,
          'checking for runs with values',
          sortedValues.join(', '),
        );

        // try to find a run of 8 consecutive cards
        if (sortedValues.length + wildCards.length >= 8) {
          // find longest run
          int bestRunLength = 0;
          List<int> bestRunValues = [];
          int bestWildsNeeded =
              1000; // placeholder high number higher than the number of cards in the deck

          // try each value as a potential starting point
          for (int startValue in sortedValues) {
            List<int> currentRun = [];
            int wildsNeeded = 0;

            // check up to 10 consecutive values
            for (int i = 0; i < 10; i++) {
              int expectedValue = startValue + i;

              if (valueGroups.containsKey(expectedValue)) {
                // we have this value
                currentRun.add(expectedValue);
              } else if (wildsNeeded < wildCards.length) {
                // use a wild card
                currentRun.add(expectedValue);
                wildsNeeded++;
              } else {
                // cant continue the run
                break;
              }
            }

            // check if this is a valid run of 8 or more cards
            if (currentRun.length >= 8) {
              _logPlayerAction(
                player.name,
                'found potential run',
                'starting at $startValue with length ${currentRun.length}, needing $wildsNeeded wilds',
              );

              // check if this is a better run than the previously stored run
              if (wildsNeeded < bestWildsNeeded ||
                  (wildsNeeded == bestWildsNeeded &&
                      currentRun.length > bestRunLength)) {
                bestRunLength = currentRun.length;
                bestRunValues = List.from(currentRun);
                bestWildsNeeded = wildsNeeded;
              }
            }
          }

          // check if we found a valid run
          if (bestRunLength >= 8) {
            // take just 8 card values for the run
            List<int> runValues = bestRunValues.sublist(0, 8);
            _logPlayerAction(
              player.name,
              'using run values',
              runValues.join(', '),
            );

            // create the run with the real cards and wild cards if needed
            List<game_card.Card> remainingWilds = [...wildCards];

            for (int value in runValues) {
              if (valueGroups.containsKey(value) &&
                  valueGroups[value]!.isNotEmpty) {
                // add a value card
                runCards.add(valueGroups[value]!.removeAt(0));
              } else {
                // add a wild card
                runCards.add(remainingWilds.removeAt(0));
              }
            }

            foundValidRun = true;
            _logPlayerAction(
              player.name,
              'created valid run',
              'with ${runCards.length} cards',
            );
          }
        }

        if (foundValidRun) {
          // create card groups for the phase
          List<List<String>> cardGroups = [runCards.map((c) => c.id).toList()];

          // attempt to play the phase
          _logPlayerAction(
            player.name,
            'submitting phase',
            '${cardGroups.length} groups',
          );
          bool success = widget.engine.playPhase(cardGroups);

          if (success) {
            setState(() {
              _phaseAttemptedThisTurn = true;
              _selectedCards.clear();
            });

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Phase Completed!')));
            print(
              'About to play success sound...',
            ); //Can delete this before submission
            SoundPlayer.playPhaseCompleteSound();
            _logPlayerAction(player.name, 'phase attempt result', 'Success');
            _syncGameState();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Phase attempt failed, check requirements'),
              ),
            );
            _logPlayerAction(player.name, 'phase attempt result', 'Failed');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Need a run of 8 consecutive cards')),
          );
          _logPlayerAction(
            player.name,
            'phase attempt failed',
            'no valid run found',
          );
        }
        return;
      } else if (phaseNumber == 6) {
        _logPlayerAction(
          player.name,
          'phase 6 requirements',
          'one run of nine',
        );

        // separate number and wild cards
        Map<int, List<game_card.Card>> valueGroups = {};
        List<game_card.Card> wildCards = [];

        for (var card in _selectedCards) {
          if (card.type == game_card.CardType.wild) {
            wildCards.add(card);
            _logPlayerAction(
              player.name,
              'identified wild card',
              card.toString(),
            );
          } else {
            if (!valueGroups.containsKey(card.value)) {
              valueGroups[card.value] = [];
            }
            valueGroups[card.value]!.add(card);
          }
        }

        _logPlayerAction(
          player.name,
          'found unique values',
          valueGroups.keys.join(', '),
        );
        _logPlayerAction(
          player.name,
          'found wild cards',
          wildCards.length.toString(),
        );

        // same logic as phase 4 finding potential runs
        bool foundValidRun = false;
        List<game_card.Card> runCards = [];

        // sort values to check for runs
        List<int> sortedValues = valueGroups.keys.toList()..sort();
        _logPlayerAction(
          player.name,
          'checking for runs with values',
          sortedValues.join(', '),
        );

        // try to find a run of 8 consecutive cards
        if (sortedValues.length + wildCards.length >= 9) {
          // find longest run
          int bestRunLength = 0;
          List<int> bestRunValues = [];
          int bestWildsNeeded =
              1000; // placeholder high number higher than the number of cards in the deck

          // try each value as a potential starting point
          for (int startValue in sortedValues) {
            List<int> currentRun = [];
            int wildsNeeded = 0;

            // check up to 10 consecutive values
            for (int i = 0; i < 10; i++) {
              int expectedValue = startValue + i;

              if (valueGroups.containsKey(expectedValue)) {
                // we have this value
                currentRun.add(expectedValue);
              } else if (wildsNeeded < wildCards.length) {
                // use a wild card
                currentRun.add(expectedValue);
                wildsNeeded++;
              } else {
                // cant continue the run
                break;
              }
            }

            // check if this is a valid run of 9 or more cards
            if (currentRun.length >= 9) {
              _logPlayerAction(
                player.name,
                'found potential run',
                'starting at $startValue with length ${currentRun.length}, needing $wildsNeeded wilds',
              );

              // check if this is a better run than the previously stored run
              if (wildsNeeded < bestWildsNeeded ||
                  (wildsNeeded == bestWildsNeeded &&
                      currentRun.length > bestRunLength)) {
                bestRunLength = currentRun.length;
                bestRunValues = List.from(currentRun);
                bestWildsNeeded = wildsNeeded;
              }
            }
          }

          // check if we found a valid run
          if (bestRunLength >= 9) {
            // take just 9 card values for the run
            List<int> runValues = bestRunValues.sublist(0, 9);
            _logPlayerAction(
              player.name,
              'using run values',
              runValues.join(', '),
            );

            // create the run with the real cards and wild cards if needed
            List<game_card.Card> remainingWilds = [...wildCards];

            for (int value in runValues) {
              if (valueGroups.containsKey(value) &&
                  valueGroups[value]!.isNotEmpty) {
                // add a value card
                runCards.add(valueGroups[value]!.removeAt(0));
              } else {
                // add a wild card
                runCards.add(remainingWilds.removeAt(0));
              }
            }

            foundValidRun = true;
            _logPlayerAction(
              player.name,
              'created valid run',
              'with ${runCards.length} cards',
            );
          }
        }

        if (foundValidRun) {
          // create card groups for the phase
          List<List<String>> cardGroups = [runCards.map((c) => c.id).toList()];

          // attempt to play the phase
          _logPlayerAction(
            player.name,
            'submitting phase',
            '${cardGroups.length} groups',
          );
          bool success = widget.engine.playPhase(cardGroups);

          if (success) {
            setState(() {
              _phaseAttemptedThisTurn = true;
              _selectedCards.clear();
            });

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Phase Completed!')));
            print(
              'About to play success sound...',
            ); //Can delete this before submission
            SoundPlayer.playPhaseCompleteSound();
            _logPlayerAction(player.name, 'phase attempt result', 'Success');
            _syncGameState();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Phase attempt failed, check requirements'),
              ),
            );
            _logPlayerAction(player.name, 'phase attempt result', 'Failed');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Need a run of 9 consecutive cards')),
          );
          _logPlayerAction(
            player.name,
            'phase attempt failed',
            'no valid run found',
          );
        }
        return;
      } else if (phaseNumber == 7) {
        _logPlayerAction(
          player.name,
          'phase 7 requirements',
          'two sets of four cards',
        );

        // group cards by their value
        Map<int, List<game_card.Card>> valueGroups = {};
        List<game_card.Card> wildCards = [];

        // separate wilds and group cards by value
        for (var card in _selectedCards) {
          if (card.type == game_card.CardType.wild) {
            wildCards.add(card);
            _logPlayerAction(
              player.name,
              'identified wild card',
              card.toString(),
            );
          } else {
            if (!valueGroups.containsKey(card.value)) {
              valueGroups[card.value] = [];
            }
            valueGroups[card.value]!.add(card);
          }
        }

        _logPlayerAction(
          player.name,
          'found unique values',
          valueGroups.keys.join(', '),
        );
        _logPlayerAction(
          player.name,
          'found wild cards',
          wildCards.length.toString(),
        );

        // identify values that could form sets
        List<int> validSetValues = [];
        Map<int, int> wildsNeededForSet = {};

        valueGroups.forEach((value, cards) {
          _logPlayerAction(
            player.name,
            'value $value has cards',
            cards.length.toString(),
          );

          if (cards.length >= 4) {
            // complete set without wilds
            validSetValues.add(value);
            wildsNeededForSet[value] = 0;
            _logPlayerAction(
              player.name,
              'value $value forms complete set',
              'no wilds needed',
            );
          } else if (cards.length + wildCards.length >= 4) {
            // could form a set with wilds
            int wildsNeeded = 4 - cards.length;
            validSetValues.add(value);
            wildsNeededForSet[value] = wildsNeeded;
            _logPlayerAction(
              player.name,
              'value $value could form set',
              'using $wildsNeeded wilds',
            );
          }
        });

        // sort values by fewest wilds needed
        validSetValues.sort(
          (a, b) => wildsNeededForSet[a]!.compareTo(wildsNeededForSet[b]!),
        );

        // check if we have at least two valid sets
        if (validSetValues.length >= 2) {
          _logPlayerAction(
            player.name,
            'identified valid sets',
            validSetValues.join(', '),
          );

          // create card groups for the phase
          List<List<String>> cardGroups = [];
          List<game_card.Card> remainingWilds = [...wildCards];

          // take the best two sets (needing fewest wilds)
          for (int i = 0; i < 2; i++) {
            int setValue = validSetValues[i];
            List<game_card.Card> setCards = [...valueGroups[setValue]!];

            // add wilds if needed
            int wildsNeeded = wildsNeededForSet[setValue]!;
            for (int w = 0; w < wildsNeeded && remainingWilds.isNotEmpty; w++) {
              setCards.add(remainingWilds.removeAt(0));
            }

            // convert to card IDs
            cardGroups.add(setCards.map((c) => c.id).toList());
            _logPlayerAction(
              player.name,
              'created set',
              'value $setValue with ${setCards.length} cards',
            );
          }

          // attempt to play the phase
          _logPlayerAction(
            player.name,
            'submitting phase',
            '${cardGroups.length} groups',
          );
          bool success = widget.engine.playPhase(cardGroups);

          if (success) {
            setState(() {
              _phaseAttemptedThisTurn = true;
              _selectedCards.clear();
            });

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Phase completed!')));
            print(
              'About to play success sound...',
            ); //Can delete this before submission
            SoundPlayer.playPhaseCompleteSound();
            _logPlayerAction(player.name, 'phase attempt result', 'Success');
            _syncGameState();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Phase attempt failed. Check requirements.'),
              ),
            );
            _logPlayerAction(player.name, 'phase attempt result', 'Failed');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Need 2 sets of 4 cards each with the same numbers.',
              ),
            ),
          );
          _logPlayerAction(
            player.name,
            'phase attempt failed',
            'not enough valid sets',
          );
        }
        return;
      } else if (phaseNumber == 8) {
        _logPlayerAction(
          player.name,
          'phase 8 requirements',
          '7 cards of one color',
        );

        // group cards by their value
        Map<game_card.CardColor, List<game_card.Card>> colorGroups = {};
        List<game_card.Card> wildCards = [];

        // separate wilds and group cards by value
        for (var card in _selectedCards) {
          if (card.type == game_card.CardType.wild) {
            wildCards.add(card);
            _logPlayerAction(
              player.name,
              'identified wild card',
              card.toString(),
            );
          } else {
            if (!colorGroups.containsKey(card.color)) {
              colorGroups[card.color] = [];
            }
            colorGroups[card.color]!.add(card);
          }
        }

        _logPlayerAction(
          player.name,
          'found unique colors',
          colorGroups.keys.join(', '),
        );
        _logPlayerAction(
          player.name,
          'found wild cards',
          wildCards.length.toString(),
        );

        // identify color groups that could form sets
        List<game_card.CardColor> potentialColors = [];
        Map<game_card.CardColor, int> wildsNeededForColorSet = {};

        colorGroups.forEach((color, cards) {
          _logPlayerAction(
            player.name,
            'color $color has cards',
            cards.length.toString(),
          );

          if (cards.length >= 7) {
            // complete set without wilds
            potentialColors.add(color);
            wildsNeededForColorSet[color] = 0;
            _logPlayerAction(
              player.name,
              'color $color forms complete set',
              'no wilds needed',
            );
          } else if (cards.length + wildCards.length >= 7) {
            // could form a set with wilds
            int wildsNeeded = 7 - cards.length;
            potentialColors.add(color);
            wildsNeededForColorSet[color] = wildsNeeded;
            _logPlayerAction(
              player.name,
              'color $color could form set',
              'using $wildsNeeded wilds',
            );
          }
        });

        // check if we have a valid color set
        if (potentialColors.isNotEmpty) {
          // sort color sets by fewest wilds needed
          potentialColors.sort(
            (a, b) => wildsNeededForColorSet[a]!.compareTo(
              wildsNeededForColorSet[b]!,
            ),
          );

          // use color that requires the fewest wild cards
          game_card.CardColor bestColor = potentialColors[0];
          int wildsNeeded = wildsNeededForColorSet[bestColor]!;

          // create the color group
          List<game_card.Card> colorCards = [];
          colorCards.addAll(colorGroups[bestColor]!);

          // add wild cards if needed
          for (int i = 0; i < wildsNeeded; i++) {
            colorCards.add(wildCards[i]);
          }

          // take just 7 cards
          if (colorCards.length > 7) {
            colorCards = colorCards.sublist(0, 7);
          }

          _logPlayerAction(
            player.name,
            'created color group',
            'color ${bestColor.name} with ${colorCards.length} cards',
          );

          // create card groups for the phase
          List<List<String>> cardGroups = [
            colorCards.map((c) => c.id).toList(),
          ];

          // attempt to play the phase
          _logPlayerAction(
            player.name,
            'submitting phase',
            '${cardGroups.length} groups',
          );
          bool success = widget.engine.playPhase(cardGroups);

          if (success) {
            setState(() {
              _phaseAttemptedThisTurn = true;
              _selectedCards.clear();
            });

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Phase completed!')));
            print(
              'About to play success sound...',
            ); //Can delete this before submission
            SoundPlayer.playPhaseCompleteSound();
            _logPlayerAction(player.name, 'phase attempt result', 'Success');
            _syncGameState();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Phase attempt failed. Check requirements.'),
              ),
            );
            _logPlayerAction(player.name, 'phase attempt result', 'Failed');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Need 1 set of 7 cards each with the same color.'),
            ),
          );
          _logPlayerAction(
            player.name,
            'phase attempt failed',
            'no valid color group found',
          );
        }
        return;
      }
      if (phaseNumber == 9) {
        _logPlayerAction(
          player.name,
          'phase 9 requirements',
          'a set of 5 and a set of 2 cards',
        );

        // group cards by their value
        Map<int, List<game_card.Card>> valueGroups = {};
        List<game_card.Card> wildCards = [];

        // separate wilds and group cards by value
        for (var card in _selectedCards) {
          if (card.type == game_card.CardType.wild) {
            wildCards.add(card);
            _logPlayerAction(
              player.name,
              'identified wild card',
              card.toString(),
            );
          } else {
            if (!valueGroups.containsKey(card.value)) {
              valueGroups[card.value] = [];
            }
            valueGroups[card.value]!.add(card);
          }
        }

        _logPlayerAction(
          player.name,
          'found unique values',
          valueGroups.keys.join(', '),
        );
        _logPlayerAction(
          player.name,
          'found wild cards',
          wildCards.length.toString(),
        );

        // identify values that could form sets
        List<int> validSetValues = [];
        Map<int, int> wildsNeededForSet = {};

        valueGroups.forEach((value, cards) {
          _logPlayerAction(
            player.name,
            'value $value has cards',
            cards.length.toString(),
          );

          // Check for set of 5
          if (cards.length >= 5) {
            // complete set without wilds
            validSetValues.add(value);
            wildsNeededForSet[value] = 0;
            _logPlayerAction(
              player.name,
              'value $value forms complete set of 5',
              'no wilds needed',
            );
          } else if (cards.length >= 2 &&
              cards.length + wildCards.length >= 5) {
            // could form a set of 5 with wilds (need at least 2 natural cards)
            int wildsNeeded = 5 - cards.length;
            validSetValues.add(value);
            wildsNeededForSet[value] = wildsNeeded;
            _logPlayerAction(
              player.name,
              'value $value could form set of 5',
              'using $wildsNeeded wilds',
            );
          }

          // Check for set of 2
          if (cards.length >= 2) {
            // complete set of 2 without wilds
            if (!validSetValues.contains(value)) {
              validSetValues.add(value);
              wildsNeededForSet[value] = 0;
              _logPlayerAction(
                player.name,
                'value $value forms complete set of 2',
                'no wilds needed',
              );
            }
          } else if (cards.length == 1 && wildCards.length >= 1) {
            // could form a set of 2 with 1 wild
            if (!validSetValues.contains(value)) {
              validSetValues.add(value);
              wildsNeededForSet[value] = 1;
              _logPlayerAction(
                player.name,
                'value $value could form set of 2',
                'using 1 wild',
              );
            }
          }
        });

        // sort values by fewest wilds needed
        validSetValues.sort(
          (a, b) => wildsNeededForSet[a]!.compareTo(wildsNeededForSet[b]!),
        );

        // check if we have at least two valid sets
        if (validSetValues.length >= 2) {
          _logPlayerAction(
            player.name,
            'identified valid sets',
            validSetValues.join(', '),
          );

          // create card groups for the phase
          List<List<String>> cardGroups = [];
          List<game_card.Card> remainingWilds = [...wildCards];

          // Find a value that can form a set of 5
          bool foundSetOf5 = false;
          bool foundSetOf2 = false;
          int? setOf5Value;
          int? setOf2Value;

          // First identify which values can form the set of 5 and which can form set of 2
          for (int setValue in validSetValues) {
            List<game_card.Card> setCards = [...valueGroups[setValue]!];
            int availableWilds = remainingWilds.length;

            if (setCards.length + availableWilds >= 5 && !foundSetOf5) {
              // This can be our set of 5
              setOf5Value = setValue;
              foundSetOf5 = true;
            } else if (setCards.length + availableWilds >= 2 &&
                !foundSetOf2 &&
                setValue != setOf5Value) {
              // This can be our set of 2
              setOf2Value = setValue;
              foundSetOf2 = true;
            }

            if (foundSetOf5 && foundSetOf2) break;
          }

          if (foundSetOf5 && foundSetOf2) {
            // Create set of 5
            List<game_card.Card> set5Cards = [...valueGroups[setOf5Value]!];
            int wildsNeeded5 = 5 - set5Cards.length;
            wildsNeeded5 = wildsNeeded5 < 0 ? 0 : wildsNeeded5;

            // Add wilds if needed for set of 5
            for (
              int w = 0;
              w < wildsNeeded5 && remainingWilds.isNotEmpty;
              w++
            ) {
              set5Cards.add(remainingWilds.removeAt(0));
            }

            // Convert to card IDs for set of 5
            cardGroups.add(set5Cards.map((c) => c.id).toList());
            _logPlayerAction(
              player.name,
              'created set of 5',
              'value $setOf5Value with ${set5Cards.length} cards',
            );

            // Create set of 2
            List<game_card.Card> set2Cards = [...valueGroups[setOf2Value]!];
            int wildsNeeded2 = 2 - set2Cards.length;
            wildsNeeded2 = wildsNeeded2 < 0 ? 0 : wildsNeeded2;

            // Add wilds if needed for set of 2
            for (
              int w = 0;
              w < wildsNeeded2 && remainingWilds.isNotEmpty;
              w++
            ) {
              set2Cards.add(remainingWilds.removeAt(0));
            }

            // Convert to card IDs for set of 2
            cardGroups.add(set2Cards.map((c) => c.id).toList());
            _logPlayerAction(
              player.name,
              'created set of 2',
              'value $setOf2Value with ${set2Cards.length} cards',
            );

            // attempt to play the phase
            _logPlayerAction(
              player.name,
              'submitting phase',
              '${cardGroups.length} groups',
            );
            bool success = widget.engine.playPhase(cardGroups);

            if (success) {
              setState(() {
                _phaseAttemptedThisTurn = true;
                _selectedCards.clear();
              });

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Phase completed!')));
              print(
                'About to play success sound...',
              ); //Can delete this before submission
              SoundPlayer.playPhaseCompleteSound();
              _logPlayerAction(player.name, 'phase attempt result', 'Success');
              _syncGameState();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Phase attempt failed. Check requirements.'),
                ),
              );
              _logPlayerAction(player.name, 'phase attempt result', 'Failed');
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Need 1 set of 5 cards and 1 set of 2 cards each with the same numbers.',
                ),
              ),
            );
            _logPlayerAction(
              player.name,
              'phase attempt failed',
              'could not form required sets',
            );
          }
        }
        return;
      }
      if (phaseNumber == 10) {
        _logPlayerAction(
          player.name,
          'phase 10 requirements',
          'a set of 5 and a set of 3 cards',
        );

        // group cards by their value
        Map<int, List<game_card.Card>> valueGroups = {};
        List<game_card.Card> wildCards = [];

        // separate wilds and group cards by value
        for (var card in _selectedCards) {
          if (card.type == game_card.CardType.wild) {
            wildCards.add(card);
            _logPlayerAction(
              player.name,
              'identified wild card',
              card.toString(),
            );
          } else {
            if (!valueGroups.containsKey(card.value)) {
              valueGroups[card.value] = [];
            }
            valueGroups[card.value]!.add(card);
          }
        }

        _logPlayerAction(
          player.name,
          'found unique values',
          valueGroups.keys.join(', '),
        );
        _logPlayerAction(
          player.name,
          'found wild cards',
          wildCards.length.toString(),
        );

        // identify values that could form sets
        List<int> validSetValues = [];
        Map<int, int> wildsNeededForSet = {};

        valueGroups.forEach((value, cards) {
          _logPlayerAction(
            player.name,
            'value $value has cards',
            cards.length.toString(),
          );

          // Check for set of 5
          if (cards.length >= 5) {
            // complete set without wilds
            validSetValues.add(value);
            wildsNeededForSet[value] = 0;
            _logPlayerAction(
              player.name,
              'value $value forms complete set of 5',
              'no wilds needed',
            );
          } else if (cards.length >= 3 &&
              cards.length + wildCards.length >= 5) {
            // could form a set of 5 with wilds (need at least 2 natural cards)
            int wildsNeeded = 5 - cards.length;
            validSetValues.add(value);
            wildsNeededForSet[value] = wildsNeeded;
            _logPlayerAction(
              player.name,
              'value $value could form set of 5',
              'using $wildsNeeded wilds',
            );
          }

          // Check for set of 3
          if (cards.length >= 3) {
            // complete set of 2 without wilds
            if (!validSetValues.contains(value)) {
              validSetValues.add(value);
              wildsNeededForSet[value] = 0;
              _logPlayerAction(
                player.name,
                'value $value forms complete set of 3',
                'no wilds needed',
              );
            }
          } else if (cards.length == 1 && wildCards.length >= 1) {
            // could form a set of 3 with 2 wild
            if (!validSetValues.contains(value)) {
              validSetValues.add(value);
              wildsNeededForSet[value] = 2;
              _logPlayerAction(
                player.name,
                'value $value could form set of 3',
                'using 2 wild',
              );
            }
          }
        });

        // sort values by fewest wilds needed
        validSetValues.sort(
          (a, b) => wildsNeededForSet[a]!.compareTo(wildsNeededForSet[b]!),
        );

        // check if we have at least two valid sets
        if (validSetValues.length >= 2) {
          _logPlayerAction(
            player.name,
            'identified valid sets',
            validSetValues.join(', '),
          );

          // create card groups for the phase
          List<List<String>> cardGroups = [];
          List<game_card.Card> remainingWilds = [...wildCards];

          // Find a value that can form a set of 5
          bool foundSetOf5 = false;
          bool foundSetOf3 = false;
          int? setOf5Value;
          int? setOf3Value;

          // First identify which values can form the set of 5 and which can form set of 2
          for (int setValue in validSetValues) {
            List<game_card.Card> setCards = [...valueGroups[setValue]!];
            int availableWilds = remainingWilds.length;

            if (setCards.length + availableWilds >= 5 && !foundSetOf5) {
              // This can be our set of 5
              setOf5Value = setValue;
              foundSetOf5 = true;
            } else if (setCards.length + availableWilds >= 2 &&
                !foundSetOf3 &&
                setValue != setOf5Value) {
              // This can be our set of 2
              setOf3Value = setValue;
              foundSetOf3 = true;
            }

            if (foundSetOf5 && foundSetOf3) break;
          }

          if (foundSetOf5 && foundSetOf3) {
            // Create set of 5
            List<game_card.Card> set5Cards = [...valueGroups[setOf5Value]!];
            int wildsNeeded5 = 5 - set5Cards.length;
            wildsNeeded5 = wildsNeeded5 < 0 ? 0 : wildsNeeded5;

            // Add wilds if needed for set of 5
            for (
              int w = 0;
              w < wildsNeeded5 && remainingWilds.isNotEmpty;
              w++
            ) {
              set5Cards.add(remainingWilds.removeAt(0));
            }

            // Convert to card IDs for set of 5
            cardGroups.add(set5Cards.map((c) => c.id).toList());
            _logPlayerAction(
              player.name,
              'created set of 5',
              'value $setOf5Value with ${set5Cards.length} cards',
            );

            // Create set of 3
            List<game_card.Card> set3Cards = [...valueGroups[setOf3Value]!];
            int wildsNeeded3 = 3 - set3Cards.length;
            wildsNeeded3 = wildsNeeded3 < 0 ? 0 : wildsNeeded3;

            // Add wilds if needed for set of 3
            for (
              int w = 0;
              w < wildsNeeded3 && remainingWilds.isNotEmpty;
              w++
            ) {
              set3Cards.add(remainingWilds.removeAt(0));
            }

            // Convert to card IDs for set of 2
            cardGroups.add(set3Cards.map((c) => c.id).toList());
            _logPlayerAction(
              player.name,
              'created set of 2',
              'value $setOf3Value with ${set3Cards.length} cards',
            );

            // attempt to play the phase
            _logPlayerAction(
              player.name,
              'submitting phase',
              '${cardGroups.length} groups',
            );
            bool success = widget.engine.playPhase(cardGroups);

            if (success) {
              setState(() {
                _phaseAttemptedThisTurn = true;
                _selectedCards.clear();
              });

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Phase completed!')));
              print(
                'About to play success sound...',
              ); //Can delete this before submission
              SoundPlayer.playPhaseCompleteSound();
              _logPlayerAction(player.name, 'phase attempt result', 'Success');
              _syncGameState();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Phase attempt failed. Check requirements.'),
                ),
              );
              _logPlayerAction(player.name, 'phase attempt result', 'Failed');
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Need 1 set of 5 cards and 1 set of 3 cards each with the same numbers.',
                ),
              ),
            );
            _logPlayerAction(
              player.name,
              'phase attempt failed',
              'could not form required sets',
            );
          }
        }
        return;
      } else {
        if (phaseNumber > 10) {
          // the player has completed all phases
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Congratulations! You have completed all phases!'),
              backgroundColor: Colors.green,
            ),
          );
          print(
            'About to play success sound...',
          ); //Can delete this before submission
          SoundPlayer.playGameCompleteSound();
          _logPlayerAction(
            player.name,
            'attempted phase',
            'all phases completed',
          );
        } else {
          // shouldn't reach this
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid phase number: $phaseNumber'),
              backgroundColor: Colors.red,
            ),
          );
          _logPlayerAction(
            player.name,
            'attempted invalid phase',
            phaseNumber.toString(),
          );
        }
        return;
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
        SnackBar(content: Text('You must draw a card before ending your turn')),
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
      _logPlayerAction(
        player.name,
        'discarding card',
        cardToDiscard.toString(),
      );
      _logPlayerHand(player.name, player.hand);

      setState(() {
        // discard the selected card
        player.discard(cardToDiscard, widget.engine.discardPile);

        // log after discard
        _logPlayerAction(
          player.name,
          'discarded card, hand size now',
          '${player.hand.length}',
        );
        _logPlayerHand(player.name, player.hand);
        _logPlayerAction(
          player.name,
          'top card on discard pile',
          '${widget.engine.discardPile.last}',
        );

        // check if player won the round
        if (player.hasEmptyHand) {
          _logPlayerAction(player.name, 'has empty hand', 'won the round!');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${player.name} wins the round!')),
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

      // cync before processing the next turn
      _syncGameState().then((_) {
        // allow some time for the UI to update
        Future.delayed(const Duration(milliseconds: 300), () {
          _isProcessingTurn = false;

          // check if AI's turn after user plays
          if (widget.engine.currentPlayer.name != userName) {
            _handleAiTurn();
          }
        });
      });
    } catch (e) {
      _handleError('Error ending turn', e);
      _isProcessingTurn = false;
    }
  }

  // handle ending the round when button is clicked
  void _endRound(Player player) {
    if (!player.hasLaidDown) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must complete your phase first!')),
      );
      return;
    }

    if (player.currentPhase >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You\'ve already completed all phases!')),
      );
      return;
    }

    if (_isProcessingTurn) {
      _log('Turn already processing, ignoring end round');
      return;
    }

    _isProcessingTurn = true;

    try {
      _logPlayerAction(player.name, 'ending round', 'discarding all cards');

      setState(() {
        // add all remaining cards to discard pile
        List<game_card.Card> cardsToDiscard = List.from(player.hand);
        for (var card in cardsToDiscard) {
          // log each card being discarded
          _logPlayerAction(player.name, 'discarding card', card.toString());
          player.discard(card, widget.engine.discardPile);
        }

        _logPlayerAction(player.name, 'hand is now empty', 'round will end');

        // show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Round complete! You advance to phase ${player.currentPhase + 1}',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // end round will automatically advance phase for the player who emptied their hand
        widget.engine.endRound();

        // reset turn state
        _hasDrawnThisTurn = false;
        _phaseAttemptedThisTurn = false;
        _drawnCard = null;
        _selectedCards.clear();
      });

      // sync before processing the next turn
      _syncGameState().then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _isProcessingTurn = false;

          // check whose turn it is after the round ends
          if (widget.engine.currentPlayer.name != userName) {
            _handleAiTurn();
          }
        });
      });
    } catch (e) {
      _handleError('Error ending round', e);
      _isProcessingTurn = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.engine.currentPlayer;
    final isUserTurn = player.name == userName;

    // sort the player's hand for better display/easier user intepretation
    List<game_card.Card> sortedHand = List.from(player.hand);
    sortedHand.sort((a, b) {
      if (a.type != b.type) {
        return a.type.index.compareTo(b.type.index);
      }
      if (a.value != b.value) {
        return a.value.compareTo(b.value);
      }
      return a.color.index.compareTo(b.color.index);
    });

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
            // New row with your turn on left and phase info on right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Current Phase: ${player.currentPhase}${player.hasLaidDown ? ' ✓' : ''}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: player.hasLaidDown ? Colors.green : null,
                      ),
                    ),
                    Text(
                      "Phase Completed: ${player.hasLaidDown ? 'Yes' : 'No'}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      "Cards Drawn This Turn: ${_hasDrawnThisTurn ? 'Yes' : 'No'}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            if (_selectedCards.isNotEmpty)
              Text(
                "Selected Cards: ${_selectedCards.length}",
                style: const TextStyle(fontSize: 16, color: Colors.blue),
              ),
            const SizedBox(height: 20),
            Text(
              "Phase ${player.currentPhase} Requirements:",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              getPhaseDescription(player.currentPhase),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Image.asset(
              'assets/phase_${player.currentPhase}.png',
              height: 80,
              fit: BoxFit.contain,
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
                        const Text(
                          "Draw Deck",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text("Cards: ${widget.engine.deck.length}"),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed:
                              isUserTurn && !_hasDrawnThisTurn
                                  ? () => _drawFromDeck(player)
                                  : null,
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
                        const Text(
                          "Discard Pile",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.engine.discardPile.isNotEmpty
                              ? widget.engine.discardPile.last.toString()
                              : "Empty",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed:
                              isUserTurn && _canTakeFromDiscard()
                                  ? () => _drawFromDiscard(player)
                                  : null,
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
              Wrap(
                spacing: 8.0, // horizontal space between buttons
                runSpacing: 8.0, // vertical space between lines
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed:
                        _canAttemptPhase(player)
                            ? () => _attemptPhase(player)
                            : null,
                    child: const Text("Attempt Phase"),
                  ),
                  ElevatedButton(
                    onPressed:
                        _selectedCards.isNotEmpty
                            ? () => setState(() => _selectedCards.clear())
                            : null,
                    child: const Text("Clear Selection"),
                  ),
                  // End Round button - only visible when player has completed their phase
                  if (player.hasLaidDown)
                    ElevatedButton(
                      onPressed: () => _endRound(player),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("End Round"),
                    ),
                ],
              ),

            const SizedBox(height: 20),

            // player Hand
            const Text(
              "Your Hand:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            ElevatedButton(
              onPressed: _pickCardImage,
              child: const Text("Upload Image of Real Cards"),
            ),

            if (_uploadedImage != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: Image.file(_uploadedImage!, fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Enter the cards shown in the image:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _manualCardEntries.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _manualCardEntries.length) {
                            int selectedValue = 1;
                            game_card.CardColor selectedColor =
                                game_card.CardColor.red;

                            return Row(
                              children: [
                                DropdownButton<game_card.CardColor>(
                                  value: selectedColor,
                                  onChanged:
                                      (value) => setState(
                                        () => selectedColor = value!,
                                      ),
                                  items:
                                      game_card.CardColor.values.map((color) {
                                        return DropdownMenuItem(
                                          value: color,
                                          child: Text(color.name),
                                        );
                                      }).toList(),
                                ),
                                const SizedBox(width: 10),
                                DropdownButton<int>(
                                  value: selectedValue,
                                  onChanged:
                                      (value) => setState(
                                        () => selectedValue = value!,
                                      ),
                                  items:
                                      List.generate(12, (i) => i + 1).map((
                                        num,
                                      ) {
                                        return DropdownMenuItem(
                                          value: num,
                                          child: Text(num.toString()),
                                        );
                                      }).toList(),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _manualCardEntries.add(
                                        game_card.Card(
                                          id: DateTime.now().toIso8601String(),
                                          color: selectedColor,
                                          value: selectedValue,
                                          type: game_card.CardType.number,
                                        ),
                                      );
                                    });
                                  },
                                  child: const Text("Add Card"),
                                ),
                              ],
                            );
                          } else {
                            final card = _manualCardEntries[index];
                            return ListTile(
                              title: Text(
                                '${card.color.name.toUpperCase()} ${card.value}',
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed:
                                    () => setState(
                                      () => _manualCardEntries.removeAt(index),
                                    ),
                              ),
                            );
                          }
                        },
                      ),
                      ElevatedButton(
                        onPressed: () => _replaceHandWithManualEntries(player),
                        child: const Text("Replace Hand with These Cards"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        sortedHand.map((card) {
                          final isSelected = _selectedCards.any(
                            (c) => c.id == card.id,
                          );
                          final isNewCard = _drawnCard?.id == card.id;

                          return GestureDetector(
                            onTap:
                                isUserTurn
                                    ? () {
                                      if (_hasDrawnThisTurn) {
                                        if (isSelected) {
                                          _toggleCardSelection(card);
                                        } else if (_selectedCards.isEmpty) {
                                          showDialog(
                                            context: context,
                                            builder:
                                                (context) => AlertDialog(
                                                  title: const Text(
                                                    'Card Action',
                                                  ),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'What do you want to do with ${card.toString()}?',
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                          _toggleCardSelection(
                                                            card,
                                                          );
                                                        },
                                                        child: const Text(
                                                          'Select for Phase',
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                          _endTurn(
                                                            player,
                                                            card,
                                                          );
                                                        },
                                                        child: const Text(
                                                          'Discard & End Turn',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed:
                                                          () =>
                                                              Navigator.of(
                                                                context,
                                                              ).pop(),
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                          );
                                        } else {
                                          _toggleCardSelection(card);
                                        }
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Draw a card first'),
                                          ),
                                        );
                                      }
                                    }
                                    : null,
                            child: Container(
                              width: 60,
                              height: 90,
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Colors.blue.shade200
                                        : isNewCard
                                        ? Colors.green.shade100
                                        : Colors.white,
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? Colors.blue
                                          : isNewCard
                                          ? Colors.green
                                          : Colors.grey,
                                  width: isSelected || isNewCard ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Image.asset(
                                  _getCardImagePath(card),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    // fallback to text if image not found
                                    return Center(
                                      child: Text(
                                        card.toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight:
                                              isSelected || isNewCard
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                        ),
                                      ),
                                    );
                                  },
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
