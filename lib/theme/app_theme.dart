import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF17181B);
  static const surface = Color(0xFF202227);
  static const card = Color(0xFF2A2C33);
  static const line = Color(0xFF3A3D46);
  static const yellow = Color(0xFFFFC82C);
  static const ink = Color(0xFF1A1A1A);
  static const text = Color(0xFFF4F4F5);
  static const muted = Color(0xFF9EA1AB);
  static const green = Color(0xFF5BD68B);
  static const red = Color(0xFFFF6B6B);
  static const blue = Color(0xFF7DD3FC);
}

class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.yellow,
      onPrimary: AppColors.ink,
      secondary: AppColors.yellow,
      onSecondary: AppColors.ink,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.red,
    );

    OutlineInputBorder border(Color c, [double w = 0]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: w == 0 ? BorderSide.none : BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: ThemeData.dark()
          .textTheme
          .apply(bodyColor: AppColors.text, displayColor: AppColors.text),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: const TextStyle(color: AppColors.muted),
        hintStyle: const TextStyle(color: AppColors.muted),
        prefixIconColor: AppColors.muted,
        border: border(Colors.transparent),
        enabledBorder: border(Colors.transparent),
        focusedBorder: border(AppColors.yellow, 1.5),
        errorBorder: border(AppColors.red, 1.2),
        focusedErrorBorder: border(AppColors.red, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.yellow,
          foregroundColor: AppColors.ink,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.yellow),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.ink,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        extendedTextStyle:
            const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        height: 68,
        indicatorColor: AppColors.yellow,
        indicatorShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected)
                  ? AppColors.ink
                  : AppColors.muted,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: s.contains(WidgetState.selected)
                  ? AppColors.yellow
                  : AppColors.muted,
            )),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: AppColors.yellow,
        labelColor: AppColors.yellow,
        unselectedLabelColor: AppColors.muted,
        dividerColor: AppColors.line,
        labelStyle: TextStyle(fontWeight: FontWeight.w700),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        selectedColor: AppColors.yellow,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        showCheckmark: false,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.card,
        contentTextStyle: const TextStyle(color: AppColors.text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        titleTextStyle: const TextStyle(
            color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerColor: AppColors.line,
    );
  }
}
