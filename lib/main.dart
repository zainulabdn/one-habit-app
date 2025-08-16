import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/settings/settings_screen.dart';
import 'router.dart';
import 'theme/theme.dart';
import 'data/habit_repo.dart';
import 'models/habit.dart';
// @_zain.ul.abdn

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(HabitAdapter());
  await HabitRepo.open();
  runApp(ProviderScope(child: OneTapHabitApp()));
}

class OneTapHabitApp extends ConsumerWidget {
  OneTapHabitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = createRouter();
    final mode = ref.watch(themeModeProvider);
    final seed = ref.watch(accentColorProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(seed),
      darkTheme: buildDarkTheme(seed),
      themeMode: mode,
      routerConfig: router,
    );
  }
}
