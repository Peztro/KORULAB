import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Radios usados en toda la app.
abstract final class KoruRadius {
  static const s = 12.0;
  static const m = 16.0;
  static const l = 22.0;
  static const xl = 28.0;
}

/// Colores de acento de Korulab, con una versión para cada tema.
///
/// Úsalos con `context.koru.hoja`, `context.koru.oro`, etc. Así un mismo
/// widget se ve bien en el tema claro y en el oscuro.
@immutable
class KoruTokens extends ThemeExtension<KoruTokens> {
  const KoruTokens({
    required this.hoja,
    required this.agua,
    required this.oro,
    required this.fuego,
    required this.tierra,
    required this.degradadoHero,
    required this.textoHero,
  });

  /// Verde de marca para iconos y acentos.
  final Color hoja;
  final Color agua;
  final Color oro;
  final Color fuego;
  final Color tierra;

  /// Fondo de las tarjetas destacadas (bienvenida, cabeceras).
  final Gradient degradadoHero;

  /// Texto sobre [degradadoHero]; siempre claro.
  final Color textoHero;

  static const oscuro = KoruTokens(
    hoja: Color(0xFF5BD27A),
    agua: Color(0xFF4FD1C5),
    oro: Color(0xFFFFC94D),
    fuego: Color(0xFFFF8A3D),
    tierra: Color(0xFFC9A27E),
    degradadoHero: LinearGradient(
      colors: [Color(0xFF1F5A33), Color(0xFF12433E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textoHero: Color(0xFFF2FBF4),
  );

  static const claro = KoruTokens(
    hoja: Color(0xFF1E9A4A),
    agua: Color(0xFF0F8C83),
    oro: Color(0xFFC48A00),
    fuego: Color(0xFFE8661A),
    tierra: Color(0xFF8B6A4E),
    degradadoHero: LinearGradient(
      colors: [Color(0xFF2E8B4F), Color(0xFF16786F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textoHero: Color(0xFFFFFFFF),
  );

  @override
  KoruTokens copyWith({
    Color? hoja,
    Color? agua,
    Color? oro,
    Color? fuego,
    Color? tierra,
    Gradient? degradadoHero,
    Color? textoHero,
  }) {
    return KoruTokens(
      hoja: hoja ?? this.hoja,
      agua: agua ?? this.agua,
      oro: oro ?? this.oro,
      fuego: fuego ?? this.fuego,
      tierra: tierra ?? this.tierra,
      degradadoHero: degradadoHero ?? this.degradadoHero,
      textoHero: textoHero ?? this.textoHero,
    );
  }

  @override
  KoruTokens lerp(KoruTokens? other, double t) {
    if (other == null) return this;
    return KoruTokens(
      hoja: Color.lerp(hoja, other.hoja, t)!,
      agua: Color.lerp(agua, other.agua, t)!,
      oro: Color.lerp(oro, other.oro, t)!,
      fuego: Color.lerp(fuego, other.fuego, t)!,
      tierra: Color.lerp(tierra, other.tierra, t)!,
      degradadoHero: Gradient.lerp(degradadoHero, other.degradadoHero, t)!,
      textoHero: Color.lerp(textoHero, other.textoHero, t)!,
    );
  }
}

extension KoruThemeContext on BuildContext {
  KoruTokens get koru =>
      Theme.of(this).extension<KoruTokens>() ?? KoruTokens.oscuro;
}

const _esquemaOscuro = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF5BD27A),
  onPrimary: Color(0xFF05260F),
  primaryContainer: Color(0xFF1F5A33),
  onPrimaryContainer: Color(0xFFB9F3C8),
  secondary: Color(0xFF4FD1C5),
  onSecondary: Color(0xFF032B27),
  secondaryContainer: Color(0xFF12433E),
  onSecondaryContainer: Color(0xFFB8F2EB),
  tertiary: Color(0xFFFFC94D),
  onTertiary: Color(0xFF3A2C00),
  tertiaryContainer: Color(0xFF4A3A10),
  onTertiaryContainer: Color(0xFFFFE6A8),
  error: Color(0xFFFF6B6B),
  onError: Color(0xFF3B0000),
  errorContainer: Color(0xFF5C1A1A),
  onErrorContainer: Color(0xFFFFD6D6),
  surface: Color(0xFF0B140E),
  onSurface: Color(0xFFEAF5EC),
  surfaceContainerLowest: Color(0xFF0B140E),
  surfaceContainerLow: Color(0xFF111C14),
  surfaceContainer: Color(0xFF15221A),
  surfaceContainerHigh: Color(0xFF1A2A1F),
  surfaceContainerHighest: Color(0xFF213426),
  onSurfaceVariant: Color(0xFFA9C2AF),
  outline: Color(0xFF2C4233),
  outlineVariant: Color(0xFF1F3025),
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: Color(0xFFEAF5EC),
  onInverseSurface: Color(0xFF0B140E),
  inversePrimary: Color(0xFF1E7A3E),
  surfaceTint: Colors.transparent,
);

const _esquemaClaro = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF1E7A3E),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFCDEFD6),
  onPrimaryContainer: Color(0xFF0B3A1B),
  secondary: Color(0xFF0F7C74),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFC6EEE9),
  onSecondaryContainer: Color(0xFF053A35),
  tertiary: Color(0xFF8F6400),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFFFE8B0),
  onTertiaryContainer: Color(0xFF3A2900),
  error: Color(0xFFC62828),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF5C0F0F),
  surface: Color(0xFFF4F8F3),
  onSurface: Color(0xFF10201A),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFFFFFFF),
  surfaceContainer: Color(0xFFFFFFFF),
  surfaceContainerHigh: Color(0xFFEEF4EE),
  surfaceContainerHighest: Color(0xFFE4EDE5),
  onSurfaceVariant: Color(0xFF4F6656),
  outline: Color(0xFFBFD0C3),
  outlineVariant: Color(0xFFDDE7DF),
  shadow: Color(0xFF0B2414),
  scrim: Colors.black,
  inverseSurface: Color(0xFF1A2A1F),
  onInverseSurface: Color(0xFFEAF5EC),
  inversePrimary: Color(0xFF5BD27A),
  surfaceTint: Colors.transparent,
);

