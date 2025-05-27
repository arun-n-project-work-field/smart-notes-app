import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../data/models.dart';

class NotesDatabaseService {
  NotesDatabaseService._();

  static final NotesDatabaseService db = NotesDatabaseService._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await init();
    return _database!;
  }

  Future<Database> init() async {
    String dbPath = await getDatabasesPath();
    String fullPath = join(dbPath, 'notes.db');
    print("Database path: $fullPath");

    return await openDatabase(
      fullPath,
      version: 4,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE Notes (
            _id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            content TEXT,
            date TEXT,
            isImportant INTEGER,
            imagePath TEXT,
            reminderDateTime TEXT,
            userId INTEGER
          );
        ''');
        print('New table created at version 4');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE Notes ADD COLUMN imagePath TEXT;');
          print('Upgraded to v2: imagePath column added');
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE Notes ADD COLUMN reminderDateTime TEXT;',
          );
          print('Upgraded to v3: reminderDateTime column added');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE Notes ADD COLUMN userId INTEGER;');
          print('Upgraded to v4: userId column added');
        }
      },
    );
  }

  Future<List<NotesModel>> getNotesFromDB([int? paramUserId]) async {
    final db = await database;
    int? userId = paramUserId;
    if (userId == null) {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('user_id');
    }
    if (userId == null) return [];

    final List<Map<String, dynamic>> maps = await db.query(
      'Notes',
      columns: [
        '_id',
        'title',
        'content',
        'date',
        'isImportant',
        'imagePath',
        'reminderDateTime',
        'userId',
      ],
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => NotesModel.fromMap(map)).toList();
  }

  Future<void> updateNoteInDB(NotesModel updatedNote) async {
    final db = await database;
    await db.update(
      'Notes',
      updatedNote.toMap(),
      where: '_id = ?',
      whereArgs: [updatedNote.id],
    );
    print('Note updated: ${updatedNote.title}');
  }

  Future<void> deleteNoteInDB(NotesModel noteToDelete) async {
    final db = await database;
    await db.delete('Notes', where: '_id = ?', whereArgs: [noteToDelete.id]);
    print('Note deleted');
  }

  Future<NotesModel> addNoteInDB(NotesModel newNote) async {
    final db = await database;
    if (newNote.title.trim().isEmpty) {
      newNote.title = 'Untitled Note';
    }
    int id = await db.insert('Notes', newNote.toMap()..remove('_id'));
    newNote.id = id;
    print('Note added: ${newNote.title}');
    return newNote;
  }
}
