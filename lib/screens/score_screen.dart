import 'package:flutter/material.dart';
import '../models/player.dart';

class ScorePage extends StatefulWidget{
  const ScorePage({super.key});
  
  @override
  _ScorePageState createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage>{
  final TextEditingController _nameController = TextEditingController();
  final Map<Player, TextEditingController> _scoreControllers = {};
  final Map<Player, bool> _phaseCompleted = {};
  final List<Player> _players = [];
  final List<Previous> _previousEntries = [];
  bool undoUsed = true;

  void _addPlayer() {
    final name = _nameController.text.trim();
    if(name.isEmpty) return;
    final newPlayer = Player(id: '0', name: name);
    setState(() {
      _players.add((newPlayer));
      _scoreControllers[newPlayer] = TextEditingController();
      _phaseCompleted[newPlayer] = false;
      _nameController.clear();
      _previousEntries.add(Previous(playerIndex: _players.length - 1));
    });
  }

  void _submitRound() {
    setState(() {
      for(int i = 0; i < _players.length; i++)
      {
        if(_players[i].currentPhase < 11)
        {
          _previousEntries[i].currentPhase = _players[i].currentPhase;
          _previousEntries[i].score = _players[i].score;
          final scoreText = _scoreControllers[_players[i]]?.text??'';
          final score = int.tryParse(scoreText) ?? 0;
          _players[i].score += score;
          if(_phaseCompleted[_players[i]] == true)
          {
            _players[i].currentPhase += 1;
          }
          _scoreControllers[_players[i]]?.clear();
          _phaseCompleted[_players[i]] = false;
        }
      }
    });
  }

  void _undoSubmit(){
    setState(() {
      for(int i = 0; i < _players.length; i++)
      {
        _players[i].currentPhase = _previousEntries[i].currentPhase;
        _players[i].score = _previousEntries[i].score;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scoreControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Phase 10 Score Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Player Name'),
                    onSubmitted: (_) => _addPlayer(),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(onPressed: _addPlayer, child: Text('Add'))
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _players.length,
                itemBuilder: (_, index) {
                  final player = _players[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(player.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("Phases Completed: ${player.currentPhase - 1} | Score: ${player.score}"),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _scoreControllers[player],
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(hintText: 'Score this round'),
                                ),
                              ),
                              Checkbox(
                                value: _phaseCompleted[player],
                                onChanged: (value) {
                                  setState(() {
                                    _phaseCompleted[player] = value ?? false;
                                  });
                                },
                              ),
                              Text("Phase Done")
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: (_players.isNotEmpty && undoUsed == false)
                  ? (){
                    setState((){
                      undoUsed = true;
                    });
                    _undoSubmit();
                  }
                  : null,
                  child: Text("Undo"),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _players.isNotEmpty 
                  ? (){ 
                    setState((){
                      undoUsed = false;
                    });
                    _submitRound();
                  } 
                  : null,
                  child: Text('Submit Round'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class Previous {
  final int playerIndex;
  int currentPhase;
  int score;

  Previous({
    required this.playerIndex,
    this.currentPhase = 1,
    this.score = 0,
  });
}