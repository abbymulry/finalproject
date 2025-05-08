import 'package:flutter/material.dart';
import 'dart:math';

enum CardType { normal, wild, skip }

class ProjectPalette {
  Color darkGray = const Color.fromARGB(255, 47, 47, 60);
  Color lightGray = const Color.fromARGB(255, 206, 206, 255);
  Color white = const Color.fromARGB(255, 255, 255, 255);
  Color black = const Color.fromARGB(255, 0, 0, 0);
  Color red = const Color.fromARGB(255, 255, 0, 87);
  Color orange = const Color.fromARGB(255, 255, 183, 0);
  Color green = const Color.fromARGB(255, 0, 255, 73);
  Color blue = const Color.fromARGB(255, 0, 228, 255);
}

class CardModel {
  final int number;
  final String color;
  final CardType type;

  CardModel(this.number, this.color, this.type);

  @override
  String toString() {
    if (type == CardType.wild) return 'WILD';
    if (type == CardType.skip) return 'SKIP';
    return '$color $number';
  }
}

class Deck {
  final List<CardModel> _cards = [];
  final List<String> colors = ['Red', 'Green', 'Blue', 'Yellow'];

  Deck() {
    for (var color in colors) {
      for (int n = 1; n <= 12; n++) {
        _cards.add(CardModel(n, color, CardType.normal));
        _cards.add(CardModel(n, color, CardType.normal));
      }
    }

    for (int i = 0; i < 8; i++) {
      _cards.add(CardModel(0, 'Any', CardType.wild));
    }

    for (int i = 0; i < 4; i++) {
      _cards.add(CardModel(0, 'Any', CardType.skip));
    }

    shuffle();
  }

  void shuffle() => _cards.shuffle();
  CardModel draw() => _cards.removeLast();
  bool get isEmpty => _cards.isEmpty;
}

class Player {
  final String name;
  final List<CardModel> hand = [];
  int currentPhase = 1;
  bool hasLaidDown = false;

  Player(this.name);

  void drawCard(Deck deck) {
    hand.add(deck.draw());
  }

  void discard(CardModel card, List<CardModel> discardPile) {
    hand.remove(card);
    discardPile.add(card);
  }

  bool attemptPhase() {
    var freq = <int, int>{};
    for (var card in hand) {
      if (card.type == CardType.normal) {
        freq[card.number] = (freq[card.number] ?? 0) + 1;
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

class GameEngine {
  final List<Player> players;
  final Deck deck = Deck();
  final List<CardModel> discardPile = [];
  int currentPlayerIndex = 0;

  GameEngine(this.players) {
    for (var p in players) {
      for (int i = 0; i < 10; i++) {
        p.drawCard(deck);
      }
    }
    discardPile.add(deck.draw());
  }

  Player get currentPlayer => players[currentPlayerIndex];

  void nextTurn() {
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
  }

  void resetHands() {
    for (var p in players) {
      p.hand.clear();
      for (int i = 0; i < 10; i++) {
        p.drawCard(deck);
      }
      p.hasLaidDown = false;
    }
    discardPile.clear();
    discardPile.add(deck.draw());
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phase 10 Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int pageIndex = 0;

  static const List<Widget> _pages = <Widget>[
    PlayPage(),
    HelpPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      pageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Phase 10"),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.white,
        child: _pages[pageIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.play_circle), label: 'Play'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Help'),
        ],
        currentIndex: pageIndex,
        onTap: _onItemTapped,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class GameSession {
  static final GameSession _instance = GameSession._internal();
  factory GameSession() => _instance;
  GameEngine? currentGame;
  GameSession._internal();
}

class PlayPage extends StatelessWidget {
  const PlayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(ProjectPalette().lightGray),
                ),
                onPressed: () {
                  final game = GameEngine([Player('Bob'), Player('Alice')]);
                  GameSession().currentGame = game;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => GameScreen(engine: game)),
                  );
                },
                child: Text("Start New Game", style: TextStyle(color: ProjectPalette().black)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(ProjectPalette().lightGray),
                ),
                onPressed: () {
                  final game = GameSession().currentGame;
                  if (game != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GameScreen(engine: game)),
                    );
                  } else {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text("No game in progress.")));
                  }
                },
                child: Text("Continue Game", style: TextStyle(color: ProjectPalette().black)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(ProjectPalette().lightGray),
                ),
                onPressed: () {},
                child: Text("Join Game", style: TextStyle(color: ProjectPalette().black)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: const Center(child: Text("Help content goes here.")),
    );
  }
}

class GameScreen extends StatefulWidget {
  final GameEngine engine;
  const GameScreen({super.key, required this.engine});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final String userName = 'Bob';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.engine.currentPlayer.name != userName) {
        _handleAiTurn();
      }
    });
  }

  void _handleAiTurn() async {
    final ai = widget.engine.currentPlayer;

    await Future.delayed(const Duration(seconds: 1));

    if (widget.engine.deck.isEmpty) return;

    setState(() {
      ai.drawCard(widget.engine.deck);
    });

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      ai.attemptPhase();
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (ai.hand.isNotEmpty) {
      setState(() {
        ai.discard(ai.hand.first, widget.engine.discardPile);
      });
    }

    if (ai.hasEmptyHand) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${ai.name} wins the round!')),
      );
      ai.currentPhase++;
      widget.engine.resetHands();
    }

    setState(() {
      widget.engine.nextTurn();
    });

    if (widget.engine.currentPlayer.name != userName) {
      _handleAiTurn();
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.engine.currentPlayer;

    return Scaffold(
      appBar: AppBar(
        title: Text("${player.name}'s Turn"),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Current Phase: ${player.currentPhase}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text("Has Laid Down: ${player.hasLaidDown ? 'Yes' : 'No'}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text("Top of Discard Pile: ${widget.engine.discardPile.last}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: player.hand
                  .map(
                    (card) => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: player.name == userName
                          ? () {
                              setState(() {
                                player.discard(card, widget.engine.discardPile);
                                if (player.hasEmptyHand) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${player.name} wins the round!')),
                                  );
                                  player.currentPhase++;
                                  widget.engine.resetHands();
                                }
                                widget.engine.nextTurn();
                              });
                            }
                          : null,
                      child: Text(card.toString()),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: player.name == userName
                  ? () {
                      setState(() {
                        player.drawCard(widget.engine.deck);
                      });
                    }
                  : null,
              child: const Text('Draw Card'),
            ),
          ],
        ),
      ),
    );
  }
}
