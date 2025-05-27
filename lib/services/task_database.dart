import 'package:notes_demo_project/services/notification_service.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../data/task_model.dart';

class TaskDatabaseService {
  static final TaskDatabaseService db = TaskDatabaseService._();

  TaskDatabaseService._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tasks.db');

    return await openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            isDone INTEGER,
            dateCreated TEXT,
            startDate TEXT,
            startTime TEXT,
            endDate TEXT,
            endTime TEXT,
            dueDate TEXT,
            dueTime TEXT,
            priority TEXT,
            userId INTEGER,
            isRange INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE tasks ADD COLUMN startDate TEXT;");
          await db.execute("ALTER TABLE tasks ADD COLUMN endDate TEXT;");
          await db.execute("ALTER TABLE tasks ADD COLUMN priority TEXT;");
        }
        if (oldVersion < 3) {
          await db.execute("ALTER TABLE tasks ADD COLUMN dueDate TEXT;");
        }
        if (oldVersion < 4) {
          await db.execute("ALTER TABLE tasks ADD COLUMN userId INTEGER;");
        }
        if (oldVersion < 5) {
          await db.execute("ALTER TABLE tasks ADD COLUMN dueTime TEXT;");
          await db.execute("ALTER TABLE tasks ADD COLUMN startTime TEXT;");
          await db.execute("ALTER TABLE tasks ADD COLUMN endTime TEXT;");
          await db.execute("ALTER TABLE tasks ADD COLUMN isRange INTEGER;");
        }
      },
    );
  }

  Future<List<TaskModel>> getTasks({int? userId}) async {
    final db = await database;
    List<Map<String, dynamic>> result;
    if (userId != null) {
      result = await db.query(
        'tasks',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'dateCreated DESC',
      );
    } else {
      result = await db.query('tasks', orderBy: 'dateCreated DESC');
    }
    return result.map((e) => TaskModel.fromMap(e)).toList();
  }

  Future<TaskModel?> getTaskById(int id) async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return TaskModel.fromMap(result.first);
  }

  Future<int> insertTask(TaskModel task) async {
    final db = await database;
    final id = await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _scheduleTaskNotification(task.copyWith(id: id));
    return id;
  }

  Future<void> updateTask(TaskModel task) async {
    final db = await database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _scheduleTaskNotification(task);
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllCompleted({int? userId}) async {
    final db = await database;
    if (userId != null) {
      await db.delete(
        'tasks',
        where: 'isDone = ? AND userId = ?',
        whereArgs: [1, userId],
      );
    } else {
      await db.delete('tasks', where: 'isDone = ?', whereArgs: [1]);
    }
  }

  Future<void> _scheduleTaskNotification(TaskModel task) async {
    try {
      if (task.isDone == true) return;

      DateTime? notifTime;
      String body = "";

      if (task.isRange) {
        if (task.endDate != null && task.endTime != null) {
          notifTime = _combineDateAndTime(task.endDate!, task.endTime!);
          body = "Task \"${task.title}\" deadline reached (range end)!";
        }
      } else {
        if (task.dueDate != null && task.dueTime != null) {
          notifTime = _combineDateAndTime(task.dueDate!, task.dueTime!);
          body = "Task \"${task.title}\" deadline reached!";
        }
      }

      if (notifTime != null &&
          body.isNotEmpty &&
          notifTime.isAfter(DateTime.now())) {
        print("Scheduling notification for '${task.title}' at $notifTime");
        await NotificationService().scheduleNotification(
          id: task.id ?? DateTime.now().millisecondsSinceEpoch,
          title: "Task Reminder",
          body: body,
          scheduledDate: notifTime,
        );
      }
    } catch (e) {
      print("Notification scheduling failed: $e");
    }
  }

  DateTime _combineDateAndTime(String dateStr, String timeStr) {
    final date = DateTime.parse(dateStr);
    final parts = timeStr.split(":");
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
