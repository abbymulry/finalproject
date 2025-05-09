// Smart AI helper class for Phase 10

import '../models/player.dart';
import '../models/card.dart' as game_card;
import '../models/game.dart';

class AIBrain {
  static bool attemptPhase(Game game, Player ai) {
    final phase = ai.currentPhase;
    final hand = List<game_card.Card>.from(ai.hand);
    List<List<game_card.Card>>? groups;

    switch (phase) {
      case 1:
        groups = _findSets(hand, [3, 3]);
        break;
      case 2:
        final sets = _findSets(hand, [3]);
        if (sets.isNotEmpty) {
          final run = _findRun(
            _removeUsed(hand, sets.expand((e) => e).toList()),
            4,
          );
          if (run != null) groups = [sets.first, run];
        }
        break;
      case 3:
        final sets = _findSets(hand, [4]);
        if (sets.isNotEmpty) {
          final run = _findRun(
            _removeUsed(hand, sets.expand((e) => e).toList()),
            4,
          );
          if (run != null) groups = [sets.first, run];
        }
        break;
      case 4:
        final run = _findRun(hand, 7);
        if (run != null) groups = [run];
        break;
      case 5:
        final run = _findRun(hand, 8);
        if (run != null) groups = [run];
        break;
      case 6:
        final run = _findRun(hand, 9);
        if (run != null) groups = [run];
        break;
      case 7:
        groups = _findSets(hand, [4, 4]);
        break;
      case 8:
        groups = _findColorGroup(hand, 7);
        break;
      case 9:
        groups = _findSets(hand, [5, 2]);
        break;
      case 10:
        groups = _findSets(hand, [5, 3]);
        break;
      default:
        return false;
    }

    if (groups == null) return false;
    final ids = groups.map((g) => g.map((c) => c.id).toList()).toList();
    return game.playPhase(ids);
  }

  static List<List<game_card.Card>> _findSets(
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

  static List<game_card.Card> _removeUsed(
    List<game_card.Card> hand,
    List<game_card.Card> used,
  ) {
    final result = List<game_card.Card>.from(hand);
    for (var c in used) {
      result.remove(c);
    }
    return result;
  }

  static List<game_card.Card>? _findRun(
    List<game_card.Card> hand,
    int runLength,
  ) {
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
          orElse: () => null as game_card.Card,
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

      if (run.length == runLength) return run;
    }

    return null;
  }

  static List<List<game_card.Card>>? _findColorGroup(
    List<game_card.Card> hand,
    int size,
  ) {
    final wilds = hand.where((c) => c.type == game_card.CardType.wild).toList();
    final colors = <game_card.CardColor, List<game_card.Card>>{};
    for (final c in hand.where((c) => c.type == game_card.CardType.number)) {
      colors.putIfAbsent(c.color, () => []).add(c);
    }

    for (final group in colors.values) {
      if (group.length + wilds.length >= size) {
        final result = List<game_card.Card>.from(group);
        while (result.length < size && wilds.isNotEmpty) {
          result.add(wilds.removeLast());
        }
        return [result];
      }
    }

    return null;
  }
}
