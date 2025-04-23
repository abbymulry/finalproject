// Erich Krueger
// Dillon Summers
// Thomas Woodcum
// Abby Mulry
//Mark Herpin
//Jianan Niu
//Dylan Miller
// Joseph (Ashton) Berret
//Game
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 109, 92, 156)),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int pageIndex = 0;

  static const List<Widget>_pages = <Widget> [
    PlayPage(),
    HelpPage(),
  ];

void _onItemTapped(int index)
{
  setState((){
    pageIndex = index;
  });
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Phase 10"),
        backgroundColor: Color.fromARGB(255, 47,47,60),
        foregroundColor: Colors.white,
      ),
      body: _pages[pageIndex],
      bottomNavigationBar: BottomNavigationBar(
        showUnselectedLabels: true,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle), 
            label: 'Play',
            backgroundColor: Color.fromARGB(255, 47,47,60),
            
            ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help), 
            label: 'Help',
            ),
        ],
        currentIndex: pageIndex,
        onTap: _onItemTapped,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();  
}

class _PlayPageState extends State<PlayPage> {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  // Navigate to new game logic
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => NewGameScreen()));
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Color.fromARGB(255, 255, 183, 0)),
                ),
                child: const Text(
                  "Start New Game",
                  style: TextStyle(color: Colors.black)
                  ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Navigate to continue game logic
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => ContinueGameScreen()));
                },
                child: const Text(
                  "Continue Game",
                  style: TextStyle(color: Colors.black)
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Navigate to join game logic
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => JoinGameScreen()));
                },
                child: const Text(
                  "Join Game",
                  style: TextStyle(color: Colors.black)),
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

    return Scaffold(
      body: Center(
        child: Text("There"),
      )
    );
  }
}
