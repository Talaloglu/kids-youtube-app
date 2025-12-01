import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../widgets/video_card.dart';
import '../widgets/state_view.dart';
import 'video_player_screen.dart';
import '../utils/custom_route.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HistoryProvider>(context, listen: false).loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch History'),
        actions: [
          Consumer<HistoryProvider>(
            builder: (context, historyProvider, _) {
              if (historyProvider.history.isEmpty) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear History',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear History?'),
                      content: const Text(
                        'Are you sure you want to clear your watch history?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            historyProvider.clearHistory();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, historyProvider, _) {
          if (!historyProvider.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (historyProvider.history.isEmpty) {
            return StateView.empty(message: 'No watch history yet.');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historyProvider.history.length,
            itemBuilder: (context, index) {
              final video = historyProvider.history[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: VideoCard(
                  video: video,
                  onTap: () {
                    Navigator.push(
                      context,
                      FadePageRoute(page: VideoPlayerScreen(video: video)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
