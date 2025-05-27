import '../services/chatgpt_service.dart';

Future<String> predictPriorityWithAI(String title, String description) async {
  final prompt = '''
Given the following task, respond ONLY with one word: High, Medium, or Low.
What is the priority level of this task?

Title: $title
Description: $description

Your answer must be just one word: High, Medium, or Low.
''';

  final service = ChatGptService();
  final response = await service.getChatGptResponse(prompt);

  final res = response.toLowerCase();
  if (res.contains("high")) return "High";
  if (res.contains("medium")) return "Medium";
  if (res.contains("low")) return "Low";
  return "Medium";
}
