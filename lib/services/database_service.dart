import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/emotional_note.dart';
import '../models/behavior_pattern.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mental_wellness.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  /// Ensures all tables and columns exist even if migrations were skipped.
  Future<void> _onOpen(Database db) async {
    // journal_entries — create if missing, then ensure sentiment column exists
    await db.execute('''CREATE TABLE IF NOT EXISTS journal_entries (
      id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL,
      mood INTEGER NOT NULL, content TEXT, tags TEXT, sentiment TEXT)''');
    try { await db.execute('ALTER TABLE journal_entries ADD COLUMN sentiment TEXT'); } catch (_) {}
    try { await db.execute('ALTER TABLE journal_entries ADD COLUMN tags TEXT'); } catch (_) {}
    // Other tables
    await db.execute('''CREATE TABLE IF NOT EXISTS mood_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL UNIQUE,
      mood INTEGER NOT NULL, note TEXT)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS gratitude_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL UNIQUE,
      prompt1 TEXT, prompt2 TEXT, prompt3 TEXT)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS sleep_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL UNIQUE,
      bedtime TEXT NOT NULL, wakeTime TEXT NOT NULL,
      durationHours REAL NOT NULL, quality INTEGER NOT NULL, note TEXT)''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE emotional_notes ADD COLUMN sentiment TEXT');
      await db.execute('ALTER TABLE behavior_patterns ADD COLUMN dayOfWeek TEXT DEFAULT "monday"');
      await db.execute('ALTER TABLE behavior_patterns ADD COLUMN sessionCount INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE behavior_patterns ADD COLUMN featureUsed TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('CREATE TABLE IF NOT EXISTS mood_logs (id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL UNIQUE, mood INTEGER NOT NULL, note TEXT)');
    }
    if (oldVersion < 4) {
      await db.execute('''CREATE TABLE IF NOT EXISTS journal_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, mood INTEGER NOT NULL,
        content TEXT, tags TEXT, sentiment TEXT)''');
      // If upgrading from an earlier schema where journal_entries existed without sentiment,
      // ensure the column is present before insertion.
      try {
        await db.execute('ALTER TABLE journal_entries ADD COLUMN sentiment TEXT');
      } catch (e) {
        // column may already exist; ignore
      }
      await db.execute('''CREATE TABLE IF NOT EXISTS gratitude_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL UNIQUE,
        prompt1 TEXT, prompt2 TEXT, prompt3 TEXT)''');
      await db.execute('''CREATE TABLE IF NOT EXISTS sleep_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL UNIQUE,
        bedtime TEXT NOT NULL, wakeTime TEXT NOT NULL,
        durationHours REAL NOT NULL, quality INTEGER NOT NULL, note TEXT)''');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''CREATE TABLE emotional_notes (
      id INTEGER PRIMARY KEY AUTOINCREMENT, content TEXT NOT NULL,
      createdAt TEXT NOT NULL, expiresAt TEXT NOT NULL, sentiment TEXT)''');
    await db.execute('''CREATE TABLE behavior_patterns (
      id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp TEXT NOT NULL,
      appOpenCount INTEGER NOT NULL, screenTimeSeconds INTEGER NOT NULL,
      timeOfDay TEXT NOT NULL, interactionSpeed INTEGER NOT NULL,
      dayOfWeek TEXT NOT NULL, sessionCount INTEGER NOT NULL, featureUsed TEXT)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS mood_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL UNIQUE,
      mood INTEGER NOT NULL, note TEXT)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS journal_entries (
      id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL,
      mood INTEGER NOT NULL, content TEXT, tags TEXT, sentiment TEXT)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS gratitude_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL UNIQUE,
      prompt1 TEXT, prompt2 TEXT, prompt3 TEXT)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS sleep_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL UNIQUE,
      bedtime TEXT NOT NULL, wakeTime TEXT NOT NULL,
      durationHours REAL NOT NULL, quality INTEGER NOT NULL, note TEXT)''');
  }

  // ── Emotional Notes ────────────────────────────────────────────────────────
  Future<int> insertEmotionalNote(EmotionalNote note) async =>
      (await database).insert('emotional_notes', note.toMap());

  Future<List<EmotionalNote>> getActiveEmotionalNotes() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final r = await db.query('emotional_notes', where: 'expiresAt > ?', whereArgs: [now], orderBy: 'createdAt DESC');
    return r.map((m) => EmotionalNote.fromMap(m)).toList();
  }

  Future<List<EmotionalNote>> getRecentEmotionalNotes({int days = 7}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final r = await db.query('emotional_notes', where: 'createdAt > ?', whereArgs: [cutoff], orderBy: 'createdAt DESC');
    return r.map((m) => EmotionalNote.fromMap(m)).toList();
  }

  Future<int> deleteEmotionalNote(int id) async =>
      (await database).delete('emotional_notes', where: 'id = ?', whereArgs: [id]);

  Future<void> deleteExpiredNotes() async {
    final db = await database;
    await db.delete('emotional_notes', where: 'expiresAt <= ?', whereArgs: [DateTime.now().toIso8601String()]);
  }

  Future<List<EmotionalNote>> getEmotionalNotes() async {
    final r = await (await database).query('emotional_notes', orderBy: 'createdAt DESC');
    return r.map((m) => EmotionalNote.fromMap(m)).toList();
  }

  // ── Behavior Patterns ──────────────────────────────────────────────────────
  Future<int> insertBehaviorPattern(BehaviorPattern pattern) async =>
      (await database).insert('behavior_patterns', pattern.toMap());

  Future<List<BehaviorPattern>> getRecentBehaviorPatterns({int days = 7}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final r = await db.query('behavior_patterns', where: 'timestamp > ?', whereArgs: [cutoff], orderBy: 'timestamp DESC');
    return r.map((m) => BehaviorPattern.fromMap(m)).toList();
  }

  Future<List<BehaviorPattern>> getBehaviorPatterns({int limit = 30}) async {
    final r = await (await database).query('behavior_patterns', orderBy: 'timestamp DESC', limit: limit);
    return r.map((m) => BehaviorPattern.fromMap(m)).toList();
  }

  // ── Mood Logs ──────────────────────────────────────────────────────────────
  Future<void> insertMoodLog({required int mood, String note = ''}) async {
    final today = _today();
    await (await database).insert('mood_logs', {'date': today, 'mood': mood, 'note': note},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getTodayMoodLog() async {
    final r = await (await database).query('mood_logs', where: 'date = ?', whereArgs: [_today()]);
    return r.isEmpty ? null : r.first;
  }

  Future<List<Map<String, dynamic>>> getMoodLogs({int days = 7}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String().split('T')[0];
    return (await database).query('mood_logs', where: 'date >= ?', whereArgs: [cutoff], orderBy: 'date DESC');
  }

  Future<int> getMoodStreak() async => _calcStreak(await (await database).query('mood_logs', orderBy: 'date DESC'));

  // ── Journal Entries ────────────────────────────────────────────────────────
  Future<void> insertJournalEntry({required int mood, required String content, required String tags, String? sentiment, int? id}) async {
    final db = await database;
    final data = <String, dynamic>{
      'date': DateTime.now().toIso8601String(),
      'mood': mood,
      'content': content,
      'tags': tags,
      'sentiment': sentiment ?? 'neutral',
    };
    if (id != null) {
      final count = await db.update('journal_entries', data, where: 'id = ?', whereArgs: [id]);
      if (count == 0) await db.insert('journal_entries', data);
    } else {
      await db.insert('journal_entries', data);
    }
  }

  Future<List<Map<String, dynamic>>> getJournalEntries() async =>
      (await database).query('journal_entries', orderBy: 'date DESC');

  /// Returns journal entries from the last 7 days only (for charts).
  Future<List<Map<String, dynamic>>> getJournalEntriesLast7Days() async {
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 7))
        .toIso8601String()
        .split('T')[0];
    // date is stored as full ISO — compare first 10 chars
    return db.rawQuery(
      "SELECT * FROM journal_entries WHERE substr(date,1,10) >= ? ORDER BY date DESC",
      [cutoff],
    );
  }

  /// Counts rows in a simple date-keyed table (mood_logs, gratitude_logs, sleep_logs)
  /// where date >= cutoff (format 'yyyy-MM-dd').
  Future<int> countEntriesSince(String table, String cutoff) async {
    final r = await (await database).rawQuery(
        'SELECT COUNT(*) as c FROM $table WHERE date >= ?', [cutoff]);
    return r.first['c'] as int? ?? 0;
  }

  /// Counts journal entries since cutoff using substr comparison.
  Future<int> countJournalEntriesSince(String cutoff) async {
    final r = await (await database).rawQuery(
        "SELECT COUNT(*) as c FROM journal_entries WHERE substr(date,1,10) >= ?",
        [cutoff]);
    return r.first['c'] as int? ?? 0;
  }

  Future<void> deleteJournalEntry(int id) async =>
      (await database).delete('journal_entries', where: 'id = ?', whereArgs: [id]);

  Future<int> getJournalStreak() async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT DISTINCT substr(date,1,10) as d FROM journal_entries ORDER BY d DESC");
    return _calcStreak(rows.map((r) => {'date': r['d']}).toList());
  }

  // ── Gratitude Logs ─────────────────────────────────────────────────────────
  Future<void> insertGratitude({required String prompt1, required String prompt2, required String prompt3}) async {
    await (await database).insert('gratitude_logs',
        {'date': _today(), 'prompt1': prompt1, 'prompt2': prompt2, 'prompt3': prompt3},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getTodayGratitude() async {
    final r = await (await database).query('gratitude_logs', where: 'date = ?', whereArgs: [_today()]);
    return r.isEmpty ? null : r.first;
  }

  Future<List<Map<String, dynamic>>> getGratitudeHistory() async =>
      (await database).query('gratitude_logs', orderBy: 'date DESC');

  Future<int> getGratitudeStreak() async => _calcStreak(await (await database).query('gratitude_logs', orderBy: 'date DESC'));

  // ── Sleep Logs ─────────────────────────────────────────────────────────────
  Future<void> insertSleepLog({
    required String bedtime, required String wakeTime,
    required double durationHours, required int quality, String note = '',
  }) async {
    await (await database).insert('sleep_logs',
        {'date': _today(), 'bedtime': bedtime, 'wakeTime': wakeTime, 'durationHours': durationHours, 'quality': quality, 'note': note},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getTodaySleepLog() async {
    final r = await (await database).query('sleep_logs', where: 'date = ?', whereArgs: [_today()]);
    return r.isEmpty ? null : r.first;
  }

  Future<List<Map<String, dynamic>>> getSleepHistory({int days = 7}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String().split('T')[0];
    return (await database).query('sleep_logs', where: 'date >= ?', whereArgs: [cutoff], orderBy: 'date DESC');
  }

  Future<int> getSleepStreak() async => _calcStreak(await (await database).query('sleep_logs', orderBy: 'date DESC'));

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _today() => DateTime.now().toIso8601String().split('T')[0];

  int _calcStreak(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return 0;
    int streak = 0;
    DateTime check = DateTime.now();
    for (final row in rows) {
      final rawDate = row['date'] as String;
      final date = DateTime.parse(rawDate.split('T')[0]);
      final diff = check.difference(date).inDays;
      if (diff == 0 || diff == 1) {
        streak++;
        check = date;
      } else {
        break;
      }
    }
    return streak;
  }

  // ── NLP Insights ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getNlpInsights() async {
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 30))
        .toIso8601String()
        .split('T')[0]; // 'yyyy-MM-dd'

    // journal_entries use full ISO timestamp — compare first 10 chars
    final journal = await db.rawQuery(
        "SELECT * FROM journal_entries WHERE substr(date,1,10) >= ? ORDER BY date DESC",
        [cutoff]);
    // emotional_notes use full ISO timestamp
    final notes = await db.query('emotional_notes',
        where: 'createdAt >= ?',
        whereArgs: [DateTime.now().subtract(const Duration(days: 30)).toIso8601String()],
        orderBy: 'createdAt DESC');

    int pos = 0, neg = 0, neu = 0;

    for (final r in [...journal, ...notes]) {
      final s = (r['sentiment'] as String? ?? 'neutral').toLowerCase();
      if (s == 'positive') pos++;
      else if (s == 'negative') neg++;
      else neu++;
    }

    // Top tags from journal
    final tagCounts = <String, int>{};
    for (final r in journal) {
      final tags = (r['tags'] as String? ?? '').split(',').where((t) => t.isNotEmpty);
      for (final t in tags) tagCounts[t] = (tagCounts[t] ?? 0) + 1;
    }
    final topTags = (tagCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .map((e) => e.key)
        .toList();

    // Mood distribution from mood_logs (last 30 days)
    final moodRows = await db.query('mood_logs',
        where: 'date >= ?', whereArgs: [cutoff]);
    final moodDist = <int, int>{};
    for (final r in moodRows) {
      final m = r['mood'] as int;
      moodDist[m] = (moodDist[m] ?? 0) + 1;
    }

    return {
      'positive': pos,
      'negative': neg,
      'neutral': neu,
      'total': pos + neg + neu,
      'topTags': topTags,
      'moodDistribution': moodDist,
    };
  }

  Future close() async => (await database).close();
}
