import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../components/task_card_component.dart';
import '../data/task_model.dart';
import '../screens/completed_tasks_page.dart';
import '../screens/edit_task.dart';
import '../screens/settings.dart';
import '../screens/task_view_page.dart';
import '../services/sharedPref.dart';
import '../services/task_database.dart';

class TasksPage extends StatefulWidget {
  final Function(Brightness brightness) changeTheme;

  const TasksPage({Key? key, required this.changeTheme}) : super(key: key);

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<TaskModel> allTasks = [];
  String? username;
  int? userId;
  DateTime selectedDate = DateTime.now();
  Set<int> animatingTasks = {};

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final name = await getUsername();
    final id = await getCurrentUserId();
    final tasks = await TaskDatabaseService.db.getTasks(userId: id);
    setState(() {
      username = name ?? 'User';
      userId = id;
      allTasks = tasks;
    });
  }

  Future<void> markTaskAsCompleted(TaskModel task) async {
    if (animatingTasks.contains(task.id)) return;

    setState(() {
      animatingTasks.add(task.id!);
    });

    final all = await TaskDatabaseService.db.getTasks();
    final original = all.firstWhere((t) => t.id == task.id);

    final updated = original.copyWith(isDone: true);

    await TaskDatabaseService.db.updateTask(updated);
    await Future.delayed(const Duration(milliseconds: 800));

    await loadData();
    setState(() {
      animatingTasks.remove(task.id);
    });
  }

  List<TaskModel> get filteredTasks {
    return allTasks.where((task) {
      final selected = selectedDate;
      if (task.isDone) return false;

      DateTime? start;
      DateTime? end;

      if (task.isRange) {
        start =
            task.startDate != null ? DateTime.tryParse(task.startDate!) : null;
        end = task.endDate != null ? DateTime.tryParse(task.endDate!) : null;
      } else {
        start = task.dueDate != null ? DateTime.tryParse(task.dueDate!) : null;
        end = start;
      }

      if (start == null) return false;

      return selected.isAtSameMomentAs(start) ||
          (end != null &&
              selected.isAfter(start.subtract(const Duration(days: 1))) &&
              selected.isBefore(end.add(const Duration(days: 1))));
    }).toList();
  }

  Future<void> _goToCompletedPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CompletedTasksPage()),
    );
    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist),
            tooltip: "Completed Tasks",
            onPressed: _goToCompletedPage,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsPage(changeTheme: widget.changeTheme),
                ),
              );
            },
          ),
        ],
        title: Text(
          'Tasks',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
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
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditTaskPage(triggerRefetch: loadData),
              ),
            );
            selectedDate = DateTime.now();
            await loadData();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          child: SvgPicture.asset(
            'assets/icons/task_add_icon.svg',
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

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              Row(
                children: [
                  const Icon(Icons.person, size: 32),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username ?? '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Welcome back!',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              buildDateSelector(),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  DateFormat('EEEE, dd MMMM yyyy').format(selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Progress',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(thickness: 1, height: 16),
              buildProgressBar(),
              const SizedBox(height: 20),
              const Text(
                'Tasks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(thickness: 1, height: 16),
              if (filteredTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'No tasks for this day.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Builder(
                          builder: (context) {
                            final tomorrow = selectedDate.add(
                              const Duration(days: 1),
                            );
                            final hasTasksTomorrow = allTasks.any((t) {
                              final start = DateTime.tryParse(t.dateCreated);
                              final end =
                                  t.dueDate != null
                                      ? DateTime.tryParse(t.dueDate!)
                                      : null;
                              if (start == null) return false;
                              return end != null
                                  ? tomorrow.isAfter(
                                        start.subtract(const Duration(days: 1)),
                                      ) &&
                                      tomorrow.isBefore(
                                        end.add(const Duration(days: 1)),
                                      )
                                  : DateFormat('yyyy-MM-dd').format(tomorrow) ==
                                      DateFormat('yyyy-MM-dd').format(start);
                            });
                            if (hasTasksTomorrow) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  "But you've got stuff coming up tomorrow!",
                                  style: TextStyle(
                                    color: Color(0xFF26A69A),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                            return SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => TaskViewPage(
                                  task: task,
                                  onUpdate: loadData,
                                ),
                          ),
                        );
                        if (result == true || result == "edit") {
                          await loadData();
                        }
                      },
                      child: TaskCardComponent(
                        key: ValueKey(task.id),
                        task: task,
                        onToggleComplete: () => markTaskAsCompleted(task),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildProgressBar() {
    final selected = selectedDate;
    final done =
        allTasks.where((task) {
          final start = DateTime.tryParse(task.dateCreated);
          final end =
              task.dueDate != null ? DateTime.tryParse(task.dueDate!) : null;
          if (start == null) return false;

          final isInRange =
              end != null
                  ? selected.isAfter(start.subtract(const Duration(days: 1))) &&
                      selected.isBefore(end.add(const Duration(days: 1)))
                  : DateFormat('yyyy-MM-dd').format(selected) ==
                      DateFormat('yyyy-MM-dd').format(start);

          return isInRange && task.isDone;
        }).length;

    final total =
        allTasks.where((task) {
          final start = DateTime.tryParse(task.dateCreated);
          final end =
              task.dueDate != null ? DateTime.tryParse(task.dueDate!) : null;
          if (start == null) return false;

          final isInRange =
              end != null
                  ? selected.isAfter(start.subtract(const Duration(days: 1))) &&
                      selected.isBefore(end.add(const Duration(days: 1)))
                  : DateFormat('yyyy-MM-dd').format(selected) ==
                      DateFormat('yyyy-MM-dd').format(start);

          return isInRange;
        }).length;

    final percent = total == 0 ? 0.0 : done / total;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color progressColor = const Color(0xFF26A69A);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOutCubic,
                    height: 10,
                    width: constraints.maxWidth * percent,
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            '$done / $total completed',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDateSelector() {
    final now = DateTime.now();
    final Color selectedColor = const Color(0xFF26A69A); // Teal 400
    final Color selectedTextColor = Colors.white;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 8,
        itemBuilder: (context, index) {
          if (index == 7) {
            return GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => selectedDate = picked);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_today, size: 20),
              ),
            );
          }

          final day = now.add(Duration(days: index));
          final isSelected =
              DateFormat('yyyy-MM-dd').format(day) ==
              DateFormat('yyyy-MM-dd').format(selectedDate);
          final isToday =
              DateFormat('yyyy-MM-dd').format(day) ==
              DateFormat('yyyy-MM-dd').format(DateTime.now());

          return GestureDetector(
            onTap: () => setState(() => selectedDate = day),
            child: Container(
              width: 48,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected
                          ? selectedColor
                          : (isToday
                              ? Colors.orangeAccent
                              : Colors.grey.shade400),
                  width: isToday ? 2.2 : 2,
                ),
                boxShadow: [
                  if (isToday && !isSelected)
                    BoxShadow(
                      color: Colors.orangeAccent.withOpacity(0.35),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('d').format(day),
                    style: TextStyle(
                      color:
                          isSelected
                              ? selectedTextColor
                              : (isDark ? Colors.white : Colors.black),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('E').format(day).substring(0, 2),
                    style: TextStyle(
                      color:
                          isSelected
                              ? selectedTextColor.withOpacity(0.8)
                              : (isDark ? Colors.grey.shade400 : Colors.grey),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
