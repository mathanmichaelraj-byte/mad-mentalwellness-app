class EmotionalNote {
  final int? id;
  final String content;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? sentiment; // 'positive', 'neutral', 'negative'

  EmotionalNote({
    this.id,
    required this.content,
    required this.createdAt,
    required this.expiresAt,
    this.sentiment,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'sentiment': sentiment,
    };
  }

  factory EmotionalNote.fromMap(Map<String, dynamic> map) {
    return EmotionalNote(
      id: map['id'],
      content: map['content'],
      createdAt: DateTime.parse(map['createdAt']),
      expiresAt: DateTime.parse(map['expiresAt']),
      sentiment: map['sentiment'],
    );
  }
}
