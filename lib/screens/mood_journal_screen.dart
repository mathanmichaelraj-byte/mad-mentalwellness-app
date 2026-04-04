import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/emotional_inference_service.dart';
import '../utils/app_theme.dart';
import '../utils/sentiment_analyzer.dart';

const _journalMoods = [
  {'emoji': '🤩', 'label': 'Amazing', 'color': Color(0xFF6366F1)},
  {'emoji': '😊', 'label': 'Happy',   'color': Color(0xFF10B981)},
  {'emoji': '😐', 'label': 'Okay',    'color': Color(0xFF14B8A6)},
  {'emoji': '😔', 'label': 'Sad',     'color': Color(0xFF6B7280)},
  {'emoji': '😢', 'label': 'Terrible','color': Color(0xFFEF4444)},
];

const _allTags = [
  'Anxious','Grateful','Tired','Energetic','Focused',
  'Peaceful','Overwhelmed','Hopeful','Lonely','Proud',
];

class MoodJournalScreen extends StatefulWidget {
  const MoodJournalScreen({super.key});
  @override
  State<MoodJournalScreen> createState() => _MoodJournalScreenState();
}

class _MoodJournalScreenState extends State<MoodJournalScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _load();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final entries = await DatabaseService.instance.getJournalEntries();
    setState(() { _entries = entries; _loading = false; });
    _fadeCtrl.forward(from: 0);
  }

  Future<void> _openEditor({Map<String, dynamic>? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JournalEditor(existing: existing, onSaved: _load),
    );
  }

  Future<void> _delete(int id) async {
    await DatabaseService.instance.deleteJournalEntry(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const Text('📓 Mood Journal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _entries.isEmpty
              ? _buildEmpty()
              : FadeTransition(
                  opacity: _fadeCtrl,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    itemCount: _entries.length,
                    itemBuilder: (_, i) => _EntryCard(
                      entry: _entries[i],
                      index: i,
                      onDelete: () => _delete(_entries[i]['id'] as int),
                      onTap: () => _openEditor(existing: _entries[i]),
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('📓', style: const TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      Text('No journal entries yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
      const SizedBox(height: 8),
      Text('Tap + to write your first entry', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary(context))),
    ]),
  );
}

class _EntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  const _EntryCard({required this.entry, required this.index, required this.onDelete, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final moodIdx = entry['mood'] as int;
    final mood = _journalMoods[moodIdx];
    final color = mood['color'] as Color;
    final date = DateTime.parse(entry['date'] as String);
    final tags = (entry['tags'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? [];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + index * 60),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child)),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.25)),
            boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(children: [
                Text(mood['emoji'] as String, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(mood['label'] as String, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
                  Text(DateFormat('EEE, MMM d · h:mm a').format(date),
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
                ])),
                // Sentiment badge
                if ((entry['sentiment'] as String?) != null)
                  _SentimentBadge(sentiment: entry['sentiment'] as String),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: AppTheme.textSecondary(context), size: 20),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if ((entry['content'] as String?)?.isNotEmpty == true)
                  Text(entry['content'] as String,
                      maxLines: 3, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, height: 1.55, color: AppTheme.textPrimary(context))),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6, children: tags.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                  )).toList()),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _JournalEditor extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;
  const _JournalEditor({this.existing, required this.onSaved});
  @override
  State<_JournalEditor> createState() => _JournalEditorState();
}

class _JournalEditorState extends State<_JournalEditor> {
  int _mood = 2;
  final _contentCtrl = TextEditingController();
  final Set<String> _selectedTags = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _mood = widget.existing!['mood'] as int;
      _contentCtrl.text = widget.existing!['content'] as String? ?? '';
      final tags = (widget.existing!['tags'] as String?)?.split(',').where((t) => t.isNotEmpty) ?? [];
      _selectedTags.addAll(tags);
    }
  }

  @override
  void dispose() { _contentCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final text = _contentCtrl.text.trim();
      final sentiment = text.isNotEmpty ? SentimentAnalyzer.analyze(text) : 'neutral';
      await DatabaseService.instance.insertJournalEntry(
        mood: _mood,
        content: text,
        tags: _selectedTags.join(','),
        sentiment: sentiment,
        id: widget.existing?['id'] as int?,
      );
      // Invalidate emotional state cache so home screen reflects new entry
      EmotionalInferenceService.instance.invalidateCache();
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save entry: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final moodData = _journalMoods[_mood];
    final color = moodData['color'] as Color;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(widget.existing == null ? 'New Entry' : 'Edit Entry',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
          const SizedBox(height: 20),
          // Mood picker
          Text('How are you feeling?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary(context))),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(_journalMoods.length, (i) {
            final m = _journalMoods[i];
            final sel = _mood == i;
            return GestureDetector(
              onTap: () => setState(() => _mood = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: sel ? (m['color'] as Color).withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sel ? (m['color'] as Color) : Colors.transparent, width: 2),
                ),
                child: Column(children: [
                  AnimatedScale(scale: sel ? 1.2 : 1.0, duration: const Duration(milliseconds: 200),
                      child: Text(m['emoji'] as String, style: const TextStyle(fontSize: 28))),
                  const SizedBox(height: 4),
                  Text(m['label'] as String, style: TextStyle(fontSize: 10, fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      color: sel ? (m['color'] as Color) : AppTheme.textSecondary(context))),
                ]),
              ),
            );
          })),
          const SizedBox(height: 20),
          // Content
          Text('Write about your day', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary(context))),
          const SizedBox(height: 10),
          TextField(
            controller: _contentCtrl,
            maxLines: 5,
            style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 14, height: 1.6),
            decoration: InputDecoration(
              hintText: 'What\'s on your mind today?',
              hintStyle: TextStyle(color: AppTheme.textSecondary(context)),
              filled: true,
              fillColor: AppTheme.primary.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius), borderSide: BorderSide(color: color, width: 2)),
            ),
          ),
          const SizedBox(height: 20),
          // Tags
          Text('Add tags', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary(context))),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: _allTags.map((tag) {
            final sel = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () => setState(() => sel ? _selectedTags.remove(tag) : _selectedTags.add(tag)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? color.withOpacity(0.15) : AppTheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? color : Colors.transparent),
                ),
                child: Text(tag, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                    color: sel ? color : AppTheme.textSecondary(context))),
              ),
            );
          }).toList()),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius))),
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Save Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SentimentBadge extends StatelessWidget {
  final String sentiment;
  const _SentimentBadge({required this.sentiment});

  @override
  Widget build(BuildContext context) {
    final s = sentiment.toLowerCase();
    final color = s == 'positive'
        ? const Color(0xFF10B981)
        : s == 'negative'
            ? const Color(0xFFEF4444)
            : const Color(0xFF14B8A6);
    final icon = s == 'positive'
        ? Icons.sentiment_satisfied_rounded
        : s == 'negative'
            ? Icons.sentiment_dissatisfied_rounded
            : Icons.sentiment_neutral_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(s[0].toUpperCase() + s.substring(1),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}
