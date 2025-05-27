import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/dashboard_card.dart';
import 'home.dart';
import 'settings.dart';
import 'tasks_page.dart';

class DashboardPage extends StatefulWidget {
  final Function(Brightness brightness) changeTheme;

  const DashboardPage({super.key, required this.changeTheme});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String username = 'User';

  @override
  void initState() {
    super.initState();
    loadUsername();
  }

  void loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final storedName = prefs.getString('username');
    setState(() {
      username = storedName ?? 'User';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final mutedColor = isDark ? Colors.grey[400] : Colors.grey[700];

    return Scaffold(
      backgroundColor: Theme
          .of(context)
          .scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme
            .of(context)
            .scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Dashboard',
          style: Theme
              .of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                    isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    child: Icon(
                      Icons.person,
                      color: isDark ? Colors.white : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome,',
                        style: TextStyle(
                          fontSize: 16,
                          color: mutedColor,
                        ),
                      ),
                      Text(
                        username,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Notes Card
              DashboardCard(
                title: 'Notes',
                description: 'View and manage your personal notes',
                svgAsset: 'assets/icons/note_icon.svg',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MyHomePage(
                            title: 'Notes',
                            changeTheme: widget.changeTheme,
                          ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Tasks Card
              DashboardCard(
                title: 'Tasks',
                description: 'Track your tasks and stay organized',
                svgAsset: 'assets/icons/task_icon.svg',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TasksPage(changeTheme: widget.changeTheme),
                    ),
                  );
                },
              ),

              const SizedBox(height: 64),

              // Lottie Animation
              Center(
                child: SizedBox(
                  height: 90,
                  child: Lottie.asset('assets/animations/animation2.json'),
                ),
              ),

              const SizedBox(height: 24),

              const Center(child: _MotivationText()),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _MotivationText extends StatelessWidget {
  const _MotivationText({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    const quote = 'Stay focused. Get organized.';

    return Column(
      children: [
        Text(
          quote,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: 0.3,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            final textPainter = TextPainter(
              text: const TextSpan(
                text: quote,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 0.3,
                ),
              ),
              maxLines: 1,
              textDirection: TextDirection.ltr,
            )
              ..layout();

            return Container(
              width: textPainter.width + 6,
              height: 2,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        ),
      ],
    );
  }
}
