import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── PALETTE ──────────────────────────────────────────────────────────────────

class CyColors {
  // Fond
  static const cream       = Color(0xFFF9F5F0);
  static const creamDark   = Color(0xFFEDE7DF);
  static const creamBorder = Color(0xFFE8DDD4);

  // Bordeaux
  static const bordeaux    = Color(0xFF7C1C2E);
  static const bordeauxDark= Color(0xFF5A1220);
  static const bordeauxLight= Color(0xFFFDF0F2);
  static const bordeauxBorder= Color(0xFFE8C5CC);

  // Or
  static const gold        = Color(0xFFC8973F);
  static const goldLight   = Color(0xFFFAF3E3);
  static const goldBorder  = Color(0xFFE8D5A8);

  // Texte
  static const inkDark     = Color(0xFF2B0D14);  // quasi-noir bordeaux
  static const inkMid      = Color(0xFF7C5A3E);  // brun moyen
  static const inkLight    = Color(0xFFB09880);  // gris chaud

  // Succès / Erreur
  static const successDark = Color(0xFF1C5C35);
  static const successMid  = Color(0xFF2E8A53);
  static const successLight= Color(0xFFE8F5EE);
  static const errorDark   = Color(0xFF7A1515);
  static const errorMid    = Color(0xFFC0392B);
  static const errorLight  = Color(0xFFFAECEC);

  // Caméra
  static const camBg       = Color(0xFF1A0A0E);
}

// ─── TYPOGRAPHY ───────────────────────────────────────────────────────────────

class CyText {
  static TextStyle logo({double size = 22}) => GoogleFonts.playfairDisplay(
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: CyColors.inkDark,
    letterSpacing: 0.3,
  );

  static TextStyle logoAccent({double size = 22}) => GoogleFonts.playfairDisplay(
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: CyColors.bordeaux,
    letterSpacing: 0.3,
  );

  static TextStyle heading({double size = 20, Color? color}) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: color ?? CyColors.inkDark,
    letterSpacing: -0.3,
  );

  static TextStyle body({double size = 14, Color? color}) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: color ?? CyColors.inkMid,
    height: 1.5,
  );

  static TextStyle label({double size = 12, Color? color}) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: FontWeight.w500,
    color: color ?? CyColors.inkLight,
    letterSpacing: 0.3,
  );

  static TextStyle mono({double size = 12, Color? color}) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    color: color ?? CyColors.inkLight,
    letterSpacing: 0.5,
  );
}

// ─── THEME ────────────────────────────────────────────────────────────────────

class CyTheme {
  static ThemeData get theme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: CyColors.cream,
    colorScheme: const ColorScheme.light(
      primary: CyColors.bordeaux,
      secondary: CyColors.gold,
      surface: CyColors.cream,
      error: CyColors.errorMid,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: CyColors.cream,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      iconTheme: const IconThemeData(color: CyColors.inkDark),
      titleTextStyle: CyText.heading(size: 16),
    ),
    dividerColor: CyColors.creamBorder,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: CyColors.creamBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: CyColors.creamBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: CyColors.bordeaux, width: 1.5),
      ),
      labelStyle: CyText.label(),
      hintStyle: CyText.label(),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: CyColors.bordeaux,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        textStyle: CyText.label(size: 14, color: Colors.white),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CyColors.bordeaux,
        side: const BorderSide(color: CyColors.bordeauxBorder),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: CyText.label(size: 14, color: CyColors.bordeaux),
      ),
    ),
  );
}

// ─── WIDGETS RÉUTILISABLES ────────────────────────────────────────────────────

/// Logo "CyScan" avec le Cy en bordeaux
class CyScanLogo extends StatelessWidget {
  final double size;
  const CyScanLogo({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: 'Cy', style: CyText.logoAccent(size: size)),
          TextSpan(text: 'Scan', style: CyText.logo(size: size)),
        ],
      ),
    );
  }
}

/// Carte avec fond crème, bord subtil
class CyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final VoidCallback? onTap;

  const CyCard({super.key, required this.child, this.padding, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CyColors.creamBorder),
          ),
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

/// Badge de statut (EN COURS, À VENIR, TERMINÉ)
class CyBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const CyBadge({super.key, required this.label, required this.bg, required this.fg});

  factory CyBadge.active()   => const CyBadge(label: 'EN COURS', bg: Color(0xFFE8F5EE), fg: Color(0xFF1C5C35));
  factory CyBadge.upcoming() => const CyBadge(label: 'À VENIR',  bg: Color(0xFFFAF3E3), fg: Color(0xFF8A6020));
  factory CyBadge.past()     => const CyBadge(label: 'TERMINÉ',  bg: Color(0xFFF2EDE8), fg: Color(0xFF7C5A3E));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: CyText.label(size: 10, color: fg)),
    );
  }
}

/// Champ texte stylisé
class CyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final int maxLines;
  final Function(String)? onSubmitted;

  const CyTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.maxLines = 1,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: CyText.body(size: 15, color: CyColors.inkDark),
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: CyColors.inkLight, size: 20),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

/// Bouton primaire bordeaux plein
class CyButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const CyButton({super.key, required this.label, this.onPressed, this.isLoading = false, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(height: 20, width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
            Text(label.toUpperCase(),
                style: CyText.label(size: 13, color: Colors.white).copyWith(letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }
}

/// Séparateur section avec titre
class CySectionTitle extends StatelessWidget {
  final String title;
  const CySectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: CyText.label(size: 11, color: CyColors.gold).copyWith(letterSpacing: 2),
      ),
    );
  }
}