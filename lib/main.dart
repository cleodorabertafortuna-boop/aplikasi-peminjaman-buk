import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'screens/member/member_shell.dart';
import 'screens/staff/staff_shell.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  final state = AppState();
  await state.restore();
  runApp(ChangeNotifierProvider.value(value: state, child: const PerpusApp()));
}

class PerpusApp extends StatelessWidget {
  const PerpusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perpustakaan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Consumer<AppState>(
        builder: (_, s, __) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutCubic,
          child: s.user == null
              ? const LoginScreen(key: ValueKey('login'))
              : s.user!.isStaff
                  ? const StaffShell(key: ValueKey('staff'))
                  : const MemberShell(key: ValueKey('member')),
        ),
      ),
    );
  }
}
