import 'package:flutter/material.dart';


class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  void _showHelpDialog(BuildContext context, String title, String content) {
    showDialog<String>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: double.infinity, 
                  height: 60,             
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),  
                   onPressed: () => _showHelpDialog(
                    context,
                    'Objective',
                    'Be the first player to complete all ten phases by discarding your entire hand...',
                  ),
                    child: const Text('Objective'),
                  ),
                ),

                SizedBox(
                  width: double.infinity, 
                  height: 60,             
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),  
                   onPressed: () => _showHelpDialog(
                    context,
                    'Setup',
                    'Shuffle the deck and deal 10 cards face down to each player. The remaining deck is placed face down in the center, forming the draw pile. Flip the top card of the draw pile over to reveal the discard pile.',
                  ),
                    child: const Text('Setup'),
                  ),
                ),

                SizedBox(
                  width: double.infinity, 
                  height: 60,             
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),  
                   onPressed: () => _showHelpDialog(
                    context,
                    'Rules',
                    'At the beginning of your turn you will draw a card from the draw pile. At the end of your turn you will discard a card into the discard pile. During your turn you will attempt to discard as many cards as you can while meeting the requirements of the current phase. Requirements can include a run (a sequence of cards of the same suit ascending or descending), or a set (3 or 4 of the same number). Once you discard all your cards for the current phase, you will move onto the next phase. The player to complete all 10 phases first wins!',
                  ),
                    child: const Text('Rules'),
                  ),
                ),

                SizedBox(
                  width: double.infinity, 
                  height: 60,             
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),  
                   onPressed: () => _showHelpDialog(
                    context,
                    'Special Cards',
                    'Wild Card: Can be played as any number or color to complete a run or set.\n\nSkip Card: Place this card on top of the discard pile to skip the next player\'s turn. The next player draws 2 cards and completes their turn.',
                  ),
                    child: const Text('Special Cards'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}