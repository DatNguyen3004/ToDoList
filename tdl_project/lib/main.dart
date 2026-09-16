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
import 'views/tasks/voice_task_view.dart';
import 'views/trash/trash_view.dart';
import 'widgets/brand_logo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TdlBootstrap());
}

class _BootstrapData {
  const _BootstrapData({
    required this.taskController,
    required this.localStore,
    required this.initialUser,
  });

  final TaskController taskController;
  final LocalTaskStore localStore;
  final User? initialUser;
}

class TdlBootstrap extends StatefulWidget {
  const TdlBootstrap({super.key});

  @override
  State<TdlBootstrap> createState() => _TdlBootstrapState();
}

class _TdlBootstrapState extends State<TdlBootstrap> {
  late Future<_BootstrapData> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  Future<_BootstrapData> _initialize() async {
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
    return _BootstrapData(
      taskController: taskController,
      localStore: localStore,
      initialUser: initialUser,
    );
  }

  void _retry() {
    setState(() => _initialization = _initialize());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapData>(
      future: _initialization,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data != null) {
          return TdlApp(
            taskController: data.taskController,
            localStore: data.localStore,
            initialUser: data.initialUser,
            initialGuestMode:
                data.initialUser == null &&
                data.localStore.hasSelectedGuestMode,
            initialTasksLoaded: false,
          );
        }
        return StartupSplash(
          errorMessage: snapshot.hasError
              ? 'Không thể tải dữ liệu ứng dụng.'
              : null,
          onRetry: snapshot.hasError ? _retry : null,
        );
      },
    );
  }
}

class StartupSplash extends StatefulWidget {
  const StartupSplash({this.errorMessage, this.onRetry, super.key});

  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  State<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<StartupSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.04).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1976D2);
    final hasError = widget.errorMessage != null;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TDL',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FCFF),
        colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: const BrandLogo(
                      key: Key('startup_brand_logo'),
                      size: 112,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'TDL',
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!hasError)
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: primaryBlue,
                      ),
                    )
                  else ...[
                    Text(
                      widget.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF6F8192)),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      key: const Key('retry_startup_button'),
                      onPressed: widget.onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TdlApp extends StatefulWidget {
  const TdlApp({
    this.taskController,
    this.localStore,
    this.initialUser,
    this.initialGuestMode = false,
    this.initialTasksLoaded = true,
    super.key,
  });

  final TaskController? taskController;
  final LocalTaskStore? localStore;
  final User? initialUser;
  final bool initialGuestMode;
  final bool initialTasksLoaded;

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
  bool _isLoadingTasks = false;

  @override
  void initState() {
    super.initState();
    _ownsTaskController = widget.taskController == null;
    _taskController = widget.taskController ?? TaskController();
    _user = widget.initialUser;
    _continueAsGuest = widget.initialGuestMode;
    _isLoadingTasks = !widget.initialTasksLoaded;

    if (SupabaseConfig.isConfigured) {
      _authService = AuthService(Supabase.instance.client);
      _authSubscription = _authService!.authStateChanges.listen(
        (state) => _handleAuthChange(state.session?.user),
      );
      if (_user != null) unawaited(_refreshCurrentUser());
    }
    if (_isLoadingTasks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_loadInitialTasks());
      });
    }
  }

  Future<void> _loadInitialTasks() async {
    try {
      await _taskController.load();
    } on Object catch (error) {
      if (mounted) _showMessage('Không thể đồng bộ công việc: $error');
    } finally {
      if (mounted) setState(() => _isLoadingTasks = false);
    }
  }

  Future<void> _refreshCurrentUser() async {
    try {
      final refreshedUser = await _authService?.refreshCurrentUser();
      if (!mounted || refreshedUser == null || refreshedUser.id != _user?.id) {
        return;
      }
      setState(() => _user = refreshedUser);
    } on Object catch (error) {
      debugPrint('Không thể làm mới ảnh đại diện Google: $error');
    }
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    if (_ownsTaskController) _taskController.dispose();
    super.dispose();
  }

  Future<void> _handleAuthChange(User? user) async {
    if (!mounted) return;
    if (user?.id == _user?.id) {
      if (user != null) setState(() => _user = user);
      if (user != null) unawaited(_refreshCurrentUser());
      return;
    }
    setState(() {
      _user = user;
      _continueAsGuest = user == null;
      _isLoadingTasks = true;
    });
    if (user != null) unawaited(_refreshCurrentUser());
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
      if (user == null) unawaited(widget.localStore?.rememberGuestMode());
    } on Object catch (error) {
      if (mounted) _showMessage('Không thể tải dữ liệu tài khoản: $error');
    } finally {
      if (mounted) setState(() => _isLoadingTasks = false);
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
      if (mounted) _showMessage('Đăng xuất thành công.');
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
      home: showHome
          ? _HomePage(
              taskController: _taskController,
              user: _user,
              isLoadingTasks: _isLoadingTasks,
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
    required this.isLoadingTasks,
    this.user,
  });

  final TaskController taskController;
  final ValueChanged<bool> onThemeChanged;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onSignOut;
  final bool isLoadingTasks;
  final User? user;

  String? _photoUrlIn(Map<String, dynamic>? metadata, {int depth = 0}) {
    if (metadata == null || depth > 2) return null;
    for (final key in const ['avatar_url', 'picture', 'photo_url', 'avatar']) {
      final value = metadata[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    for (final value in metadata.values) {
      if (value is Map) {
        final nested = _photoUrlIn(
          Map<String, dynamic>.from(value),
          depth: depth + 1,
        );
        if (nested != null) return nested;
      }
    }
    return null;
  }

  String? _photoUrlFor(User? currentUser) {
    if (currentUser == null) return null;
    final metadataSources = <Map<String, dynamic>?>[
      currentUser.userMetadata,
      ...?currentUser.identities
          ?.where((identity) => identity.provider == 'google')
          .map((identity) => identity.identityData),
      ...?currentUser.identities?.map((identity) => identity.identityData),
    ];
    for (final metadata in metadataSources) {
      final photoUrl = _photoUrlIn(metadata);
      if (photoUrl != null) return photoUrl;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final metadata = user?.userMetadata;
    final photoUrl = _photoUrlFor(user);
    return AnimatedBuilder(
      animation: taskController,
      builder: (context, _) => HomeView(
        isSignedIn: user != null,
        userPhotoUrl: photoUrl,
        displayName: (metadata?['full_name'] ?? metadata?['name']) as String?,
        email: user?.email,
        tasks: taskController.activeTasks,
        isLoadingTasks: isLoadingTasks,
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
        onCreateVoice: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => VoiceTaskView(
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
      ),
    );
  }
}
