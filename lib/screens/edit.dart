import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notes_demo_project/data/models.dart';
import 'package:notes_demo_project/screens/ai_note_page.dart';
import 'package:notes_demo_project/services/chatgpt_service.dart';
import 'package:notes_demo_project/services/database.dart';
import 'package:notes_demo_project/services/notification_service.dart';
import 'package:notes_demo_project/services/sharedPref.dart';
import 'package:notes_demo_project/screens/home.dart';

class EditNotePage extends StatefulWidget {
  final Function() triggerRefetch;
  final NotesModel? existingNote;

  const EditNotePage({
    Key? key,
    required this.triggerRefetch,
    this.existingNote,
  }) : super(key: key);

  @override
  _EditNotePageState createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  bool isNoteNew = true;
  File? selectedImage;
  bool reminderEnabled = false;
  DateTime? reminderDateTime;
  bool isCorrecting = false;

  late NotesModel currentNote;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final FocusNode titleFocus = FocusNode();
  final FocusNode contentFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    currentNote =
        widget.existingNote ??
            NotesModel(
              content: '',
              title: '',
              date: DateTime.now(),
              isImportant: false,
            );
    isNoteNew = widget.existingNote == null;

    titleController.text = currentNote.title;
    contentController.text = currentNote.content;

    if (currentNote.imagePath != null) {
      selectedImage = File(currentNote.imagePath!);
    }
    if (currentNote.reminderDateTime != null) {
      reminderEnabled = true;
      reminderDateTime = currentNote.reminderDateTime;
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => selectedImage = File(pickedFile.path));
    }
  }

  Future<void> pickReminderDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: reminderDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(reminderDateTime ?? DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          reminderDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void handleSave() async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Title and content cannot be empty."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Always get USER_ID via sharedPref.dart
    final userId = await getCurrentUserId();

    currentNote
      ..title = title
      ..content = content
      ..imagePath = selectedImage?.path
      ..reminderDateTime = reminderEnabled ? reminderDateTime : null
      ..userId = userId;

    if (isNoteNew || currentNote.id == null) {
      final latestNote = await NotesDatabaseService.db.addNoteInDB(currentNote);
      currentNote = latestNote;
    } else {
      await NotesDatabaseService.db.updateNoteInDB(currentNote);
    }

    if (reminderEnabled && reminderDateTime != null) {
      await NotificationService().scheduleNotification(
        id: currentNote.id ?? DateTime
            .now()
            .millisecondsSinceEpoch,
        title: title,
        body: 'Reminder time has come!',
        scheduledDate: reminderDateTime!,
      );
    }

    widget.triggerRefetch();

    Navigator.of(context).popUntil((route) => route.isFirst);
    await Future.delayed(Duration(milliseconds: 150));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            MyHomePage(
              title: 'Notes',
              changeTheme: (brightness) {},
            ),
      ),
    );
  }


  void handleBack() {
    Navigator.of(context).pop();
  }

  Future<void> correctWithAI() async {
    final content = contentController.text.trim();
    if (content.isEmpty) return;

    setState(() => isCorrecting = true);
    try {
      final prompt =
          "Please correct the spelling and grammar mistakes in the following text: $content";
      final corrected = await ChatGptService().getChatGptResponse(prompt);
      setState(() => contentController.text = corrected);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Correction error: $e")));
    } finally {
      setState(() => isCorrecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    return Stack(
      children: [
        Scaffold(
          floatingActionButton: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade200, Colors.grey.shade300],
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
              onPressed: () async {
                final result = await Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                        AiNotePage(triggerRefetch: widget.triggerRefetch),
                  ),
                );

                if (result is Map<String, String>) {
                  setState(() {
                    isNoteNew = true;
                    currentNote = NotesModel(
                      title: result['title'] ?? '',
                      content: result['content'] ?? '',
                      date: DateTime.now(),
                      isImportant: false,
                    );
                    titleController.text = currentNote.title;
                    contentController.text = currentNote.content;
                    selectedImage = null;
                    reminderEnabled = false;
                    reminderDateTime = null;
                  });
                }
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              child: SvgPicture.asset(
                'assets/icons/ai_icon.svg',
                width: 28,
                height: 28,
                colorFilter: ColorFilter.mode(
                  isDark ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          body: ListView(
            padding: EdgeInsets.only(top: 80),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  focusNode: titleFocus,
                  autofocus: true,
                  controller: titleController,
                  maxLines: null,
                  textInputAction: TextInputAction.next,
                  onSubmitted:
                      (_) => FocusScope.of(context).requestFocus(contentFocus),
                  style: TextStyle(
                    fontFamily: 'ZillaSlab',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Enter a title',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 32,
                      fontFamily: 'ZillaSlab',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  focusNode: contentFocus,
                  controller: contentController,
                  maxLines: null,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Start typing...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.10 : 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF26A69A).withOpacity(0.20),
                      width: 1.1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: isCorrecting ? null : correctWithAI,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            isCorrecting
                                ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: const Color(0xFF26A69A),
                              ),
                            )
                                : SvgPicture.asset(
                              'assets/icons/ai_icon.svg',
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                const Color(0xFF26A69A),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isCorrecting
                                  ? "Correcting..."
                                  : "Fix Grammar (AI)",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (selectedImage != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(selectedImage!),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => selectedImage = null),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SwitchListTile(
                title: Text("Add reminder"),
                value: reminderEnabled,
                onChanged: (bool value) {
                  setState(() {
                    reminderEnabled = value;
                    if (!value) reminderDateTime = null;
                  });
                },
              ),
              if (reminderEnabled)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: pickReminderDateTime,
                    icon: Icon(Icons.access_time),
                    label: Text(
                      reminderDateTime != null
                          ? "${reminderDateTime!.day.toString().padLeft(
                          2, '0')}/${reminderDateTime!.month.toString().padLeft(
                          2, '0')} ${reminderDateTime!.hour.toString().padLeft(
                          2, '0')}:${reminderDateTime!.minute.toString()
                          .padLeft(2, '0')}"
                          : "Select Date & Time",
                    ),
                  ),
                ),
              SizedBox(height: 100),
            ],
          ),
        ),
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 80,
              color: Theme
                  .of(context)
                  .canvasColor
                  .withOpacity(0.3),
              child: SafeArea(
                child: Row(
                  children: <Widget>[
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: handleBack,
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.image_outlined),
                      onPressed: pickImage,
                    ),
                    IconButton(
                      icon: Icon(
                        currentNote.isImportant
                            ? Icons.flag
                            : Icons.outlined_flag,
                      ),
                      onPressed: () {
                        setState(() {
                          currentNote.isImportant = !currentNote.isImportant;
                        });
                      },
                    ),
                    IconButton(icon: Icon(Icons.check), onPressed: handleSave),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isCorrecting)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/ai_icon.svg',
                width: 72,
                height: 72,
                colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
          ),
      ],
    );
  }
}
