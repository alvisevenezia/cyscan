import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/app_state.dart';
import '../../services/api_service.dart';
import '../../theme/cy_theme.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;
  const EventDetailScreen({super.key, required this.event});
  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Map<String, dynamic>? _stats;
  bool _loadingStats = true;
  bool _importing = false;
  String? _importMsg;
  bool _importOk = false;

  @override
  void initState() { super.initState(); _loadStats(); }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final s = await context.read<AppState>().api.getStats(widget.event.id);
      setState(() { _stats = s; _loadingStats = false; });
    } catch (_) { setState(() => _loadingStats = false); }
  }

  Future<void> _importCSV() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (r == null || r.files.single.path == null) return;
    setState(() { _importing = true; _importMsg = null; });
    try {
      final res = await context.read<AppState>().api.importCSV(widget.event.id, File(r.files.single.path!));
      setState(() {
        _importing = false;
        _importOk = !res.containsKey('error');
        _importMsg = res.containsKey('error')
            ? res['error']
            : '${res['imported']} billets importés  ·  ${res['skipped']} ignorés\n'
            + (res['tarifs'] as Map<String,dynamic>? ?? {}).entries
                .map((e) => '${e.value}× ${e.key}').join('\n');
      });
      if (_importOk) _loadStats();
    } catch (e) {
      setState(() { _importing = false; _importOk = false; _importMsg = e.toString(); });
    }
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
        title: Text(widget.event.name, style: CyText.heading(size: 15), overflow: TextOverflow.ellipsis),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded, color: CyColors.inkLight, size: 20),
            onPressed: _loadStats)],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
            child: Container(height: 0.5, color: CyColors.creamBorder)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _infoCard(),
          const SizedBox(height: 24),
          const CySectionTitle('Statistiques'),
          _loadingStats
              ? const Center(child: CircularProgressIndicator(color: CyColors.bordeaux, strokeWidth: 2))
              : _statsGrid(),
          const SizedBox(height: 28),
          const CySectionTitle('Importer des billets HelloAsso'),
          Text('Export CSV depuis HelloAsso → Participants → Exporter.',
              style: CyText.body(size: 13, color: CyColors.inkLight)),
          const SizedBox(height: 14),
          if (_importMsg != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: _importOk ? CyColors.successLight : CyColors.errorLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _importOk ? CyColors.successMid.withOpacity(.3) : CyColors.errorMid.withOpacity(.3)),
              ),
              child: Text(_importMsg!, style: CyText.body(size: 13,
                  color: _importOk ? CyColors.successDark : CyColors.errorMid)),
            ),
          ],
          OutlinedButton.icon(
            onPressed: _importing ? null : _importCSV,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: CyColors.bordeauxBorder),
              foregroundColor: CyColors.bordeaux,
              backgroundColor: CyColors.bordeauxLight,
            ),
            icon: _importing
                ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: CyColors.bordeaux))
                : const Icon(Icons.upload_file_outlined, size: 18),
            label: Text(_importing ? 'Importation…' : 'Choisir le fichier CSV',
                style: CyText.label(size: 13, color: CyColors.bordeaux)),
          ),
        ]),
      ),
    );
  }

  Widget _infoCard() {
    return CyCard(
      child: Column(children: [
        _row(Icons.calendar_today_outlined, 'Début', widget.event.dateStart),
        const SizedBox(height: 8),
        _row(Icons.calendar_month_outlined, 'Fin', widget.event.dateEnd),
        if (widget.event.description != null) ...[
          const SizedBox(height: 8),
          _row(Icons.notes_rounded, 'Description', widget.event.description!),
        ],
      ]),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 15, color: CyColors.inkLight),
      const SizedBox(width: 8),
      Text('$label : ', style: CyText.body(size: 13, color: CyColors.inkLight)),
      Expanded(child: Text(value, style: CyText.body(size: 13, color: CyColors.inkDark))),
    ]);
  }

  Widget _statsGrid() {
    if (_stats == null) return Text('Pas de données', style: CyText.body(size: 13, color: CyColors.inkLight));
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.6,
      children: [
        _statCard('Billets', '${_stats!['total_tickets']}', Icons.confirmation_number_outlined, CyColors.bordeaux, CyColors.bordeauxLight),
        _statCard('Scannés', '${_stats!['scanned_tickets']}', Icons.qr_code_scanner, CyColors.gold, CyColors.goldLight),
        _statCard('Servis', '${_stats!['consumed_drinks']}', Icons.wine_bar_outlined, CyColors.inkMid, CyColors.creamDark),
        _statCard('Restants', '${_stats!['remaining_drinks']}', Icons.local_bar_outlined, CyColors.successMid, CyColors.successLight),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.15)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: fg, size: 20),
        const SizedBox(height: 6),
        Text(value, style: CyText.heading(size: 22, color: fg)),
        Text(label, style: CyText.label(size: 11, color: fg.withOpacity(0.7)), textAlign: TextAlign.center),
      ]),
    );
  }
}