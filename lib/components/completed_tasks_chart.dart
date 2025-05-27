import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/task_model.dart';

class CompletedTasksChart extends StatelessWidget {
  final List<TaskModel> tasks;

  const CompletedTasksChart({super.key, required this.tasks});

  Map<String, int> getCompletionCountsPerDay() {
    final Map<String, int> counts = {};
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(date);
      counts[key] = 0;
    }

    for (var task in tasks) {
      final dateStr = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.tryParse(task.dateCreated)!);
      if (counts.containsKey(dateStr)) {
        counts[dateStr] = counts[dateStr]! + 1;
      }
    }

    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = getCompletionCountsPerDay();
    final maxCount =
        data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b);

    const double totalChartHeight = 96;
    const double barMaxHeight = 60;
    const double textHeight = 14;
    const double spacer = 4;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          height: totalChartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children:
                data.entries.map((entry) {
                  final day = DateFormat('E').format(DateTime.parse(entry.key));
                  final count = entry.value;
                  // Responsive bar
                  final barHeight =
                      maxCount == 0 ? 0.0 : (count / maxCount) * barMaxHeight;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: textHeight,
                          child: FittedBox(
                            child: Text(
                              count.toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: spacer),
                        Container(
                          width: 16,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : Colors.black,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: spacer),
                        SizedBox(
                          height: textHeight,
                          child: FittedBox(
                            child: Text(
                              day,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }
}
