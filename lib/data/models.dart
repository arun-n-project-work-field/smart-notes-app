import 'dart:math';

class NotesModel {
  int? id;
  String title;
  String content;
  bool isImportant;
  DateTime date;
  String? imagePath;
  DateTime? reminderDateTime;
  int? userId;

  NotesModel({
    this.id,
    required this.title,
    required this.content,
    required this.isImportant,
    required this.date,
    this.imagePath,
    this.reminderDateTime,
    this.userId,
  });

  factory NotesModel.fromMap(Map<String, dynamic> map) {
    return NotesModel(
      id: map['_id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      isImportant: map['isImportant'] == 1,
      date: DateTime.parse(map['date']),
      imagePath: map['imagePath'],
      reminderDateTime:
          map['reminderDateTime'] != null
              ? DateTime.tryParse(map['reminderDateTime'])
              : null,
      userId: map['userId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'title': title,
      'content': content,
      'isImportant': isImportant ? 1 : 0,
      'date': date.toIso8601String(),
      'imagePath': imagePath,
      'reminderDateTime': reminderDateTime?.toIso8601String(),
      'userId': userId,
    };
  }

  factory NotesModel.random() {
    final random = Random();
    return NotesModel(
      id: random.nextInt(1000) + 1,
      title: 'Lorem Ipsum ' * (random.nextInt(4) + 1),
      content: 'Lorem Ipsum ' * (random.nextInt(4) + 1),
      isImportant: random.nextBool(),
      date: DateTime.now().add(Duration(hours: random.nextInt(100))),
      imagePath: null,
      reminderDateTime: DateTime.now().add(Duration(hours: random.nextInt(48))),
      userId: 1,
    );
  }
}
