import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core.dart';
import 'screens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const ComeOnApp());
}

class ComeOnApp extends StatefulWidget {
  const ComeOnApp({super.key});
  @override
  State<ComeOnApp> createState() => _ComeOnAppState();
}

class _ComeOnAppState extends State<ComeOnApp> {
  final app = AppState();
  @override
  void initState() {
    super.initState();
    app.init();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFFFFC857), brightness: Brightness.dark)
        .copyWith(surface: const Color(0xFF0B0B0D));
    return MaterialApp(
      title: 'Come On',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: scheme, scaffoldBackgroundColor: scheme.surface,
        appBarTheme: AppBarTheme(backgroundColor: scheme.surface, scrolledUnderElevation: 0),
        inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
        bottomSheetTheme: const BottomSheetThemeData(showDragHandle: true),
      ),
      home: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final p = app.project;
          if (!app.loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          if (p == null) return CreateScreen(state: app);
          if (!p.planned) return PlanScreen(state: app, setup: true);
          return HomeScreen(state: app);
        },
      ),
    );
  }
}
