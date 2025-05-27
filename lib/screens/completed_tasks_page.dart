import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/task_model.dart';
import '../screens/task_view_page.dart';
import '../services/chatgpt_service.dart';
import '../services/sharedPref.dart';
import '../services/task_database.dart';
import '../utils/ai_weekly_report_helper.dart';

class CompletedTasksPage extends StatefulWidget {
  const CompletedTasksPage({super.key});

  @override
  State<CompletedTasksPage> createState() => _CompletedTasksPageState();
}

class _CompletedTasksPageState extends State<CompletedTasksPage> {
  List<TaskModel> completedTasks = [];
  String selectedPriority = 'All';
  String searchQuery = '';
  bool aiLoading = false;
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    loadCompletedTasks();
  }

  Future<void> loadCompletedTasks() async {
    final userId = await getCurrentUserId();
    final all = await TaskDatabaseService.db.getTasks();
    setState(() {
      currentUserId = userId;
      completedTasks =
          all.where((t) => t.isDone && t.userId == userId).toList();
    });
  }

  List<TaskModel> get last7DaysTasks {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    return completedTasks.where((t) {
      final d = DateTime.tryParse(t.dateCreated);
      if (d == null) return false;
      return d.isAfter(sevenDaysAgo.subtract(const Duration(days: 1)));
    }).toList();
  }

  int get todayCount {
    final today = DateTime.now();
    return completedTasks.where((t) {
      if (t.isRange && t.startDate != null && t.endDate != null) {
        final start = DateTime.parse(t.startDate!);
        final end = DateTime.parse(t.endDate!);
        return today.isAfter(start.subtract(const Duration(days: 1))) &&
            today.isBefore(end.add(const Duration(days: 1)));
      } else if (!t.isRange && t.dueDate != null) {
        return DateFormat('yyyy-MM-dd').format(DateTime.parse(t.dueDate!)) ==
            DateFormat('yyyy-MM-dd').format(today);
      }
      return false;
    }).length;
  }

  String get mostCommonPriority {
    final Map<String, int> counter = {'High': 0, 'Medium': 0, 'Low': 0};
    for (var task in completedTasks) {
      final p = task.priority ?? 'Medium';
      counter[p] = (counter[p] ?? 0) + 1;
    }
    return counter.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  List<TaskModel> get filteredTasks {
    return completedTasks.where((task) {
      final matchPriority =
          selectedPriority == 'All' || task.priority == selectedPriority;
      final matchQuery = task.title.toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
      return matchPriority && matchQuery;
    }).toList();
  }

  Widget buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildWeeklyChart() {
    final now = DateTime.now();
    final daysOfWeek = List.generate(
      7,
      (i) => now.subtract(Duration(days: 6 - i)),
    );
    final dailyCounts = List.generate(7, (i) => 0);

    for (var task in completedTasks) {
      DateTime? date;
      if (task.isRange && task.startDate != null && task.endDate != null) {
        final start = DateTime.parse(task.startDate!);
        final end = DateTime.parse(task.endDate!);
        for (int d = 0; d < 7; d++) {
          final day = daysOfWeek[d];
          if (day.isAfter(start.subtract(const Duration(days: 1))) &&
              day.isBefore(end.add(const Duration(days: 1)))) {
            dailyCounts[d]++;
          }
        }
        continue;
      } else if (task.dueDate != null) {
        date = DateTime.tryParse(task.dueDate!);
      }
      if (date == null) continue;
      for (int i = 0; i < 7; i++) {
        if (DateFormat('yyyy-MM-dd').format(daysOfWeek[i]) ==
            DateFormat('yyyy-MM-dd').format(date)) {
          dailyCounts[i]++;
        }
      }
    }

    final maxCount = dailyCounts.reduce((a, b) => a > b ? a : b);
    final barColor =
        Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: SizedBox(
          width: 350,
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              final barMaxHeight = 76.0;
              final barHeight =
                  maxCount == 0
                      ? 0.0
                      : (dailyCounts[i] / maxCount) * barMaxHeight;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 12,
                    child: FittedBox(
                      child: Text(
                        dailyCounts[i].toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 16,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 12,
                    child: FittedBox(
                      child: Text(
                        DateFormat('E').format(daysOfWeek[i]),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Future<void> _showWeeklyAIReport() async {
    setState(() => aiLoading = true);
    try {
      final prompt = buildWeeklyReportPrompt(last7DaysTasks);
      final aiResult = await ChatGptService().getChatGptResponse(prompt);
      if (!mounted) return;
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('AI Weekly Report'),
              content: SingleChildScrollView(child: Text(aiResult)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('CLOSE'),
                ),
              ],
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to fetch AI report: $e")));
    }
    setState(() => aiLoading = false);
  }

  String _getTaskFullDateLabel(TaskModel task) {
    if (task.isRange) {
      final start =
          task.startDate != null ? DateTime.tryParse(task.startDate!) : null;
      final end =
          task.endDate != null ? DateTime.tryParse(task.endDate!) : null;
      final sTime = task.startTime;
      final eTime = task.endTime;
      if (start != null && end != null && sTime != null && eTime != null) {
        return "${_dayMonth(start)} $sTime — ${_dayMonth(end)} $eTime";
      } else if (start != null && end != null) {
        return "${_dayMonth(start)} — ${_dayMonth(end)}";
      }
    } else {
      final due =
          task.dueDate != null ? DateTime.tryParse(task.dueDate!) : null;
      final dTime = task.dueTime;
      if (due != null && dTime != null) {
        return "${_dayMonth(due)} $dTime";
      } else if (due != null) {
        return _dayMonth(due);
      }
    }
    return 'No Date';
  }

  String _dayMonth(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')} ${_monthName(dt.month)}";
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Completed Tasks",
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.analytics_rounded,
              color: aiLoading ? Colors.grey : Colors.deepPurple,
            ),
            tooltip: "AI Weekly Analysis",
            onPressed: aiLoading ? null : _showWeeklyAIReport,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed:
                completedTasks.isEmpty
                    ? null
                    : () async {
                      for (var task in completedTasks) {
                        await TaskDatabaseService.db.deleteTask(task.id!);
                      }
                      await loadCompletedTasks();
                    },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildStatCard(
                    "Total Completed",
                    completedTasks.length.toString(),
                    Icons.check_circle,
                  ),
                  buildStatCard("Today", todayCount.toString(), Icons.today),
                  buildStatCard("Top Priority", mostCommonPriority, Icons.flag),
                ],
              ),
              const SizedBox(height: 24),
              buildWeeklyChart(),
              const SizedBox(height: 24),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Search Tasks',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => setState(() => searchQuery = val),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:
                    ['All', 'High', 'Medium', 'Low'].map((priority) {
                      final isSelected = selectedPriority == priority;
                      return ChoiceChip(
                        label: Text(
                          priority,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: isSelected,
                        onSelected:
                            (_) => setState(() => selectedPriority = priority),
                        selectedColor: const Color(0xFF26A69A),
                        backgroundColor: Colors.grey.shade200,
                        side: BorderSide(
                          color:
                              isSelected
                                  ? const Color(0xFF26A69A)
                                  : Colors.grey.shade400,
                          width: 1.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                "Completed Tasks",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 16, thickness: 1),
              if (filteredTasks.isEmpty)
                const Center(child: Text("No completed tasks."))
              else
                ...filteredTasks.map((task) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(task.title),
                      subtitle: Text(_getTaskFullDateLabel(task)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.undo),
                            tooltip: "Undo",
                            onPressed: () async {
                              final allTasks =
                                  await TaskDatabaseService.db.getTasks();
                              final original = allTasks.firstWhere(
                                (t) => t.id == task.id,
                              );

                              DateTime? taskDateTime;

                              if (original.isRange &&
                                  original.startDate != null &&
                                  original.startTime != null) {
                                final start = DateTime.tryParse(
                                  original.startDate!,
                                );
                                final startTime = TimeOfDay(
                                  hour: int.parse(
                                    original.startTime!.split(":")[0],
                                  ),
                                  minute: int.parse(
                                    original.startTime!.split(":")[1],
                                  ),
                                );
                                if (start != null) {
                                  taskDateTime = DateTime(
                                    start.year,
                                    start.month,
                                    start.day,
                                    startTime.hour,
                                    startTime.minute,
                                  );
                                }
                              } else if (original.dueDate != null &&
                                  original.dueTime != null) {
                                final due = DateTime.tryParse(
                                  original.dueDate!,
                                );
                                final dueTime = TimeOfDay(
                                  hour: int.parse(
                                    original.dueTime!.split(":")[0],
                                  ),
                                  minute: int.parse(
                                    original.dueTime!.split(":")[1],
                                  ),
                                );
                                if (due != null) {
                                  taskDateTime = DateTime(
                                    due.year,
                                    due.month,
                                    due.day,
                                    dueTime.hour,
                                    dueTime.minute,
                                  );
                                }
                              }

                              if (taskDateTime != null &&
                                  taskDateTime.isBefore(DateTime.now())) {
                                final result = await showDialog(
                                  context: context,
                                  builder:
                                      (_) => AlertDialog(
                                        title: const Text("Past Task"),
                                        content: const Text(
                                          "This task is in the past. Do you want to update it or delete it?",
                                        ),
                                        actions: [
                                          TextButton(
                                            child: const Text("Update"),
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  'update',
                                                ),
                                          ),
                                          TextButton(
                                            child: const Text("Delete"),
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  'delete',
                                                ),
                                          ),
                                        ],
                                      ),
                                );

                                if (result == 'update') {
                                  final updated = original.copyWith(
                                    isDone: false,
                                  );
                                  await TaskDatabaseService.db.updateTask(
                                    updated,
                                  );
                                } else if (result == 'delete') {
                                  await TaskDatabaseService.db.deleteTask(
                                    original.id!,
                                  );
                                }
                              } else {
                                final updated = original.copyWith(
                                  isDone: false,
                                );
                                await TaskDatabaseService.db.updateTask(
                                  updated,
                                );
                              }

                              await loadCompletedTasks();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: "Delete",
                            onPressed: () async {
                              await TaskDatabaseService.db.deleteTask(task.id!);
                              await loadCompletedTasks();
                            },
                          ),
                        ],
                      ),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => TaskViewPage(
                                  task: task,
                                  onUpdate: loadCompletedTasks,
                                ),
                          ),
                        );
                        if (result == true || result == "edit") {
                          await loadCompletedTasks();
                        }
                      },
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
