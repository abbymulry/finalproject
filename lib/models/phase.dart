// phase 10 phase model
// ==============================================================
//
// this file defines the phase requirements for the phase 10 game
//
// in phase 10, players must complete the 10 different phases listed below, in order:
// phase 1: 2 sets of 3 cards (a set is cards of the same number)
// phase 2: 1 set of 3 + 1 run of 4 (a run is consecutive numbers)
// phase 3: 1 set of 4 + 1 run of 4
// phase 4: 1 run of 7
// phase 5: 1 run of 8
// phase 6: 1 run of 9
// phase 7: 2 sets of 4
// phase 8: 7 cards of one color
// phase 9: 1 set of 5 + 1 set of 2
// phase 10: 1 set of 5 + 1 set of 3
//
// this model provides:
// - definitions for each phase requirement
// - validation logic to check if a collection of cards satisfies a phase
// - method to create all 10 phases with their requirements
// ==============================================================

import 'card.dart';

// phase class defines the requirements for each phase in the game
class Phase {
  final int phaseNumber; // which phase (1-10)
  final List<PhaseRequirement> requirements;  // what's needed to complete it
  
  Phase({
    required this.phaseNumber,
    required this.requirements,
  });
  
  // check to see if a set of cards meets this phase's requirements
  // takes a list of card groups and validates against requirements
  bool isValidPhase(List<List<Card>> cardGroups) {
    // must have same number of groups as requirements
    if (cardGroups.length != requirements.length) return false;
    
    // check each group against its corresponding requirement
    for (int i = 0; i < requirements.length; i++) {
      if (!requirements[i].meetsRequirements(cardGroups[i])) {
        return false;
      }
    }
    
    return true;
  }
  
  // method to create all 10 phases with their specific requirements
  static List<Phase> createAllPhases() {
    return [
      // phase 1: two sets of 3
      Phase(phaseNumber: 1, requirements: [
        PhaseRequirement(type: PhaseRequirementType.set, count: 3),
        PhaseRequirement(type: PhaseRequirementType.set, count: 3),
      ]),
      
      // phase 2: one set of 3, one run of 4
      Phase(phaseNumber: 2, requirements: [
        PhaseRequirement(type: PhaseRequirementType.set, count: 3),
        PhaseRequirement(type: PhaseRequirementType.run, count: 4),
      ]),
      
      // phase 3: one set of 4, one run of 4
      Phase(phaseNumber: 3, requirements: [
        PhaseRequirement(type: PhaseRequirementType.set, count: 4),
        PhaseRequirement(type: PhaseRequirementType.run, count: 4),
      ]),
      
      // phase 4: one run of 7
      Phase(phaseNumber: 4, requirements: [
        PhaseRequirement(type: PhaseRequirementType.run, count: 7),
      ]),
      
      // phase 5: one run of 8
      Phase(phaseNumber: 5, requirements: [
        PhaseRequirement(type: PhaseRequirementType.run, count: 8),
      ]),
      
      // phase 6: one run of 9
      Phase(phaseNumber: 6, requirements: [
        PhaseRequirement(type: PhaseRequirementType.run, count: 9),
      ]),
      
      // phase 7: two sets of 4
      Phase(phaseNumber: 7, requirements: [
        PhaseRequirement(type: PhaseRequirementType.set, count: 4),
        PhaseRequirement(type: PhaseRequirementType.set, count: 4),
      ]),
      
      // phase 8: seven cards of one color
      Phase(phaseNumber: 8, requirements: [
        PhaseRequirement(type: PhaseRequirementType.color, count: 7),
      ]),
      
      // phase 9: one set of 5, one set of 2
      Phase(phaseNumber: 9, requirements: [
        PhaseRequirement(type: PhaseRequirementType.set, count: 5),
        PhaseRequirement(type: PhaseRequirementType.set, count: 2),
      ]),
      
      // phase 10: one set of 5, one set of 3
      Phase(phaseNumber: 10, requirements: [
        PhaseRequirement(type: PhaseRequirementType.set, count: 5),
        PhaseRequirement(type: PhaseRequirementType.set, count: 3),
      ]),
    ];
  }
}

// types of requirements for phases
enum PhaseRequirementType { 
  set, // cards of the same number
  run, // consecutive numbers
  color // cards of the same color
}

// defines a single requirement within a phase
class PhaseRequirement {
  final PhaseRequirementType type;  // what kind of requirement
  final int count; // how many cards needed
  
  PhaseRequirement({
    required this.type,
    required this.count,
  });
  
  // check if a group of cards meets their requirement
  bool meetsRequirements(List<Card> cards) {
    // must have at least the required number of cards
    if (cards.length < count) return false;
    
    if (type == PhaseRequirementType.set) {
      // for a set, all cards must be the same value or wild
      final nonWildCards = cards.where((card) => card.type != CardType.wild).toList();
      
      // if all cards are wild, it's a valid set
      if (nonWildCards.isEmpty) return true;
      
      // get the value of the first non-wild card to serve as point of comparison for all the other cards
      final targetValue = nonWildCards[0].value;
      
      // check that all non-wild cards have the same value as target card
      return nonWildCards.every((card) => card.value == targetValue);
      
    } else if (type == PhaseRequirementType.run) {
        // count wild cards which can be used to fill gaps
        int wildCount = cards.where((c) => c.type == CardType.wild).length;
        
        // get the non-wild cards
        List<Card> numberCards = cards.where((c) => c.type != CardType.wild).toList();
        
        // if all cards are wild, it's a valid run
        if (numberCards.isEmpty) return true;
        
        // sort the number cards by value
        numberCards.sort((a, b) => a.value.compareTo(b.value));
        
        // track how many wild cards are used for gaps
        int usedWildCards = 0;
        
        // check if we can form a valid run with the available cards and wilds
        for (int i = 1; i < numberCards.length; i++) {
            // calculate the gap between consecutive cards
            int gap = numberCards[i].value - numberCards[i-1].value - 1;
            
            // gaps can't be negative since duplicate values aren't allowed/valid
            if (gap < 0) return false;
            
            // count wild cards used to fill this gap
            usedWildCards += gap;
            
            // if we need more wild cards than we have, the run is invalid
            if (usedWildCards > wildCount) return false;
        }
        
        // the total run length is non-wild cards + wild cards
        int totalRunLength = numberCards.length + wildCount;
        
        // make sure we have enough cards to form the required run
        return totalRunLength >= count;

    } else if (type == PhaseRequirementType.color) {
      // for a color requirement, all cards must be the same color or wild
      final nonWildCards = cards.where((card) => card.color != CardColor.wild).toList();
      
      // if all cards are wild, it's valid
      if (nonWildCards.isEmpty) return true;
      
      // get the color of the first non-wild card
      final targetColor = nonWildCards[0].color;
      
      // check that all non-wild cards have the same color
      return nonWildCards.every((card) => card.color == targetColor);
    }
    
    return false;
  }
}