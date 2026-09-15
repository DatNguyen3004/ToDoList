import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'controllers/task_controller.dart';
import 'views/auth/login_view.dart';
import 'views/home/home_view.dart';
import 'views/tasks/text_task_view.dart';
import 'views/trash/trash_view.dart';

void main() {
  runApp(const TdlApp());
}

class TdlApp extends StatefulWidget {
  const TdlApp({super.key});

  @override
  State<TdlApp> createState() => _TdlAppState();
}

class _TdlAppState extends State<TdlApp> {
  ThemeMode _themeMode = ThemeMode.light;
  final TaskController _taskController = TaskController();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  ThemeData _buildTheme(Brightness brightness) {
    const primaryColor = Color(0xFF4DA3FF);
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0E1B26)
          : const Color(0xFFF8FCFF),
      fontFamily: 'Roboto',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TDL',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi'), Locale('en')],
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: _themeMode,
      home: _LoginPage(
        taskController: _taskController,
        onThemeChanged: (isDark) {
          setState(() {
            _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
          });
        },
      ),
    );
  }
}

class _LoginPage extends StatelessWidget {
  const _LoginPage({
    required this.taskController,
    required this.onThemeChanged,
  });

  final TaskController taskController;
  final ValueChanged<bool> onThemeChanged;

  void _showNextStepMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return LoginView(
      onGoogleSignIn: () => _showNextStepMessage(
        context,
        'Đăng nhập Google sẽ được kết nối với Supabase ở bước tiếp theo.',
      ),
      onContinueAsGuest: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => _GuestHomePage(
            taskController: taskController,
            onThemeChanged: onThemeChanged,
          ),
        ),
      ),
    );
  }
}

class _GuestHomePage extends StatelessWidget {
  const _GuestHomePage({
    required this.taskController,
    required this.onThemeChanged,
  });

  final TaskController taskController;
  final ValueChanged<bool> onThemeChanged;

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: taskController,
      builder: (context, _) => HomeView(
        isSignedIn: false,
        tasks: taskController.activeTasks,
        onDeleteTask: taskController.moveToTrash,
        onOpenTask: (id) {
          final task = taskController.findById(id);
          if (task == null) return;
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TextTaskView(
                initialTask: task,
                onSave: (draft) {
                  taskController.updateTextTask(
                    id: id,
                    title: draft.title,
                    description: draft.description,
                    richTextJson: draft.richTextJson,
                  );
                },
              ),
            ),
          );
        },
        onThemeChanged: onThemeChanged,
        onGoogleSignIn: () => _showMessage(
          context,
          'Đăng nhập Google sẽ được kết nối với Supabase ở bước tiếp theo.',
        ),
        onSignOut: () {},
        onOpenTrash: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TrashView(taskController: taskController),
          ),
        ),
        onCreateDrawing: () => _showMessage(
          context,
          'Màn hình bản vẽ sẽ được thực hiện ở bước tiếp theo.',
        ),
        onCreateText: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TextTaskView(
              onSave: (draft) {
                taskController.addTextTask(
                  title: draft.title,
                  description: draft.description,
                  richTextJson: draft.richTextJson,
                );
              },
            ),
          ),
        ),
        onCreateImage: () => _showMessage(
          context,
          'Chức năng chọn hình ảnh sẽ được thực hiện ở bước tiếp theo.',
        ),
      ),
    );
  }
}
