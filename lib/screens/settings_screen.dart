import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/cy_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _url = TextEditingController();
  bool _saved = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final u = await context.read<AppState>().api.baseUrl;
    _url.text = u;
  }

  Future<void> _save() async {
    await context.read<AppState>().api.setBaseUrl(_url.text.trim());
    setState(() => _saved = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyColors.cream,
      appBar: AppBar(
        backgroundColor: CyColors.cream,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: CyColors.inkDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Connexion serveur', style: CyText.heading(size: 16)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
            child: Container(height: 0.5, color: CyColors.creamBorder)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 8),
          const CySectionTitle('Adresse du serveur backend'),
          CyTextField(controller: _url, label: 'URL du serveur', icon: Icons.dns_outlined,
              keyboardType: TextInputType.url),
          const SizedBox(height: 8),
          Text('Ex: http://10.0.2.2:8001  ou  https://millesime.logistiscout.fr',
              style: CyText.label(size: 11, color: CyColors.inkLight)),
          const SizedBox(height: 20),
          CyButton(
            label: _saved ? 'Sauvegardé !' : 'Sauvegarder',
            onPressed: _save,
            icon: _saved ? Icons.check_rounded : Icons.save_outlined,
          ),
        ]),
      ),
    );
  }
}