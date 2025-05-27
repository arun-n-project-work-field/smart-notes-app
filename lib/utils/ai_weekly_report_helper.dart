// lib/utils/ai_weekly_report_helper.dart

import '../data/task_model.dart';

String buildWeeklyReportPrompt(List<TaskModel> tasks) {
  StringBuffer buffer = StringBuffer();
  buffer.writeln("You are a productivity assistant.");
  buffer.writeln(
    "I will send you a list of completed tasks for the last 7 days.",
  );
  buffer.writeln("Summarize the user's week as bullet points.");
  buffer.writeln("Give advice for improvement if possible. Be concise.");

  for (var t in tasks) {
    final date = t.dateCreated.substring(0, 10);
    buffer.writeln("- [${date}] ${t.title} (${t.priority ?? 'Medium'})");
  }
  return buffer.toString();
}
