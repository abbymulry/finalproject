import 'package:flutter/material.dart';
import 'play_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; 

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final PageController _controller = PageController();


  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> helpContent = [
    {
      'title': AppLocalizations.of(context).object,
      'text': AppLocalizations.of(context).helppage1,
    },
    {
      'title': AppLocalizations.of(context).setup,
      'text': AppLocalizations.of(context).helppage2,
    },
    {
      'title': AppLocalizations.of(context).rules,
      'text': AppLocalizations.of(context).helppage3,
    },
    {
      'title': AppLocalizations.of(context).specialcard,
      'text': AppLocalizations.of(context).helppage4,
    },
  ];
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).howtoplay),
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

