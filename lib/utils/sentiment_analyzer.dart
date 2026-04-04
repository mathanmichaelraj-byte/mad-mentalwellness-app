/// Enhanced NLP sentiment & emotion analyzer.
/// Pure rule-based — no ML dependencies.
/// Detects: sentiment (positive/neutral/negative),
///          emotion (joy, calm, sadness, anxiety, anger, grief, hope, neutral),
///          intensity (mild/moderate/strong),
///          and a numeric score.
class SentimentAnalyzer {
  // ── Weighted sentiment lexicons ──────────────────────────────────────────
  static const Map<String, double> _negativeWords = {
    // Severe
    'suicidal': 4.0, 'hopeless': 3.5, 'worthless': 3.5, 'devastated': 3.5,
    'depressed': 3.0, 'miserable': 3.0, 'shattered': 3.0, 'broken': 2.8,
    // Moderate
    'anxious': 2.5, 'overwhelmed': 2.5, 'terrified': 2.5, 'panicking': 2.5,
    'stressed': 2.0, 'worried': 2.0, 'scared': 2.0, 'angry': 2.0,
    'frustrated': 2.0, 'resentful': 2.0, 'bitter': 2.0, 'furious': 2.5,
    // Mild
    'sad': 1.5, 'lonely': 1.5, 'tired': 1.5, 'exhausted': 1.8, 'hurt': 1.5,
    'numb': 1.5, 'empty': 1.8, 'lost': 1.5, 'confused': 1.2, 'drained': 1.5,
    'bad': 1.0, 'upset': 1.0, 'down': 1.0, 'unhappy': 1.2, 'difficult': 1.0,
    'struggling': 1.5, 'crying': 1.5, 'tears': 1.2, 'grief': 2.0, 'pain': 1.5,
  };

  static const Map<String, double> _positiveWords = {
    // Strong
    'amazing': 3.0, 'wonderful': 3.0, 'excellent': 3.0, 'fantastic': 3.0,
    'thrilled': 2.8, 'ecstatic': 3.0, 'overjoyed': 3.0, 'elated': 2.8,
    // Moderate
    'great': 2.5, 'excited': 2.5, 'grateful': 2.5, 'blessed': 2.5,
    'happy': 2.0, 'good': 2.0, 'love': 2.0, 'joy': 2.0, 'peaceful': 2.0,
    'proud': 2.0, 'confident': 2.0, 'motivated': 2.0, 'inspired': 2.0,
    // Mild
    'calm': 1.5, 'relaxed': 1.5, 'better': 1.5, 'improving': 1.5, 'hopeful': 1.8,
    'okay': 1.0, 'fine': 1.0, 'alright': 1.0, 'decent': 1.0, 'content': 1.5,
    'serene': 1.8, 'refreshed': 1.5, 'energized': 1.8, 'optimistic': 2.0,
  };

  // ── Emotion keyword clusters ─────────────────────────────────────────────
  static const Map<String, List<String>> _emotionKeywords = {
    'joy':     ['happy', 'joy', 'excited', 'thrilled', 'elated', 'ecstatic', 'delighted', 'cheerful', 'laugh', 'smile', 'celebrate'],
    'calm':    ['calm', 'peaceful', 'serene', 'relaxed', 'tranquil', 'still', 'quiet', 'centered', 'grounded', 'balanced', 'content'],
    'sadness': ['sad', 'crying', 'tears', 'grief', 'loss', 'lonely', 'empty', 'numb', 'heartbroken', 'depressed', 'miserable', 'broken'],
    'anxiety': ['anxious', 'worried', 'nervous', 'panic', 'scared', 'fear', 'dread', 'overwhelmed', 'tense', 'uneasy', 'restless', 'stressed'],
    'anger':   ['angry', 'furious', 'frustrated', 'irritated', 'annoyed', 'rage', 'resentful', 'bitter', 'mad', 'outraged'],
    'grief':   ['grief', 'mourning', 'loss', 'miss', 'missing', 'gone', 'death', 'died', 'passed', 'bereaved'],
    'hope':    ['hope', 'hopeful', 'optimistic', 'looking forward', 'better days', 'improving', 'progress', 'healing', 'growing'],
  };

  // ── Negations ────────────────────────────────────────────────────────────
  static const List<String> _negations = [
    'not', 'no', 'never', 'neither', 'nobody', 'nothing', 'nowhere',
    'hardly', 'barely', 'scarcely', "don't", "doesn't", "didn't", "won't",
    "wouldn't", "shouldn't", "can't", "cannot", "isn't", "wasn't", "aren't",
  ];

  // ── Intensifiers ─────────────────────────────────────────────────────────
  static const Map<String, double> _intensifiers = {
    'very': 1.5, 'extremely': 2.0, 'really': 1.5, 'so': 1.4, 'incredibly': 2.0,
    'absolutely': 2.0, 'completely': 1.8, 'totally': 1.8, 'utterly': 2.0,
    'deeply': 1.7, 'profoundly': 1.9, 'terribly': 1.8, 'awfully': 1.7,
  };

  // ── Diminishers ──────────────────────────────────────────────────────────
  static const Map<String, double> _diminishers = {
    'slightly': 0.5, 'a bit': 0.6, 'kind of': 0.6, 'sort of': 0.6,
    'somewhat': 0.7, 'a little': 0.6, 'mildly': 0.5, 'fairly': 0.8,
  };

