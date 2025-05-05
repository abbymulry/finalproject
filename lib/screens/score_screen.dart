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

  void _addPlayer() {
    final name = _nameController.text.trim();
    if(name.isEmpty) return;
    final newPlayer = Player(id: '0', name: name);
    setState(() {
      _players.add((newPlayer));
      _scoreControllers[newPlayer] = TextEditingController();
      _phaseCompleted[newPlayer] = false;
      _nameController.clear();
    });
  }

  void _submitRound() {
    setState(() {
      for(var player in _players)
      {
        final scoreText = _scoreControllers[player]?.text??'';
        final score = int.tryParse(scoreText) ?? 0;
        player.score += score;
        if(_phaseCompleted[player] == true)
        {
          player.currentPhase += 1;
        }
        _scoreControllers[player]?.clear();
        _phaseCompleted[player] = false;
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
                          Text("Phase: ${player.currentPhase} | Score: ${player.score}"),
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
            ElevatedButton(
              onPressed: _players.isNotEmpty ? _submitRound : null,
              child: Text('Submit Round'),
            )
          ],
        ),
      ),
    );
  }
}
