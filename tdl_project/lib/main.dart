import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'controllers/task_controller.dart';
import 'data/cloud_task_store.dart';
import 'data/local_task_store.dart';
import 'data/task_store.dart';
import 'models/task_item.dart';
import 'services/auth_service.dart';
import 'views/auth/login_view.dart';
import 'views/home/home_view.dart';
import 'views/tasks/drawing_task_view.dart';
import 'views/tasks/image_task_view.dart';
import 'views/tasks/text_task_view.dart';
import 'views/trash/trash_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localStore = await LocalTaskStore.open();
  User? initialUser;
  TaskStore initialStore = localStore;

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    initialUser = Supabase.instance.client.auth.currentUser;
    if (initialUser != null) {
      initialStore = CloudTaskStore(
        client: Supabase.instance.client,
        userId: initialUser.id,
      );
    }
  }

  final taskController = TaskController(store: initialStore);
  await taskController.load();
  runApp(
    TdlApp(
      taskController: taskController,
      localStore: localStore,
      initialUser: initialUser,
      initialGuestMode: initialUser == null && localStore.hasSelectedGuestMode,
    ),
  );
}

class TdlApp extends StatefulWidget {
  const TdlApp({
    this.taskController,
    this.localStore,
    this.initialUser,
    this.initialGuestMode = false,
    super.key,
  });

  final TaskController? taskController;
  final LocalTaskStore? localStore;
  final User? initialUser;
  final bool initialGuestMode;

  @override
  State<TdlApp> createState() => _TdlAppState();
}

class _TdlAppState extends State<TdlApp> {
  ThemeMode _themeMode = ThemeMode.light;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final TaskController _taskController;
  late final bool _ownsTaskController;
  AuthService? _authService;
  StreamSubscription<AuthState>? _authSubscription;
  User? _user;
  bool _continueAsGuest = false;
  bool _isSwitchingStore = false;

  @override
  void initState() {
    super.initState();
    _ownsTaskController = widget.taskController == null;
    _taskController = widget.taskController ?? TaskController();
    _user = widget.initialUser;
    _continueAsGuest = widget.initialGuestMode;

    if (SupabaseConfig.isConfigured) {
      _authService = AuthService(Supabase.instance.client);
      _authSubscription = _authService!.authStateChanges.listen(
        (state) => _handleAuthChange(state.session?.user),
      );
    }
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    if (_ownsTaskController) _taskController.dispose();
    super.dispose();
  }

