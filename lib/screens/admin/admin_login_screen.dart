import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/app_state.dart';
import '../../theme/cy_theme.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  bool _scanningQR = false;
  final _qrCtrl = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      setState(() => _scanningQR = _tabs.index == 1);
      if (_tabs.index == 0) _qrCtrl.stop();
      else _qrCtrl.start();
    });
  }

  @override
  void dispose() {
    _tabs.dispose(); _user.dispose(); _pass.dispose(); _qrCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginPwd() async {
    setState(() { _loading = true; _error = null; });
    final r = await context.read<AppState>().loginWithPassword(_user.text.trim(), _pass.text);
    if (!mounted) return;
    if (r.success) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
    } else {
      setState(() { _loading = false; _error = r.message; });
    }
  }

  void _onQR(BarcodeCapture c) async {
    if (_loading) return;
    final v = c.barcodes.firstOrNull?.rawValue; if (v == null) return;
    _qrCtrl.stop();
    setState(() => _loading = true);
    final r = await context.read<AppState>().loginWithQR(v);
    if (!mounted) return;
    if (r.success) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
    } else {
      setState(() { _loading = false; _error = r.message; });
      _qrCtrl.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyColors.cream,
      appBar: AppBar(
        backgroundColor: CyColors.cream,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: CyColors.inkDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const CyScanLogo(size: 20),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          labelColor: CyColors.bordeaux,
          unselectedLabelColor: CyColors.inkLight,
          indicatorColor: CyColors.bordeaux,
          indicatorWeight: 2,
          labelStyle: CyText.label(size: 13, color: CyColors.bordeaux),
          tabs: const [Tab(text: 'Mot de passe'), Tab(text: 'QR Admin')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_pwdTab(), _qrTab()],
      ),
    );
  }

  Widget _pwdTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 24),

        // Icône
        Center(
          child: Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: CyColors.bordeauxLight,
              shape: BoxShape.circle,
              border: Border.all(color: CyColors.bordeauxBorder),
            ),
            child: const Icon(Icons.lock_outline_rounded, color: CyColors.bordeaux, size: 28),
          ),
        ),
        const SizedBox(height: 20),
        Text('Connexion administrateur', style: CyText.heading(size: 18), textAlign: TextAlign.center),
        Text('Accès réservé aux gestionnaires d\'événements',
            style: CyText.body(size: 13, color: CyColors.inkLight), textAlign: TextAlign.center),

        const SizedBox(height: 32),
        CyTextField(controller: _user, label: 'Identifiant', icon: Icons.person_outline),
        const SizedBox(height: 14),
        CyTextField(
          controller: _pass, label: 'Mot de passe', icon: Icons.lock_outline,
          obscureText: _obscure,
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: CyColors.inkLight, size: 20),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
          onSubmitted: (_) => _loginPwd(),
        ),

        if (_error != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CyColors.errorLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CyColors.errorMid.withOpacity(0.3)),
            ),
            child: Text(_error!, style: CyText.body(size: 13, color: CyColors.errorMid)),
          ),
        ],

        const SizedBox(height: 28),
        CyButton(label: 'Se connecter', onPressed: _loginPwd, isLoading: _loading,
            icon: Icons.arrow_forward_rounded),
      ]),
    );
  }

  Widget _qrTab() {
    return Stack(children: [
      Column(children: [
        Expanded(child: MobileScanner(controller: _qrCtrl, onDetect: _onQR)),
        Container(
          padding: const EdgeInsets.all(20),
          color: CyColors.cream,
          child: Column(children: [
            const Icon(Icons.qr_code_scanner, color: CyColors.inkLight, size: 22),
            const SizedBox(height: 8),
            Text('Scannez votre QR code administrateur',
                style: CyText.body(size: 13, color: CyColors.inkMid), textAlign: TextAlign.center),
          ]),
        ),
      ]),
      if (_loading)
        Container(color: Colors.black38,
            child: const Center(child: CircularProgressIndicator(color: CyColors.gold))),
      if (_error != null)
        Positioned(
          bottom: 90, left: 16, right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CyColors.errorMid,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_error!, style: CyText.body(size: 13, color: Colors.white),
                textAlign: TextAlign.center),
          ),
        ),
    ]);
  }
}