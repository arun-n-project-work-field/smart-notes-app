import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/task_model.dart';
import '../services/sharedPref.dart';
import '../services/task_database.dart';
import '../utils/ai_priority_helper.dart';

class EditTaskPage extends StatefulWidget {
  final Function triggerRefetch;
  final TaskModel? existingTask;

  const EditTaskPage({
    Key? key,
    required this.triggerRefetch,
    this.existingTask,
  }) : super(key: key);

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();

  DateTime? _singleDate;
  TimeOfDay? _singleTime;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  String _priority = 'Medium';
  bool _isRange = false;

  String? _aiSuggestedPriority;
  bool _aiSuggestLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.existingTask != null) {
      final task = widget.existingTask!;
      _titleController.text = task.title;
      _descController.text = task.description;
      _isRange = task.isRange;
      if (_isRange) {
        _startDate =
            task.startDate != null ? DateTime.tryParse(task.startDate!) : null;
        _startTime =
            task.startTime != null ? _parseTimeOfDay(task.startTime!) : null;
        _endDate =
            task.endDate != null ? DateTime.tryParse(task.endDate!) : null;
        _endTime = task.endTime != null ? _parseTimeOfDay(task.endTime!) : null;
      } else {
        _singleDate =
            task.dueDate != null ? DateTime.tryParse(task.dueDate!) : null;
        _singleTime =
            task.dueTime != null ? _parseTimeOfDay(task.dueTime!) : null;
      }
      _priority = task.priority ?? 'Medium';
    }
    _titleController.addListener(_onTextChange);
    _descController.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onTextChange() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 750), () {
      _fetchAIPrioritySuggestion();
    });
  }

  Future<void> _fetchAIPrioritySuggestion() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    if (title.isEmpty && desc.isEmpty) {
      setState(() {
        _aiSuggestedPriority = null;
      });
      return;
    }

    setState(() {
      _aiSuggestLoading = true;
      _aiSuggestedPriority = null;
    });

    try {
      final aiPriority = await predictPriorityWithAI(title, desc);
      setState(() {
        _aiSuggestLoading = false;
        _aiSuggestedPriority = aiPriority;
      });
    } catch (e) {
      setState(() {
        _aiSuggestLoading = false;
        _aiSuggestedPriority = null;
      });
    }
  }

  Future<void> _selectDateTime({
    required bool isStart,
    required bool isDate,
  }) async {
    if (!_isRange) {
      // Single mode
      if (isDate) {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: _singleDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          setState(() => _singleDate = pickedDate);
        }
      } else {
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: _singleTime ?? const TimeOfDay(hour: 9, minute: 0),
        );
        if (pickedTime != null) {
          setState(() => _singleTime = pickedTime);
        }
      }
    } else {
      // Range mode
      if (isStart) {
        if (isDate) {
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: _startDate ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (pickedDate != null) {
            setState(() => _startDate = pickedDate);
          }
        } else {
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
          );
          if (pickedTime != null) {
            setState(() => _startTime = pickedTime);
          }
        }
      } else {
        if (isDate) {
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: _endDate ?? _startDate ?? DateTime.now(),
            firstDate: _startDate ?? DateTime.now(),
            lastDate: DateTime(2100),
          );
          if (pickedDate != null) {
            setState(() => _endDate = pickedDate);
          }
        } else {
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: _endTime ?? const TimeOfDay(hour: 18, minute: 0),
          );
          if (pickedTime != null) {
            setState(() => _endTime = pickedTime);
          }
        }
      }
    }
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final userId = await getCurrentUserId();

    if (title.isEmpty) return;

    TaskModel task;

    if (!_isRange) {
      if (_singleDate == null || _singleTime == null) return;

      final selectedDateTime = DateTime(
        _singleDate!.year,
        _singleDate!.month,
        _singleDate!.day,
        _singleTime!.hour,
        _singleTime!.minute,
      );

      if (selectedDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You can't set a past time!")),
        );
        return;
      }

      task = TaskModel(
        id: widget.existingTask?.id,
        title: title,
        description: desc,
        isDone: widget.existingTask?.isDone ?? false,
        dateCreated: _singleDate!.toIso8601String(),
        dueDate: DateFormat('yyyy-MM-dd').format(_singleDate!),
        dueTime: _singleTime!.format(context),
        priority: _priority,
        userId: userId,
        isRange: false,
      );
    } else {
      if (_startDate == null ||
          _endDate == null ||
          _startTime == null ||
          _endTime == null)
        return;

      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      if (startDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Start time can't be in the past!")),
        );
        return;
      }

      task = TaskModel(
        id: widget.existingTask?.id,
        title: title,
        description: desc,
        isDone: widget.existingTask?.isDone ?? false,
        dateCreated: _startDate!.toIso8601String(),
        startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
        startTime: _startTime!.format(context),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
        endTime: _endTime!.format(context),
        priority: _priority,
        userId: userId,
        isRange: true,
      );
    }

    if (widget.existingTask != null) {
      await TaskDatabaseService.db.updateTask(task);
    } else {
      await TaskDatabaseService.db.insertTask(task);
    }

    widget.triggerRefetch();
    Navigator.of(context).pop();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not selected';
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Not selected';
    return time.format(context);
  }

  TimeOfDay? _parseTimeOfDay(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Widget buildDateTimeCard({
    required String label,
    DateTime? date,
    TimeOfDay? time,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              GestureDetector(
                onTap: onDateTap,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatDate(date),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onTimeTap,
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatTime(time),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aiSuggestionBadge() {
    if (_aiSuggestLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Row(
          children: [
            SizedBox(
              width: 19,
              height: 19,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text("Analyzing with AI...", style: TextStyle(fontSize: 14)),
          ],
        ),
      );
    }
    if (_aiSuggestedPriority == null) return SizedBox.shrink();
    Color color =
        _aiSuggestedPriority == 'High'
            ? Colors.redAccent
            : _aiSuggestedPriority == 'Medium'
            ? Colors.orangeAccent
            : Colors.green;

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              "AI Suggested: $_aiSuggestedPriority Priority",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 14),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: color,
                textStyle: TextStyle(fontWeight: FontWeight.bold),
                minimumSize: Size(8, 32),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              ),
              child: Text("Apply"),
              onPressed: () {
                setState(() {
                  _priority = _aiSuggestedPriority!;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Priority set as $_aiSuggestedPriority by AI suggestion!",
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // APP BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              height: 60,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _handleSave,
                  ),
                ],
              ),
            ),
            // CONTENT
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  TextField(
                    controller: _titleController,
                    focusNode: _titleFocus,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    onSubmitted:
                        (_) => FocusScope.of(context).requestFocus(_descFocus),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration.collapsed(
                      hintText: 'Enter task title',
                      hintStyle: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _descController,
                    focusNode: _descFocus,
                    maxLines: null,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration.collapsed(
                      hintText: 'Add description...',
                      hintStyle: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  DropdownButtonFormField<String>(
                    value: _isRange ? 'Range' : 'Single',
                    items:
                        ['Single', 'Range']
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type == 'Single'
                                      ? 'Single Date'
                                      : 'Date Range',
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      setState(() {
                        _isRange = val == 'Range';
                        // Reset dates/times on switch
                        _singleDate = null;
                        _singleTime = null;
                        _startDate = null;
                        _startTime = null;
                        _endDate = null;
                        _endTime = null;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Task Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_isRange)
                    buildDateTimeCard(
                      label: "Due Date & Time",
                      date: _singleDate,
                      time: _singleTime,
                      onDateTap:
                          () => _selectDateTime(isStart: true, isDate: true),
                      onTimeTap:
                          () => _selectDateTime(isStart: true, isDate: false),
                    ),
                  if (_isRange)
                    Column(
                      children: [
                        buildDateTimeCard(
                          label: "Start Date & Time",
                          date: _startDate,
                          time: _startTime,
                          onDateTap:
                              () =>
                                  _selectDateTime(isStart: true, isDate: true),
                          onTimeTap:
                              () =>
                                  _selectDateTime(isStart: true, isDate: false),
                        ),
                        const SizedBox(height: 12),
                        buildDateTimeCard(
                          label: "End Date & Time",
                          date: _endDate,
                          time: _endTime,
                          onDateTap:
                              () =>
                                  _selectDateTime(isStart: false, isDate: true),
                          onTimeTap:
                              () => _selectDateTime(
                                isStart: false,
                                isDate: false,
                              ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _priority,
                          items:
                              ['High', 'Medium', 'Low']
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) =>
                                  setState(() => _priority = val ?? 'Medium'),
                          decoration: InputDecoration(
                            labelText: 'Priority',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _aiSuggestionBadge(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