/// Con [fuentesDeGoogle] en false se usa la fuente por defecto, para tests
/// que no tienen acceso a la red.
ThemeData construirTemaKorulab(
  Brightness brillo, {
  bool fuentesDeGoogle = true,
}) {
  final oscuro = brillo == Brightness.dark;
  final scheme = oscuro ? _esquemaOscuro : _esquemaClaro;
  final tokens = oscuro ? KoruTokens.oscuro : KoruTokens.claro;
  final textoColor = scheme.onSurface;
  final textoSuave = scheme.onSurfaceVariant;

  final base = ThemeData(colorScheme: scheme, useMaterial3: true);

  TextStyle fuente({
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) => fuentesDeGoogle
      ? GoogleFonts.nunito(
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          letterSpacing: letterSpacing,
          color: color,
        )
      : TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          letterSpacing: letterSpacing,
          color: color,
        );

  TextStyle nunito(
    double size,
    FontWeight weight, {
    double? height,
    double? ls,
  }) => fuente(
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: ls,
    color: textoColor,
  );

  final texto =
      (fuentesDeGoogle
              ? GoogleFonts.nunitoTextTheme(base.textTheme)
              : base.textTheme)
          .apply(bodyColor: textoColor, displayColor: textoColor)
          .copyWith(
            headlineMedium: nunito(28, FontWeight.w900, ls: -0.5),
            headlineSmall: nunito(24, FontWeight.w800, ls: -0.3),
            titleLarge: nunito(20, FontWeight.w800),
            titleMedium: nunito(16, FontWeight.w700),
            bodyLarge: nunito(16, FontWeight.w400, height: 1.45),
            bodyMedium: nunito(14, FontWeight.w400, height: 1.4),
            labelLarge: nunito(15, FontWeight.w800, ls: 0.2),
          );

  RoundedRectangleBorder redondeado(double r) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));

  final bordeCampo = OutlineInputBorder(
    borderRadius: BorderRadius.circular(KoruRadius.m),
    borderSide: BorderSide(color: scheme.outlineVariant),
  );

  return base.copyWith(
    extensions: [tokens],
    textTheme: texto,
    scaffoldBackgroundColor: scheme.surface,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: textoColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: texto.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainer,
      elevation: oscuro ? 0 : 1.5,
      shadowColor: scheme.shadow.withValues(alpha: 0.25),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KoruRadius.l),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      height: 72,
      elevation: oscuro ? 0 : 3,
      shadowColor: scheme.shadow.withValues(alpha: 0.3),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : textoSuave,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => fuente(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? textoColor
              : textoSuave,
        ),
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(KoruRadius.xl),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: redondeado(KoruRadius.m),
        textStyle: texto.labelLarge,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 48),
        elevation: 0,
        backgroundColor: scheme.surfaceContainerHighest,
        foregroundColor: textoColor,
        shape: redondeado(KoruRadius.m),
        textStyle: texto.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        foregroundColor: textoColor,
        side: BorderSide(color: scheme.outline),
        shape: redondeado(KoruRadius.m),
        textStyle: texto.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        shape: redondeado(KoruRadius.s),
        textStyle: texto.labelLarge,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: scheme.primaryContainer,
        selectedForegroundColor: scheme.onPrimaryContainer,
        foregroundColor: textoSuave,
        side: BorderSide(color: scheme.outline),
        textStyle: fuente(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: bordeCampo,
      enabledBorder: bordeCampo,
      focusedBorder: bordeCampo.copyWith(
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      labelStyle: TextStyle(color: textoSuave),
      prefixIconColor: textoSuave,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      side: BorderSide(color: scheme.outlineVariant),
      shape: redondeado(KoruRadius.s),
      labelStyle: fuente(fontWeight: FontWeight.w700, color: textoColor),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: tokens.hoja,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(KoruRadius.m)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: oscuro
          ? scheme.surfaceContainerHigh
          : scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: redondeado(KoruRadius.xl),
      titleTextStyle: texto.titleLarge,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(KoruRadius.xl),
        ),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: oscuro
          ? scheme.surfaceContainerHighest
          : scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: redondeado(KoruRadius.m),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: fuente(
        color: scheme.onInverseSurface,
        fontWeight: FontWeight.w600,
      ),
      shape: redondeado(KoruRadius.m),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHighest,
    ),
    tabBarTheme: TabBarThemeData(
      indicatorColor: scheme.primary,
      labelColor: textoColor,
      unselectedLabelColor: textoSuave,
      dividerColor: scheme.outlineVariant,
      labelStyle: fuente(fontWeight: FontWeight.w800),
    ),
  );
}
