import 'package:flutter/material.dart';
import 'play_screen.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final PageController _controller = PageController();

  final List<Map<String, String>> helpContent = [
    {
      'title': 'Objective',
      'text': 'Be the first player to complete all ten phases by discarding your entire hand according to the requirements of the current phase.',
    },
    {
      'title': 'Setup',
      'text': 'Shuffle the deck and deal 10 cards to each player. Place the rest as a draw pile. Flip one card over to start the discard pile.',
    },
    {
      'title': 'Rules',
      'text': 'On your turn, draw a card and try to complete the current phase. Then discard a card. Complete all 10 phases to win!',
    },
    {
      'title': 'Special Cards',
      'text': 'Wild: Acts as any number or color.\nSkip: Skips the next player’s turn. They draw 2 cards and continue.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Play'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.red,
        elevation: 0,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: helpContent.length,
        itemBuilder: (context, index) {
          final item = helpContent[index];
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item['title']!,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Text(
                  item['text']!,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.left,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (index > 0)
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.red),
                        onPressed: () => _controller.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                      ),
                    if (index < helpContent.length - 1)
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, color: Colors.red),
                        onPressed: () => _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                      ),
                    if (index == helpContent.length - 1)
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context, 
                            MaterialPageRoute(builder: (context) => PlayPage()),
                          );
                        },
                        child: const Text('Done', style: TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

