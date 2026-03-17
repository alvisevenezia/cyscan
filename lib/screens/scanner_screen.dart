import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/api_service.dart';
import '../theme/cy_theme.dart';
import 'admin/admin_login_screen.dart';
import 'admin/admin_dashboard_screen.dart';

String extractReference(String raw) {
  raw = raw.trim();

  // Tentative de décodage base64 (format HelloAsso natif)
  try {
    final decoded = utf8.decode(base64.decode(raw));
    // Format attendu : "157588674:638983901885433866"
    if (decoded.contains(':')) {
      return decoded.split(':').first.trim();
    }
    if (RegExp(r'^\d+$').hasMatch(decoded.trim())) {
      return decoded.trim();
    }
  } catch (_) {}

  // URL HelloAsso → extraire ticketId
  final uri = Uri.tryParse(raw);
  if (uri != null && uri.queryParameters.containsKey('ticketId')) {
    return uri.queryParameters['ticketId']!;
  }

  // Numéro brut ou référence manuelle → tel quel
  return raw;
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with TickerProviderStateMixin {
  final MobileScannerController _cam = MobileScannerController();
  bool _isProcessing = false;
  ScanResult? _lastResult;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  static const _holeSize = 270.0;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 340));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.98, end: 1.02)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _cam.dispose();
    _slideCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    setState(() => _isProcessing = true);
    _cam.stop();

    final reference = extractReference(barcode!.rawValue!);
    final result = await context.read<AppState>().api.scanTicket(reference);


    setState(() { _lastResult = result; _isProcessing = false; });
    _slideCtrl.forward(from: 0);

    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      await _slideCtrl.reverse();
      if (mounted) {
        setState(() => _lastResult = null);
        _cam.start();
      }
    }
  }

  void _goAdmin() {
    _cam.stop();
    final state = context.read<AppState>();
    if (state.isAdmin) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()))
          .then((_) { if (mounted) _cam.start(); });
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen()))
          .then((_) { if (mounted) _cam.start(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(fit: StackFit.expand, children: [

          // 1. Caméra plein écran
          MobileScanner(controller: _cam, onDetect: _onDetect),

          // 2. Overlay sombre autour du carré de scan (simple CustomPaint, pas de blur)
          CustomPaint(painter: _DarkOverlayPainter(holeSize: _holeSize)),

          // 3. Fenêtre de scan carrée blanche
          _buildScanWindow(),

          // 4. Hint sous la fenêtre
          _buildHint(),

          // 6. Loading spinner
          if (_isProcessing)
            Container(color: Colors.black45,
                child: const Center(child: CircularProgressIndicator(color: CyColors.gold, strokeWidth: 2))),

          // 7. Carte résultat qui monte depuis le bas
          if (_lastResult != null)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SlideTransition(
                position: _slideAnim,
                child: _buildResultCard(_lastResult!),
              ),
            ),

          // 5. Top bar EN DERNIER = au-dessus de tout
          _buildTopBar(),
        ]),
      ),
    );
  }

  // ── Fenêtre de scan : carré blanc + coins or ──────────────────────────────

  Widget _buildScanWindow() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(scale: _isProcessing ? 1.0 : _pulseAnim.value, child: child),
      child: Center(
        child: SizedBox(
          width: _holeSize,
          height: _holeSize,
          child: Stack(children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.85), width: 1.5),
              ),
            ),
            CustomPaint(size: const Size(_holeSize, _holeSize), painter: _GoldCornersPainter()),
          ]),
        ),
      ),
    );
  }

  Widget _buildHint() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: _holeSize + 20),
        Text(
          'Pointez vers le QR code du billet',
          textAlign: TextAlign.center,
          style: CyText.label(size: 13, color: Colors.white.withOpacity(0.5)).copyWith(letterSpacing: .3),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        color: Colors.black,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const CyScanLogo(size: 22),
                Consumer<AppState>(
                  builder: (_, state, __) => GestureDetector(
                    onTap: _goAdmin,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: state.isAdmin
                            ? CyColors.gold.withOpacity(0.18)
                            : Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: state.isAdmin
                              ? CyColors.gold.withOpacity(0.55)
                              : Colors.white.withOpacity(0.22),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            state.isAdmin ? Icons.admin_panel_settings_outlined : Icons.person_outline,
                            color: state.isAdmin ? CyColors.gold : Colors.white.withOpacity(0.75),
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            state.isAdmin ? 'Admin' : 'Connexion',
                            style: CyText.label(size: 12,
                                color: state.isAdmin ? CyColors.gold : Colors.white.withOpacity(0.75)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Résultat ──────────────────────────────────────────────────────────────

  Widget _buildResultCard(ScanResult result) {
    final ok = result.success;
    return Container(
      decoration: BoxDecoration(
        color: ok ? CyColors.successDark : CyColors.errorDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(24, 18, 24, 28 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 18),

          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(ok ? Icons.check_rounded : Icons.close_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                ok ? (result.holderName ?? 'Billet valide') : 'Billet invalide',
                style: CyText.heading(size: 17, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(result.message,
                  style: CyText.body(size: 13, color: Colors.white.withOpacity(0.65))),
            ])),
          ]),

          if (ok && result.drinksRemaining != null && result.drinksTotal != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(result.drinksTotal!, (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.wine_bar_rounded,
                        color: i < result.drinksRemaining! ? CyColors.gold : Colors.white24, size: 28),
                  )),
                ),
                const SizedBox(height: 6),
                Text('${result.drinksRemaining} / ${result.drinksTotal} verre(s) restant(s)',
                    style: CyText.body(size: 12, color: Colors.white60)),
              ]),
            ),
          ],

          if (result.eventName != null) ...[
            const SizedBox(height: 10),
            Text(result.eventName!,
                style: CyText.label(size: 11, color: Colors.white38), textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

// ─── BLUR OVERLAY ─────────────────────────────────────────────────────────────

class _DarkOverlayPainter extends CustomPainter {
  final double holeSize;
  const _DarkOverlayPainter({required this.holeSize});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;  // vrai centre = même que Center()
    final half = holeSize / 2;

    final outer = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole  = Path()..addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: holeSize, height: holeSize),
      const Radius.circular(12),
    ));
    final masked = Path.combine(PathOperation.difference, outer, hole);
    canvas.drawPath(masked, Paint()..color = Colors.black.withOpacity(0.55));
  }

  @override
  bool shouldRepaint(_DarkOverlayPainter old) => old.holeSize != holeSize;
}

// ─── PAINTERS ─────────────────────────────────────────────────────────────────

class _GoldCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CyColors.gold
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 24.0;
    const r = 11.0;
    final w = size.width;
    final h = size.height;

    // Haut-gauche
    canvas.drawPath(Path()
      ..moveTo(0, len + r)..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: const Radius.circular(r))
      ..lineTo(len + r, 0), paint);
    // Haut-droit
    canvas.drawPath(Path()
      ..moveTo(w - len - r, 0)..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
      ..lineTo(w, len + r), paint);
    // Bas-gauche
    canvas.drawPath(Path()
      ..moveTo(0, h - len - r)..lineTo(0, h - r)
      ..arcToPoint(Offset(r, h), radius: const Radius.circular(r))
      ..lineTo(len + r, h), paint);
    // Bas-droit
    canvas.drawPath(Path()
      ..moveTo(w - len - r, h)..lineTo(w - r, h)
      ..arcToPoint(Offset(w, h - r), radius: const Radius.circular(r))
      ..lineTo(w, h - len - r), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}