  // ── Context phrases ──────────────────────────────────────────────────────
  static const Map<String, double> _contextPhrases = {
    'want to die': -5.0, 'end it all': -5.0, 'no reason to live': -5.0,
    'can\'t go on': -4.0, 'give up': -3.0, 'can\'t take': -3.0,
    'falling apart': -3.0, 'breaking down': -3.0, 'hit rock bottom': -3.5,
    'getting better': 3.0, 'feeling better': 3.0, 'much better': 3.0,
    'thank': 2.0, 'appreciate': 2.0, 'grateful for': 2.5,
    'looking forward': 2.5, 'excited about': 2.5, 'proud of': 2.0,
    'can\'t stop crying': -3.5, 'so tired': -2.0, 'exhausted from': -2.0,
  };

  // ── Public API ───────────────────────────────────────────────────────────

  /// Returns 'positive', 'neutral', or 'negative'.
  static String analyze(String text) => analyzeDetailed(text)['sentiment'] as String;

  /// Returns the dominant emotion label.
  static String detectEmotion(String text) => analyzeDetailed(text)['emotion'] as String;

  /// Full analysis map with keys:
  ///   sentiment, score, confidence, emotion, intensity, emotionScores
  static Map<String, dynamic> analyzeDetailed(String text) {
    if (text.trim().isEmpty) {
      return {
        'sentiment': 'neutral', 'score': 0.0, 'confidence': 0.0,
        'emotion': 'neutral', 'intensity': 'mild', 'emotionScores': <String, double>{},
      };
    }

    final lower = text.toLowerCase();
    final words = lower.split(RegExp(r'\s+'));
    double score = 0.0;
    int wordCount = 0;

    // ── Context phrase scan ──────────────────────────────────────────────
    for (final entry in _contextPhrases.entries) {
      if (lower.contains(entry.key)) score += entry.value;
    }

    // ── Word-level scan ──────────────────────────────────────────────────
    for (int i = 0; i < words.length; i++) {
      final word = words[i].replaceAll(RegExp(r"[^a-z']"), '');
      if (word.isEmpty) continue;
      wordCount++;

      // Intensifier from previous word
      double multiplier = 1.0;
      if (i > 0) {
        final prev = words[i - 1].replaceAll(RegExp(r"[^a-z']"), '');
        multiplier = _intensifiers[prev] ?? 1.0;
      }

      // Diminisher from previous word
      if (i > 0) {
        final prev = words[i - 1].replaceAll(RegExp(r"[^a-z']"), '');
        multiplier *= _diminishers[prev] ?? 1.0;
      }

      // Negation window (3 words back)
      bool isNegated = false;
      for (int j = 1; j <= 3 && i - j >= 0; j++) {
        final prev = words[i - j].replaceAll(RegExp(r"[^a-z']"), '');
        if (_negations.contains(prev)) { isNegated = true; break; }
      }

      if (_positiveWords.containsKey(word)) {
        final v = _positiveWords[word]! * multiplier;
        score += isNegated ? -v : v;
      } else if (_negativeWords.containsKey(word)) {
        final v = _negativeWords[word]! * multiplier;
        score += isNegated ? v : -v;
      }
    }

    // Punctuation signals
    final exclamations = '!'.allMatches(text).length;
    if (exclamations > 2) score = score.abs() * (score > 0 ? 1.3 : 1.2);
    if ('?'.allMatches(text).length > 2) score -= 0.5;

    // ── Sentiment label ──────────────────────────────────────────────────
    final String sentiment;
    if (score <= -2.0) {
      sentiment = 'negative';
    } else if (score >= 2.0) {
      sentiment = 'positive';
    } else {
      sentiment = 'neutral';
    }

    // ── Emotion detection ────────────────────────────────────────────────
    final emotionScores = <String, double>{};
    for (final entry in _emotionKeywords.entries) {
      double es = 0;
      for (final kw in entry.value) {
        if (lower.contains(kw)) es += 1.0;
      }
      if (es > 0) emotionScores[entry.key] = es;
    }

    String emotion = 'neutral';
    if (emotionScores.isNotEmpty) {
      emotion = emotionScores.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    } else if (sentiment == 'positive') {
      emotion = 'joy';
    } else if (sentiment == 'negative') {
      emotion = 'sadness';
    }

    // ── Intensity ────────────────────────────────────────────────────────
    final absScore = score.abs();
    final String intensity;
    if (absScore >= 4.0) {
      intensity = 'strong';
    } else if (absScore >= 2.0) {
      intensity = 'moderate';
    } else {
      intensity = 'mild';
    }

    final confidence = (absScore / (wordCount > 0 ? wordCount : 1)).clamp(0.0, 1.0);

    return {
      'sentiment': sentiment,
      'score': score,
      'confidence': confidence,
      'emotion': emotion,
      'intensity': intensity,
      'emotionScores': emotionScores,
    };
  }

  /// Returns a human-readable emotion label for display.
  static String emotionLabel(String emotion) {
    const labels = {
      'joy': '😊 Joyful', 'calm': '😌 Calm', 'sadness': '😢 Sad',
      'anxiety': '😰 Anxious', 'anger': '😠 Frustrated',
      'grief': '💔 Grieving', 'hope': '🌱 Hopeful', 'neutral': '😐 Neutral',
    };
    return labels[emotion] ?? '😐 Neutral';
  }

  /// Maps emotion to a color hex for UI use.
  static int emotionColor(String emotion) {
    const colors = {
      'joy': 0xFF10B981, 'calm': 0xFF0D9488, 'sadness': 0xFF6366F1,
      'anxiety': 0xFFF59E0B, 'anger': 0xFFEF4444,
      'grief': 0xFF8B5CF6, 'hope': 0xFF2DD4BF, 'neutral': 0xFF6B7280,
    };
    return colors[emotion] ?? 0xFF6B7280;
  }
}
