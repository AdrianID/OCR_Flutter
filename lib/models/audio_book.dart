class AudioBook {
  final String id;
  final String title;
  final String text;
  final DateTime createdAt;

  AudioBook({
    required this.id,
    required this.title,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AudioBook.fromMap(Map<String, dynamic> map) {
    return AudioBook(
      id: map['id'],
      title: map['title'],
      text: map['text'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
} 