  Future<void> _handleAuthChange(User? user) async {
    if (!mounted || user?.id == _user?.id) return;
    setState(() => _isSwitchingStore = true);
    try {
      if (user != null) {
        await _taskController.useStore(
          CloudTaskStore(client: Supabase.instance.client, userId: user.id),
        );
      } else {
        final localStore = widget.localStore;
        if (localStore != null) {
          await _taskController.useStore(localStore);
        }
      }
      if (!mounted) return;
      setState(() {
        _user = user;
        _continueAsGuest = user == null;
      });
      if (user == null) unawaited(widget.localStore?.rememberGuestMode());
    } on Object catch (error) {
      if (mounted) _showMessage('Không thể tải dữ liệu tài khoản: $error');
    } finally {
      if (mounted) setState(() => _isSwitchingStore = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    final authService = _authService;
    if (authService == null) {
      _showMessage(
        'Chưa cấu hình Supabase. Hãy thêm SUPABASE_URL và '
        'SUPABASE_PUBLISHABLE_KEY khi chạy ứng dụng.',
      );
      return;
    }
    try {
      await authService.signInWithGoogle();
    } on Object catch (error) {
      if (mounted) _showMessage('Không thể đăng nhập Google: $error');
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService?.signOut();
    } on Object catch (error) {
      if (mounted) _showMessage('Không thể đăng xuất: $error');
    }
  }

  void _showMessage(String message) {
    final messenger = _messengerKey.currentState;
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  ThemeData _buildTheme(Brightness brightness) {
    const primaryColor = Color(0xFF1976D2);
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
    final showHome = _user != null || _continueAsGuest;
    return MaterialApp(
      scaffoldMessengerKey: _messengerKey,
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
      home: _isSwitchingStore
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : showHome
          ? _HomePage(
              taskController: _taskController,
              user: _user,
              onGoogleSignIn: _signInWithGoogle,
              onSignOut: _signOut,
              onThemeChanged: (isDark) {
                setState(() {
                  _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
                });
              },
            )
          : _LoginPage(
              onGoogleSignIn: _signInWithGoogle,
              onContinueAsGuest: () {
                setState(() => _continueAsGuest = true);
                unawaited(widget.localStore?.rememberGuestMode());
              },
            ),
    );
  }
}

class _LoginPage extends StatelessWidget {
  const _LoginPage({
    required this.onGoogleSignIn,
    required this.onContinueAsGuest,
  });

  final VoidCallback onGoogleSignIn;
  final VoidCallback onContinueAsGuest;

  @override
  Widget build(BuildContext context) {
    return LoginView(
      onGoogleSignIn: onGoogleSignIn,
      onContinueAsGuest: onContinueAsGuest,
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.taskController,
    required this.onThemeChanged,
    required this.onGoogleSignIn,
    required this.onSignOut,
    this.user,
  });

  final TaskController taskController;
  final ValueChanged<bool> onThemeChanged;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onSignOut;
  final User? user;

  @override
  Widget build(BuildContext context) {
    final metadata = user?.userMetadata;
    return AnimatedBuilder(
      animation: taskController,
      builder: (context, _) => HomeView(
        isSignedIn: user != null,
        userPhotoUrl: metadata?['avatar_url'] as String?,
        displayName: (metadata?['full_name'] ?? metadata?['name']) as String?,
        email: user?.email,
        tasks: taskController.activeTasks,
        onDeleteTask: taskController.moveToTrash,
        onOpenTask: (id) {
          final task = taskController.findById(id);
          if (task == null) return;
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) {
                if (task.contentType == TaskContentType.drawing) {
                  return DrawingTaskView(
                    initialTask: task,
                    onDeleteEmpty: () => taskController.deleteForever(id),
                    onSave: (draft) {
                      taskController.updateDrawingTask(
                        id: id,
                        title: draft.title,
                        drawingJson: draft.drawingJson,
                        strokeCount: draft.strokeCount,
                      );
                    },
                  );
                }
                if (task.contentType == TaskContentType.image) {
                  return ImageTaskView(
                    initialTask: task,
                    onDeleteEmpty: () => taskController.deleteForever(id),
                    onSave: (draft) {
                      taskController.updateImageTask(
                        id: id,
                        title: draft.title,
                        description: draft.description,
                        imageDataJson: draft.imageDataJson,
                      );
                    },
                  );
                }
                return TextTaskView(
                  initialTask: task,
                  onDeleteEmpty: () => taskController.deleteForever(id),
                  onSave: (draft) {
                    taskController.updateTextTask(
                      id: id,
                      title: draft.title,
                      description: draft.description,
                      richTextJson: draft.richTextJson,
                    );
                  },
                );
              },
            ),
          );
        },
        onThemeChanged: onThemeChanged,
        onGoogleSignIn: onGoogleSignIn,
        onSignOut: onSignOut,
        onOpenTrash: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TrashView(taskController: taskController),
          ),
        ),
        onCreateDrawing: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DrawingTaskView(
              onSave: (draft) {
                taskController.addDrawingTask(
                  title: draft.title,
                  drawingJson: draft.drawingJson,
                  strokeCount: draft.strokeCount,
                );
              },
            ),
          ),
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
        onCreateImage: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ImageTaskView(
              onSave: (draft) {
                taskController.addImageTask(
                  title: draft.title,
                  description: draft.description,
                  imageDataJson: draft.imageDataJson,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
