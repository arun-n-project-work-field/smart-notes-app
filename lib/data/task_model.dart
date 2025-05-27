class TaskModel {
  final int? id;
  final String title;
  final String description;
  final bool isDone;
  final String dateCreated;

  final String? dueDate;
  final String? dueTime;
  final String? startDate;
  final String? startTime;
  final String? endDate;
  final String? endTime;
  final String? priority;
  final int? userId;
  final bool isRange;

  TaskModel({
    this.id,
    required this.title,
    required this.description,
    required this.isDone,
    required this.dateCreated,
    this.dueDate,
    this.dueTime,
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    this.priority,
    this.userId,
    this.isRange = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isDone': isDone ? 1 : 0,
      'dateCreated': dateCreated,
      'dueDate': dueDate,
      'dueTime': dueTime,
      'startDate': startDate,
      'startTime': startTime,
      'endDate': endDate,
      'endTime': endTime,
      'priority': priority,
      'userId': userId,
      'isRange': isRange ? 1 : 0,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'],
      title: map['title'] ?? "",
      description: map['description'] ?? "",
      isDone: (map['isDone'] ?? 0) == 1,
      dateCreated: map['dateCreated'] ?? "",
      dueDate: map['dueDate'],
      dueTime: map['dueTime'],
      startDate: map['startDate'],
      startTime: map['startTime'],
      endDate: map['endDate'],
      endTime: map['endTime'],
      priority: map['priority'],
      userId: map['userId'],
      isRange: (map['isRange'] ?? 0) == 1,
    );
  }

  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    bool? isDone,
    String? dateCreated,
    String? dueDate,
    String? dueTime,
    String? startDate,
    String? startTime,
    String? endDate,
    String? endTime,
    String? priority,
    int? userId,
    bool? isRange,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      dateCreated: dateCreated ?? this.dateCreated,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      endDate: endDate ?? this.endDate,
      endTime: endTime ?? this.endTime,
      priority: priority ?? this.priority,
      userId: userId ?? this.userId,
      isRange: isRange ?? this.isRange,
    );
  }
}
