import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/app_state.dart';
import '../../services/api_service.dart';
import '../../theme/cy_theme.dart';

class TicketQRScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;
  final EventModel event;
  const TicketQRScreen({super.key, required this.ticket, required this.event});
  @override
  State<TicketQRScreen> createState() => _TicketQRScreenState();
}

class _TicketQRScreenState extends State<TicketQRScreen> {
  Uint8List? _qr;
  bool _loading = true;
  bool _sharing = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final b = await context.read<AppState>().api.downloadQrPng(widget.ticket['id']);
      setState(() { _qr = b; _loading = false; });
    } catch (e) {
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _share() async {
    if (_qr == null) return;
    setState(() => _sharing = true);
    try {
      final dir = await getTemporaryDirectory();
      final name = (widget.ticket['holder_name'] ?? 'billet').toString().replaceAll(' ', '_');
      final ref  = widget.ticket['reference'] ?? 'QR';
      final file = File('${dir.path}/billet_${name}_$ref.png');
      await file.writeAsBytes(_qr!);

      final box = context.findRenderObject() as RenderBox;

      await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')],
          text: '${widget.ticket['holder_name']} — ${widget.event.name}',
          subject: 'Billet $ref',
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: CyColors.errorMid));
      }
    }
    setState(() => _sharing = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    return Scaffold(
      backgroundColor: CyColors.cream,
      appBar: AppBar(
        backgroundColor: CyColors.cream,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: CyColors.inkDark, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('QR Code billet', style: CyText.heading(size: 16)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
            child: Container(height: 0.5, color: CyColors.creamBorder)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Infos billet
          CyCard(
            child: Column(children: [
              Text(t['holder_name'] ?? 'Sans nom', style: CyText.heading(size: 20), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(widget.event.name, style: CyText.label(size: 13, color: CyColors.gold), textAlign: TextAlign.center),
              const SizedBox(height: 14),
              Container(height: 0.5, color: CyColors.creamBorder),
              const SizedBox(height: 12),
              _infoRow(Icons.confirmation_number_outlined, t['reference'] ?? ''),
              const SizedBox(height: 6),
              _infoRow(Icons.wine_bar_outlined, '${t['drinks_total']} verre(s)'),
              if ((t['ticket_type'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                _infoRow(Icons.label_outline, t['ticket_type']),
              ],
              if ((t['holder_email'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                _infoRow(Icons.email_outlined, t['holder_email']),
              ],
            ]),
          ),

          const SizedBox(height: 20),

          // QR Code
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CyColors.creamBorder),
            ),
            padding: const EdgeInsets.all(24),
            child: _buildQR(),
          ),

          const SizedBox(height: 20),

          CyButton(
            label: 'Télécharger / Partager',
            onPressed: (_loading || _sharing || _qr == null) ? null : _share,
            isLoading: _sharing,
            icon: Icons.ios_share_rounded,
          ),

          const SizedBox(height: 16),

          // Référence brute sélectionnable
          CyCard(
            color: CyColors.cream,
            child: Column(children: [
              Text('RÉFÉRENCE', style: CyText.label(size: 10, color: CyColors.inkLight).copyWith(letterSpacing: 2)),
              const SizedBox(height: 6),
              SelectableText(t['reference'] ?? '', style: CyText.mono(size: 13, color: CyColors.inkDark),
                  textAlign: TextAlign.center),
            ]),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _buildQR() {
    if (_loading) {
      return const SizedBox(height: 240,
        child: Center(child: CircularProgressIndicator(color: CyColors.bordeaux, strokeWidth: 2)));
    }
    if (_error != null && _qr == null) {
      return SizedBox(height: 220, child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: CyColors.errorMid, size: 40),
        const SizedBox(height: 10),
        Text('Impossible de charger le QR', style: CyText.body(size: 13, color: CyColors.errorMid), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        TextButton(onPressed: _load, child: Text('Réessayer', style: CyText.label(size: 13, color: CyColors.bordeaux))),
      ],
    ));
    }
    return Image.memory(_qr!, fit: BoxFit.contain);
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 14, color: CyColors.inkLight),
      const SizedBox(width: 6),
      Flexible(child: Text(text, style: CyText.body(size: 12, color: CyColors.inkMid),
          overflow: TextOverflow.ellipsis)),
    ]);
  }
}