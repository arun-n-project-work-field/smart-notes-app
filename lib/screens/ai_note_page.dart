import 'package:flutter/material.dart';
import 'package:notes_demo_project/data/models.dart';
import 'package:notes_demo_project/screens/edit.dart';
import 'package:notes_demo_project/services/chatgpt_service.dart';

class AiNotePage extends StatefulWidget {
  final Function() triggerRefetch;

  const AiNotePage({super.key, required this.triggerRefetch});

  @override
  State<AiNotePage> createState() => _AiNotePageState();
}

class _AiNotePageState extends State<AiNotePage> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool _loading = false;

  final int maxCharLength = 1200;
  final int minLines = 12;

  final List<String> _suggestedPrompts = [
    "Explain the process of cell division.",
    "Summarize the French Revolution in 5 bullet points.",
    "Write a motivational note about productivity.",
    "Give a quick guide on effective study techniques.",
    "Explain Newton's Laws of Motion in simple terms.",
  ];

  Future<void> _generateNote() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _loading = true;
      _contentController.clear();
    });

    try {
      final extra =
          "\n\nLimit your response to around $maxCharLength characters. Be concise, focused, and do NOT exceed the limit. No unnecessary explanations.";
      final response = await ChatGptService().getChatGptResponse(
        prompt + extra,
      );

      final content =
          response.length > maxCharLength
              ? response.substring(0, maxCharLength)
              : response;

      _contentController.text = content.trim();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _goToEditNotePage() {
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Content cannot be empty.')));
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditNotePage(
              triggerRefetch: widget.triggerRefetch,
              existingNote: NotesModel(
                title: '',
                content: content,
                date: DateTime.now(),
                isImportant: false,
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color backgroundColor = isDark ? Colors.black : Colors.white;
    final Color cardColor = isDark ? Colors.grey[900]! : Colors.grey[100]!;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color hintColor = isDark ? Colors.grey[500]! : Colors.grey[500]!;
    final Color buttonColor = const Color(0xFF26A69A);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Edit Note',
            onPressed: _goToEditNotePage,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  'Generate Note with AI',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Outfit',
                    letterSpacing: 0.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _suggestedPrompts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    return GestureDetector(
                      onTap:
                          _loading
                              ? null
                              : () {
                                _promptController.text = _suggestedPrompts[i];
                              },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: buttonColor.withOpacity(0.32),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _suggestedPrompts[i],
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                isDark ? Colors.white70 : Colors.grey.shade800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // PROMPT CARD
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.tips_and_updates_rounded,
                      color: Color(0xFF26A69A),
                      size: 26,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _promptController,
                        style: TextStyle(color: textColor, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Type your topic, question, or request...',
                          hintStyle: TextStyle(color: hintColor),
                          border: InputBorder.none,
                        ),
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.done,
                        enabled: !_loading,
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: _promptController.text.isEmpty ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: IconButton(
                        icon: Icon(Icons.clear, color: hintColor),
                        tooltip: "Clear",
                        onPressed:
                            _loading
                                ? null
                                : () {
                                  setState(() {
                                    _promptController.clear();
                                    _contentController.clear();
                                  });
                                },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // GENERATE BUTTON
              ElevatedButton.icon(
                icon:
                    _loading
                        ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                        : const Icon(Icons.smart_toy_rounded, size: 22),
                onPressed: _loading ? null : _generateNote,
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    _loading ? "Generating..." : "Generate with AI",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 1.2,
                  textStyle: const TextStyle(fontFamily: 'Outfit'),
                ),
              ),
              const SizedBox(height: 30),
              // CONTENT LABEL
              Text(
                'Generated Content',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Outfit',
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              // GENERATED CONTENT AREA
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 9,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  minLines: minLines,
                  style: TextStyle(color: textColor, fontSize: 15.5),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Your generated note will appear here...',
                    hintStyle: TextStyle(color: hintColor),
                  ),
                  enabled: !_loading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
