import 'package:flutter/material.dart';

ThemeData journalTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  // WanderConnect Standard uses neutral greys for surface hierarchy.
  final background = dark ? const Color(0xff0a0a0a) : const Color(0xfffafafa);
  final ink = dark ? const Color(0xfff5f5f5) : const Color(0xff0a0a0a);
  final soft = dark ? const Color(0xff1f1f1f) : const Color(0xfff4f4f4);
  final muted = dark ? const Color(0xffa3a3a3) : const Color(0xff6b6b6b);
  final colors =
      ColorScheme.fromSeed(
        seedColor: const Color(0xff0a0a0a),
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
      ).copyWith(
        primary: ink,
        onPrimary: background,
        surface: dark ? const Color(0xff161616) : Colors.white,
        surfaceContainerLow: soft,
        secondaryContainer: dark
            ? const Color(0xff2a2a2a)
            : const Color(0xffe5e5e5),
        onSecondaryContainer: ink,
        onSurface: ink,
        onSurfaceVariant: muted,
        outline: muted,
        outlineVariant: dark
            ? const Color(0xff2a2a2a)
            : const Color(0xffe5e5e5),
      );
  final base = ThemeData(
    colorScheme: colors,
    scaffoldBackgroundColor: background,
  );
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall!.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.4,
      ),
      titleLarge: base.textTheme.titleLarge!.copyWith(
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: base.textTheme.bodyMedium!.copyWith(
        fontSize: 15,
        height: 1.35,
      ),
      titleMedium: base.textTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: base.scaffoldBackgroundColor,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.surface,
      indicatorColor: colors.secondaryContainer,
      height: 72,
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.outline),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}

class JournalIcon extends StatelessWidget {
  const JournalIcon(this.icon, {super.key});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 20, color: colors.primary),
      ),
    );
  }
}

class JournalHeading extends StatelessWidget {
  const JournalHeading(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: theme.textTheme.displaySmall),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

EdgeInsets journalInsets(BuildContext context, {double maxWidth = 700}) {
  final width = MediaQuery.sizeOf(context).width;
  final side = width > maxWidth + 40 ? (width - maxWidth) / 2 : 20.0;
  return EdgeInsets.fromLTRB(side, 20, side, 32);
}

Color journalSeverityColor(int value, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return switch (value) {
    <= 5 => dark ? const Color(0xff8bd6a0) : const Color(0xff236437),
    <= 8 => dark ? const Color(0xffffb26b) : const Color(0xffa54800),
    _ => dark ? const Color(0xffff9397) : const Color(0xffab2230),
  };
}
