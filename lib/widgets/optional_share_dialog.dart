import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../models/emotional_note.dart';
import '../utils/sentiment_analyzer.dart';

class OptionalShareDialog {
  static Future<void> show(BuildContext context, {bool autoShow = false}) async {
    if (autoShow) {
      final prefs = await SharedPreferences.getInstance();
      final lastShown = prefs.getString('last_dialog_shown');
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      if (lastShown == today) return;
    }
    
    if (!context.mounted) return;
    
    await Future.delayed(const Duration(milliseconds: 300));
    if (!context.mounted) return;
    
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _ShareDialog(autoShow: autoShow),
    );
    
    if (autoShow) {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setString('last_dialog_shown', today);
    }
  }
}

class _ShareDialog extends StatefulWidget {
  final bool autoShow;
  
  const _ShareDialog({this.autoShow = false});

  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitShare() async {
    if (_controller.text.trim().isEmpty) return;

    final sentiment = SentimentAnalyzer.analyze(_controller.text);
    
    final note = EmotionalNote(
      content: _controller.text,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      sentiment: sentiment,
    );

    await DatabaseService.instance.insertEmotionalNote(note);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for sharing'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('How\'s your day?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Feel free to share what\'s on your mind, or skip if you prefer.',
            style: TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'What\'s on your mind?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Skip'),
        ),
        ElevatedButton(
          onPressed: _submitShare,
          child: const Text('Share'),
        ),
      ],
    );
  }
}
