import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../data/task_model.dart';
import '../screens/edit_task.dart';
import '../services/task_database.dart';

class TaskViewPage extends StatefulWidget {
  final TaskModel task;
  final VoidCallback? onUpdate;

  const TaskViewPage({Key? key, required this.task, this.onUpdate})
      : super(key: key);

  @override
  State<TaskViewPage> createState() => _TaskViewPageState();
}

class _TaskViewPageState extends State<TaskViewPage> {
  late TaskModel currentTask;
  bool headerShouldShow = false;
  bool updating = false;

  @override
  void initState() {
    super.initState();
    currentTask = widget.task;
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() => headerShouldShow = true);
    });
  }

  Future<void> refreshTask() async {
    final fresh = await TaskDatabaseService.db.getTaskById(currentTask.id!);
    if (fresh != null) setState(() => currentTask = fresh);
    widget.onUpdate?.call();
  }

  String get dateString {
    // Yeni modele göre full tarih/saat info
    final t = currentTask;
    if (t.isRange) {
      final start = _tryParseDate(t.startDate);
      final end = _tryParseDate(t.endDate);
      final sTime = t.startTime;
      final eTime = t.endTime;
      if (start != null && end != null && sTime != null && eTime != null) {
        return "${_dayMonthYear(start)} $sTime — ${_dayMonthYear(end)} $eTime";
      } else if (start != null && end != null) {
        return "${_dayMonthYear(start)} — ${_dayMonthYear(end)}";
      }
      return "Date Range";
    } else {
      final due = _tryParseDate(t.dueDate);
      final dTime = t.dueTime;
      if (due != null && dTime != null) {
        return "${_dayMonthYear(due)} $dTime";
      } else if (due != null) {
        return _dayMonthYear(due);
      }
      return "No Date";
    }
  }

  DateTime? _tryParseDate(String? d) {
    if (d == null) return null;
    try {
      return DateTime.parse(d);
    } catch (_) {
      return null;
    }
  }

  String _dayMonthYear(DateTime dt) =>
      "${dt.day.toString().padLeft(2, '0')} ${_monthName(dt.month)} ${dt.year}";

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  Color get priorityColor {
    switch (currentTask.priority) {
      case "High":
        return Colors.redAccent;
      case "Medium":
        return Colors.orangeAccent;
      case "Low":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> markAsDone(bool isDone) async {
    setState(() => updating = true);

    if (!isDone) {
      final now = DateTime.now();

      DateTime? date;
      TimeOfDay? time;

      if (currentTask.isRange) {
        date = currentTask.endDate != null
            ? DateTime.tryParse(currentTask.endDate!)
            : null;
        time =
        currentTask.endTime != null ? _parseTime(currentTask.endTime!) : null;
      } else {
        date = currentTask.dueDate != null
            ? DateTime.tryParse(currentTask.dueDate!)
            : null;
        time =
        currentTask.dueTime != null ? _parseTime(currentTask.dueTime!) : null;
      }

      final hasPassed = date != null && time != null
          ? DateTime(date.year, date.month, date.day, time.hour, time.minute)
          .isBefore(now)
          : false;

      if (hasPassed) {
        final action = await showDialog<String>(
          context: context,
          builder: (ctx) =>
              AlertDialog(
                title: const Text("Time Passed"),
                content: const Text(
                    "This task's time has already passed. What do you want to do?"),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, "cancel"),
                      child: const Text("Cancel")),
                  TextButton(onPressed: () => Navigator.pop(ctx, "edit"),
                      child: const Text("Edit")),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, "delete"),
                      child: const Text(
                          "Delete", style: TextStyle(color: Colors.red))),
                ],
              ),
        );

        if (action == "edit") {
          handleEdit();
          setState(() => updating = false);
          return;
        } else if (action == "delete") {
          await TaskDatabaseService.db.deleteTask(currentTask.id!);
          widget.onUpdate?.call();
          Navigator.of(context).pop(true);
          return;
        } else {
          setState(() => updating = false);
          return;
        }
      }
    }

    await TaskDatabaseService.db.updateTask(
      currentTask.copyWith(isDone: isDone),
    );

    await refreshTask();
    setState(() => updating = false);
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(":");
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }


  void handleEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditTaskPage(
              existingTask: currentTask,
              triggerRefetch: refreshTask,
            ),
      ),
    );
    if (result == true) await refreshTask();
  }

  void handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            title: const Text("Are you sure you want to delete this task?"),
            content: const Text("This task will be permanently deleted."),
            actions: [
              TextButton(
                child: const Text("CANCEL"),
                onPressed: () => Navigator.pop(ctx, false),
              ),
              TextButton(
                child: const Text(
                  "DELETE",
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await TaskDatabaseService.db.deleteTask(currentTask.id!);
      widget.onUpdate?.call();
      Navigator.of(context).pop(true);
    }
  }

  void handleShare() {
    final t = currentTask;
    final msg = '''
Task: ${t.title}
Date(s): $dateString
Priority: ${t.priority ?? "Medium"}

${t.description}
''';
    Share.share(msg);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Stack(
        children: [
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              const SizedBox(height: 80),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: AnimatedOpacity(
                  opacity: headerShouldShow ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                  child: Text(
                    currentTask.title,
                    style: const TextStyle(
                      fontFamily: 'ZillaSlab',
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                    ),
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: headerShouldShow ? 1 : 0,
                child: Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    dateString,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
                child: Row(
                  children: [
                    _badge(
                      icon: Icons.flag,
                      text: (currentTask.priority ?? "Medium"),
                      color: priorityColor,
                    ),
                    const SizedBox(width: 12),
                    _toggleBadge(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Description",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentTask.description.isNotEmpty
                            ? currentTask.description
                            : "No description.",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildAppBar(),
        ],
      ),
    );
  }

  // Modern badge
  Widget _badge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Toggleable Ongoing/Completed badge as a button
  Widget _toggleBadge() {
    final isDone = currentTask.isDone;
    final color = isDone ? Colors.green : Colors.orange;
    final text = isDone ? "Completed" : "Ongoing";
    final icon = isDone ? Icons.check_circle : Icons.timelapse;

    return GestureDetector(
      onTap: updating ? null : () async {
        await markAsDone(!isDone);
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.55), width: 1.3),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.11),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            updating
                ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Icon(icon, color: color, size: 17),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // AppBar'ın fonksiyonu: Her zaman currentTask.isDone durumuna bak
  Widget _buildAppBar() {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 80,
          color: isDark
              ? Colors.black.withOpacity(0.7)
              : Colors.white.withOpacity(0.7),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context, true),
                ),
                const Spacer(),
                // SADECE ongoing ise göster:
                if (!currentTask.isDone)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: "Edit",
                    onPressed: handleEdit,
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: "Delete",
                  onPressed: handleDelete,
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: "Share",
                  onPressed: handleShare,
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
