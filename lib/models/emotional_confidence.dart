enum ConfidenceLevel { low, medium, high }

class EmotionalConfidence {
  final ConfidenceLevel level;
  final double score;
  final int signalCount;
  final DateTime lastUpdated;
  final List<String> signals;

  EmotionalConfidence({
    required this.level,
    required this.score,
    required this.signalCount,
    required this.lastUpdated,
    required this.signals,
  });

  bool canEscalateToMedical() => level == ConfidenceLevel.high && signalCount >= 5;
}
