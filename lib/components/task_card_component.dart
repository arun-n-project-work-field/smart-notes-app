import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/task_model.dart';

class TaskCardComponent extends StatefulWidget {
  final TaskModel task;
  final VoidCallback? onToggleComplete;

  const TaskCardComponent({Key? key, required this.task, this.onToggleComplete})
    : super(key: key);

  @override
  State<TaskCardComponent> createState() => _TaskCardComponentState();
}

class _TaskCardComponentState extends State<TaskCardComponent>
    with TickerProviderStateMixin {
  bool _isVisible = true;
  bool _justTapped = false;
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _scale = Tween<double>(
      begin: 1,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerComplete() async {
    if (_justTapped) return;
    setState(() => _justTapped = true);
    await Future.delayed(const Duration(milliseconds: 500));
    await _controller.forward();
    setState(() => _isVisible = false);
    await Future.delayed(const Duration(milliseconds: 150));
    widget.onToggleComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = widget.task;

    String dateInfo = '';
    if (t.isRange) {
      if (t.startDate != null &&
          t.startTime != null &&
          t.endDate != null &&
          t.endTime != null) {
        dateInfo =
            '${_formatDate(t.startDate!)} ${_formatTime(t.startTime!)} - ${_formatDate(t.endDate!)} ${_formatTime(t.endTime!)}';
      } else if (t.startDate != null && t.endDate != null) {
        dateInfo = '${_formatDate(t.startDate!)} - ${_formatDate(t.endDate!)}';
      } else {
        dateInfo = 'Date Range';
      }
    } else {
      if (t.dueDate != null && t.dueTime != null) {
        dateInfo = '${_formatDate(t.dueDate!)} ${_formatTime(t.dueTime!)}';
      } else if (t.dueDate != null) {
        dateInfo = _formatDate(t.dueDate!);
      } else {
        dateInfo = 'No Date';
      }
    }

    Color priorityColor;
    switch ((t.priority ?? "Medium")) {
      case "High":
        priorityColor = Colors.redAccent;
        break;
      case "Medium":
        priorityColor = Colors.orangeAccent;
        break;
      case "Low":
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child:
          _isVisible
              ? FadeTransition(
                opacity: _opacity,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              isDark
                                  ? Colors.black26
                                  : Colors.grey.withOpacity(0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? Colors.white10
                                    : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  isDark
                                      ? Colors.white24
                                      : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // SOL
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // TASK TITLE
                                    Text(
                                      t.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isDark
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    // TASK DESC
                                    if (t.description.trim().isNotEmpty)
                                      Text(
                                        t.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color:
                                              isDark
                                                  ? Colors.white70
                                                  : Colors.black87,
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.event,
                                          size: 15,
                                          color:
                                              isDark
                                                  ? Colors.white60
                                                  : Colors.grey.shade700,
                                        ),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            dateInfo,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color:
                                                  isDark
                                                      ? Colors.white60
                                                      : Colors.grey.shade800,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        _priorityBadge(
                                          t.priority ?? "Medium",
                                          priorityColor,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              _justTapped
                                  ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 28,
                                  )
                                  : GestureDetector(
                                    onTap: _triggerComplete,
                                    child: Icon(
                                      Icons.radio_button_unchecked,
                                      color:
                                          isDark ? Colors.white54 : Colors.grey,
                                      size: 28,
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
              : const SizedBox.shrink(),
    );
  }

  String _formatDate(String d) {
    try {
      final dt = DateTime.parse(d);
      return "${dt.day.toString().padLeft(2, '0')} ${_monthName(dt.month)}";
    } catch (_) {
      return "No Date";
    }
  }

  String _formatTime(String t) {
    return t;
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

  Widget _priorityBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 14, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
