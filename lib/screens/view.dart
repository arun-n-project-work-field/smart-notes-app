import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notes_demo_project/data/models.dart';
import 'package:notes_demo_project/screens/edit.dart';
import 'package:notes_demo_project/services/database.dart';
import 'package:notes_demo_project/services/sharedPref.dart';
import 'package:share_plus/share_plus.dart';

class ViewNotePage extends StatefulWidget {
  final Function() triggerRefetch;
  final NotesModel currentNote;

  ViewNotePage({
    Key? key,
    required this.triggerRefetch,
    required this.currentNote,
  }) : super(key: key);

  @override
  _ViewNotePageState createState() => _ViewNotePageState();
}

class _ViewNotePageState extends State<ViewNotePage> {
  bool headerShouldShow = false;
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() => headerShouldShow = true);
    });
  }

  Future<void> _loadUserId() async {
    final id = await getCurrentUserId();
    setState(() {
      userId = id;
    });
  }

  bool get _isOwner {
    return userId != null && userId == widget.currentNote.userId;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[700];

    if (userId == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      );
    }

    if (!_isOwner) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                "You do not have permission to view this note!",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Go back"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: <Widget>[
          ListView(
            physics: const BouncingScrollPhysics(),
            children: <Widget>[
              const SizedBox(height: 80),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: AnimatedOpacity(
                  opacity: headerShouldShow ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                  child: Text(
                    widget.currentNote.title,
                    style: TextStyle(
                      fontFamily: 'ZillaSlab',
                      fontWeight: FontWeight.w700,
                      fontSize: 36,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: headerShouldShow ? 1 : 0,
                child: Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    DateFormat.yMd().add_jm().format(widget.currentNote.date),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                child: Text(
                  widget.currentNote.content,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              if (widget.currentNote.imagePath != null &&
                  widget.currentNote.imagePath!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(widget.currentNote.imagePath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (widget.currentNote.reminderDateTime != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.amber.withOpacity(0.11)
                              : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isDark
                                ? Colors.amber.withOpacity(0.26)
                                : Colors.amber.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.alarm,
                          color: Colors.amber.shade800.withOpacity(0.85),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Reminder: ${DateFormat('dd/MM/yyyy - HH:mm').format(widget.currentNote.reminderDateTime!)}",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.amber.shade800.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 100),
            ],
          ),
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 80,
                color: Theme.of(context).canvasColor.withOpacity(0.3),
                child: SafeArea(
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: textColor),
                        onPressed: handleBack,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          widget.currentNote.isImportant
                              ? Icons.flag
                              : Icons.outlined_flag,
                          color:
                              widget.currentNote.isImportant
                                  ? Colors.amber
                                  : textColor,
                        ),
                        onPressed: markImportantAsDirty,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: textColor),
                        onPressed: handleDelete,
                      ),
                      IconButton(
                        icon: Icon(Icons.share_outlined, color: textColor),
                        onPressed: handleShare,
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: textColor),
                        onPressed: handleEdit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> handleSave() async {
    await NotesDatabaseService.db.updateNoteInDB(widget.currentNote);
    widget.triggerRefetch();
  }

  void markImportantAsDirty() {
    setState(() {
      widget.currentNote.isImportant = !widget.currentNote.isImportant;
    });
    handleSave();
  }

  void handleEdit() {
    Navigator.pop(context);
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder:
            (context) => EditNotePage(
              existingNote: widget.currentNote,
              triggerRefetch: widget.triggerRefetch,
            ),
      ),
    );
  }

  void handleShare() {
    Share.share(
      '${widget.currentNote.title.trim()}\n(On: ${widget.currentNote.date.toIso8601String().substring(0, 10)})\n\n${widget.currentNote.content}',
    );
  }

  void handleBack() {
    Navigator.pop(context);
  }

  void handleDelete() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(
            'Delete Note',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'This note will be deleted permanently',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'DELETE',
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              onPressed: () async {
                await NotesDatabaseService.db.deleteNoteInDB(
                  widget.currentNote,
                );
                widget.triggerRefetch();
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text(
                'CANCEL',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
}
