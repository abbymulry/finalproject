import 'package:flutter_test/flutter_test.dart';
import 'package:finalproject/models/card.dart';
import 'package:finalproject/models/phase.dart';

void main() {
  // tests for the phase model and phase requirements
  
  group('PhaseRequirement Tests', () {
    // test set requirement
    test('Set requirement should accept same-value cards', () {
      final requirement = PhaseRequirement(
        type: PhaseRequirementType.set, 
        count: 3
      );
      
      final cards = [
        Card(id: '1', type: CardType.number, value: 7, color: CardColor.red),
        Card(id: '2', type: CardType.number, value: 7, color: CardColor.blue),
        Card(id: '3', type: CardType.number, value: 7, color: CardColor.green),
      ];
      
      expect(requirement.meetsRequirements(cards), true);
    });
    
    test('Set requirement should reject different-value cards', () {
      final requirement = PhaseRequirement(
        type: PhaseRequirementType.set, 
        count: 3
      );
      
      final cards = [
        Card(id: '1', type: CardType.number, value: 7, color: CardColor.red),
        Card(id: '2', type: CardType.number, value: 7, color: CardColor.blue),
        Card(id: '3', type: CardType.number, value: 8, color: CardColor.green),
      ];
      
      expect(requirement.meetsRequirements(cards), false);
    });
    
    test('Set requirement should accept wild cards as substitutes', () {
      final requirement = PhaseRequirement(
        type: PhaseRequirementType.set, 
        count: 3
      );
      
      final cards = [
        Card(id: '1', type: CardType.number, value: 7, color: CardColor.red),
        Card(id: '2', type: CardType.wild, value: 0, color: CardColor.wild),
        Card(id: '3', type: CardType.number, value: 7, color: CardColor.green),
      ];
      
      expect(requirement.meetsRequirements(cards), true);
    });
    
    test('Set requirement should accept all wild cards', () {
      final requirement = PhaseRequirement(
        type: PhaseRequirementType.set, 
        count: 3
      );
      
      final cards = [
        Card(id: '1', type: CardType.wild, value: 0, color: CardColor.wild),
        Card(id: '2', type: CardType.wild, value: 0, color: CardColor.wild),
        Card(id: '3', type: CardType.wild, value: 0, color: CardColor.wild),
      ];
      
      expect(requirement.meetsRequirements(cards), true);
    });
    
    // test run requirement
    test('Run requirement should accept consecutive cards', () {
      final requirement = PhaseRequirement(
        type: PhaseRequirementType.run, 
        count: 4
      );
      
      final cards = [
        Card(id: '1', type: CardType.number, value: 3, color: CardColor.red),
        Card(id: '2', type: CardType.number, value: 4, color: CardColor.blue),
        Card(id: '3', type: CardType.number, value: 5, color: CardColor.green),
        Card(id: '4', type: CardType.number, value: 6, color: CardColor.yellow),
      ];
      
      expect(requirement.meetsRequirements(cards), true);
    });
    
    test('Run requirement should accept wild cards as gap fillers', () {
      final requirement = PhaseRequirement(
        type: PhaseRequirementType.run, 
        count: 4
      );
      
      final cards = [
        Card(id: '1', type: CardType.number, value: 3, color: CardColor.red),
        Card(id: '2', type: CardType.wild, value: 0, color: CardColor.wild), // represents 4
        Card(id: '3', type: CardType.number, value: 5, color: CardColor.green),
        Card(id: '4', type: CardType.number, value: 6, color: CardColor.yellow),
      ];
      
      expect(requirement.meetsRequirements(cards), true);
    });
    
    test('Run requirement should reject non-consecutive cards even with wilds if not enough', () {
      final requirement = PhaseRequirement(
        type: PhaseRequirementType.run, 
        count: 4
      );
      
      final cards = [
        Card(id: '1', type: CardType.number, value: 3, color: CardColor.red),
        Card(id: '2', type: CardType.wild, value: 0, color: CardColor.wild), // represents 4
        Card(id: '3', type: CardType.number, value: 7, color: CardColor.green), // gap of 2 but only 1 wild
        Card(id: '4', type: CardType.number, value: 8, color: CardColor.yellow),
      ];
      
      expect(requirement.meetsRequirements(cards), false);
    });
    
    test('Run requirement should reject duplicate values', () {
      final requirement = PhaseRequirement(
        type: PhaseRequirementType.run, 
        count: 4
      );
      
      final cards = [
        Card(id: '1', type: CardType.number, value: 3, color: CardColor.red),
        Card(id: '2', type: CardType.number, value: 4, color: CardColor.blue),
        Card(id: '3', type: CardType.number, value: 4, color: CardColor.green), // duplicate
        Card(id: '4', type: CardType.number, value: 5, color: CardColor.yellow),
      ];
      
      expect(requirement.meetsRequirements(cards), false);
    });
    
    // test color requirement
    test('Color requirement should accept same-color cards', () {
      final requirement = PhaseRequirement(
        type: PhaseRequirementType.color, 
        count: 4
      );
      
      final cards = [
        Card(id: '1', type: CardType.number, value: 3, color: CardColor.red),
        Card(id: '2', type: CardType.number, value: 5, color: CardColor.red),
        Card(id: '3', type: CardType.number, value: 7, color: CardColor.red),
        Card(id: '4', type: CardType.number, value: 9, color: CardColor.red),
      ];
      
      expect(requirement.meetsRequirements(cards), true);
    });
    
    test('Color requirement should accept wild cards as substitutes', () {
      final requirement = PhaseRequirement(
        type: PhaseRequirementType.color, 
        count: 4
      );
      
      final cards = [
        Card(id: '1', type: CardType.number, value: 3, color: CardColor.blue),
        Card(id: '2', type: CardType.number, value: 5, color: CardColor.blue),
        Card(id: '3', type: CardType.wild, value: 0, color: CardColor.wild),
        Card(id: '4', type: CardType.number, value: 9, color: CardColor.blue),
      ];
      
      expect(requirement.meetsRequirements(cards), true);
    });
    
    test('Color requirement should reject mixed-color cards', () {
      final requirement = PhaseRequirement(
        type: PhaseRequirementType.color, 
        count: 4
      );
      
      final cards = [
        Card(id: '1', type: CardType.number, value: 3, color: CardColor.blue),
        Card(id: '2', type: CardType.number, value: 5, color: CardColor.red), // different color
        Card(id: '3', type: CardType.number, value: 7, color: CardColor.blue),
        Card(id: '4', type: CardType.number, value: 9, color: CardColor.blue),
      ];
      
      expect(requirement.meetsRequirements(cards), false);
    });
  });
  
  group('Phase Tests', () {
    test('Phase 1 should accept two sets of 3', () {
      final phase = Phase.createAllPhases()[0]; // phase 1
      
      final cardGroups = [
        // first set of 3
        [
          Card(id: '1', type: CardType.number, value: 5, color: CardColor.red),
          Card(id: '2', type: CardType.number, value: 5, color: CardColor.blue),
          Card(id: '3', type: CardType.number, value: 5, color: CardColor.green),
        ],
        // second set of 3
        [
          Card(id: '4', type: CardType.number, value: 8, color: CardColor.red),
          Card(id: '5', type: CardType.number, value: 8, color: CardColor.blue),
          Card(id: '6', type: CardType.number, value: 8, color: CardColor.green),
        ],
      ];
      
      expect(phase.isValidPhase(cardGroups), true);
    });
    
    test('Phase 2 should accept one set of 3 and one run of 4', () {
      final phase = Phase.createAllPhases()[1]; // phase 2
      
      final cardGroups = [
        // set of 3
        [
          Card(id: '1', type: CardType.number, value: 5, color: CardColor.red),
          Card(id: '2', type: CardType.number, value: 5, color: CardColor.blue),
          Card(id: '3', type: CardType.number, value: 5, color: CardColor.green),
        ],
        // run of 4
        [
          Card(id: '4', type: CardType.number, value: 7, color: CardColor.red),
          Card(id: '5', type: CardType.number, value: 8, color: CardColor.blue),
          Card(id: '6', type: CardType.number, value: 9, color: CardColor.green),
          Card(id: '7', type: CardType.number, value: 10, color: CardColor.yellow),
        ],
      ];
      
      expect(phase.isValidPhase(cardGroups), true);
    });
    
    test('Phase 8 should accept seven cards of the same color', () {
      final phase = Phase.createAllPhases()[7]; // Phase 8
      
      final cardGroups = [
        // 7 cards of one color
        [
          Card(id: '1', type: CardType.number, value: 2, color: CardColor.green),
          Card(id: '2', type: CardType.number, value: 4, color: CardColor.green),
          Card(id: '3', type: CardType.number, value: 5, color: CardColor.green),
          Card(id: '4', type: CardType.number, value: 7, color: CardColor.green),
          Card(id: '5', type: CardType.number, value: 8, color: CardColor.green),
          Card(id: '6', type: CardType.number, value: 10, color: CardColor.green),
          Card(id: '7', type: CardType.number, value: 12, color: CardColor.green),
        ],
      ];
      
      expect(phase.isValidPhase(cardGroups), true);
    });
    
    test('Phase 1 should reject wrong number of groups', () {
      final phase = Phase.createAllPhases()[0]; // Phase 1
      
      final cardGroups = [
        // only one set of 3 instead of two
        [
          Card(id: '1', type: CardType.number, value: 5, color: CardColor.red),
          Card(id: '2', type: CardType.number, value: 5, color: CardColor.blue),
          Card(id: '3', type: CardType.number, value: 5, color: CardColor.green),
        ],
      ];
      
      expect(phase.isValidPhase(cardGroups), false);
    });
    
    test('Phase 2 should reject wrong order of groups', () {
      final phase = Phase.createAllPhases()[1]; // phase 2 (set of 3, run of 4)
      
      final cardGroups = [
        // run of 4 (should be set of 3 first)
        [
          Card(id: '4', type: CardType.number, value: 7, color: CardColor.red),
          Card(id: '5', type: CardType.number, value: 8, color: CardColor.blue),
          Card(id: '6', type: CardType.number, value: 9, color: CardColor.green),
          Card(id: '7', type: CardType.number, value: 10, color: CardColor.yellow),
        ],
        // set of 3 (should be first)
        [
          Card(id: '1', type: CardType.number, value: 5, color: CardColor.red),
          Card(id: '2', type: CardType.number, value: 5, color: CardColor.blue),
          Card(id: '3', type: CardType.number, value: 5, color: CardColor.green),
        ],
      ];
      
      expect(phase.isValidPhase(cardGroups), false);
    });
  });
}