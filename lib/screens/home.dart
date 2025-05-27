import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:notes_demo_project/components/faderoute.dart';
import 'package:notes_demo_project/data/models.dart';
import 'package:notes_demo_project/screens/edit.dart';
import 'package:notes_demo_project/screens/settings.dart';
import 'package:notes_demo_project/screens/view.dart';
import 'package:notes_demo_project/services/database.dart';
import 'package:notes_demo_project/services/sharedPref.dart';

import '../components/cards.dart';

class MyHomePage extends StatefulWidget {
  final Function(Brightness brightness) changeTheme;

  MyHomePage({Key? key, required this.title, required this.changeTheme})
    : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isFlagOn = false;
  List<NotesModel> notesList = [];
  TextEditingController searchController = TextEditingController();
  bool isSearchEmpty = true;

  int? userId;

  @override
  void initState() {
    super.initState();
    NotesDatabaseService.db.init();
    setNotesFromDB();
  }

  Future<void> setNotesFromDB() async {
    userId = await getCurrentUserId();
    if (userId == null) return;
    var fetchedNotes = await NotesDatabaseService.db.getNotesFromDB(userId!);
    setState(() {
      notesList = fetchedNotes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notes',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFamily: 'ZillaSlab',
            color: theme.onBackground,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder:
                      (context) =>
                          SettingsPage(changeTheme: widget.changeTheme),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade200, Colors.grey.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: gotoEditNote,
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          child: SvgPicture.asset(
            'assets/icons/add-note_icon.svg',
            width: 28,
            height: 28,
            colorFilter: ColorFilter.mode(
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          margin: EdgeInsets.only(top: 2),
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: ListView(
            physics: BouncingScrollPhysics(),
            children: <Widget>[
              buildButtonRow(),
              buildImportantIndicatorText(),
              SizedBox(height: 16),
              if (buildNoteComponentsList().isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/no_notes.png',
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'No notes yet!',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...buildNoteComponentsList(),
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildButtonRow() {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: () {
              setState(() {
                isFlagOn = !isFlagOn;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 50,
              width: 50,
              curve: Curves.slowMiddle,
              decoration: BoxDecoration(
                color: isFlagOn ? Colors.blue : Colors.transparent,
                border: Border.all(
                  width: isFlagOn ? 2 : 1,
                  color: isFlagOn ? Colors.blue.shade700 : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isFlagOn ? Icons.flag : Icons.outlined_flag,
                color: isFlagOn ? Colors.white : Colors.grey.shade300,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      maxLines: 1,
                      onChanged: handleSearch,
                      keyboardType: TextInputType.text,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration.collapsed(
                        hintText: 'Search',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isSearchEmpty ? Icons.search : Icons.cancel,
                      color: Colors.grey.shade300,
                    ),
                    onPressed: cancelSearch,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildImportantIndicatorText() {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 200),
      firstChild: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'Only showing notes marked important'.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.blue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      secondChild: const SizedBox(height: 2),
      crossFadeState:
          isFlagOn ? CrossFadeState.showFirst : CrossFadeState.showSecond,
    );
  }

  List<Widget> buildNoteComponentsList() {
    notesList.sort((a, b) => b.date.compareTo(a.date));
    return notesList
        .where((note) {
          final matchesSearch =
              searchController.text.isEmpty ||
              note.title.toLowerCase().contains(
                searchController.text.toLowerCase(),
              ) ||
              note.content.toLowerCase().contains(
                searchController.text.toLowerCase(),
              );
          final matchesFlag = !isFlagOn || note.isImportant;
          return matchesSearch && matchesFlag;
        })
        .map(
          (note) =>
              NoteCardComponent(noteData: note, onTapAction: openNoteToRead),
        )
        .toList();
  }

  void handleSearch(String value) {
    setState(() {
      isSearchEmpty = value.isEmpty;
    });
  }

  void gotoEditNote() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => EditNotePage(triggerRefetch: refetchNotesFromDB),
      ),
    );
  }

  void refetchNotesFromDB() async {
    await setNotesFromDB();
  }

  void openNoteToRead(NotesModel noteData) async {
    Navigator.push(
      context,
      FadeRoute(
        page: ViewNotePage(
          triggerRefetch: refetchNotesFromDB,
          currentNote: noteData,
        ),
      ),
    );
  }

  void cancelSearch() {
    FocusScope.of(context).unfocus();
    setState(() {
      searchController.clear();
      isSearchEmpty = true;
    });
  }
}
