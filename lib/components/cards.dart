import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models.dart';

List<Color> colorList = [
  Colors.blue,
  Colors.green,
  Colors.indigo,
  Colors.red,
  Colors.cyan,
  Colors.teal,
  Colors.amber.shade900,
  Colors.deepOrange
];
class NoteCardComponent extends StatelessWidget {
  const NoteCardComponent({
    required this.noteData,
    required this.onTapAction,
    super.key,
  });

  final NotesModel noteData;
  final Function(NotesModel noteData) onTapAction;

  @override
  Widget build(BuildContext context) {
    String neatDate = DateFormat.yMd().add_jm().format(noteData.date);
    Color color = colorList[noteData.title.length % colorList.length];

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      constraints: const BoxConstraints(minHeight: 110),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [buildBoxShadow(color, context)],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        color: Theme.of(context).dialogBackgroundColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onTapAction(noteData),
          splashColor: color.withAlpha(20),
          highlightColor: color.withAlpha(10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  noteData.title.trim(),
                  style: TextStyle(
                    fontFamily: 'ZillaSlab',
                    fontSize: 20,
                    fontWeight: noteData.isImportant
                        ? FontWeight.w800
                        : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  noteData.content.trim().split('\n').first,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Icon(Icons.flag,
                        size: 16,
                        color: noteData.isImportant
                            ? color
                            : Colors.transparent),
                    const Spacer(),
                    Text(
                      neatDate,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade300,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxShadow buildBoxShadow(Color color, BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxShadow(
      color: noteData.isImportant
          ? (isDark ? Colors.black.withAlpha(100) : color.withAlpha(60))
          : (isDark ? Colors.black.withAlpha(10) : color.withAlpha(25)),
      blurRadius: 8,
      offset: const Offset(0, 8),
    );
  }
}

class AddNoteCardComponent extends StatelessWidget {
  const AddNoteCardComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      constraints: const BoxConstraints(minHeight: 110),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).primaryColor, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.add,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Add new note',
                style: TextStyle(
                    fontFamily: 'ZillaSlab',
                    color: Theme.of(context).primaryColor,
                    fontSize: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
