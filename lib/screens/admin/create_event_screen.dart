import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../theme/cy_theme.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});
  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  DateTime? _start, _end;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final p = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: CyColors.bordeaux, surface: Colors.white),
          dialogTheme: const DialogTheme(backgroundColor: Colors.white).data,
        ),
        child: child!,
      ),
    );
    if (p == null) return;
    setState(() {
      if (isStart) { _start = p; if (_end == null || _end!.isBefore(p)) _end = p; }
      else _end = p;
    });
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) { setState(() => _error = 'Le nom est obligatoire.'); return; }
    if (_start == null || _end == null) { setState(() => _error = 'Choisissez les dates.'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AppState>().api.createEvent({
        'name': _name.text.trim(),
        'description': _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        'date_start': _start!.toIso8601String().split('T').first,
        'date_end': _end!.toIso8601String().split('T').first,
        'drinks_per_ticket': 1, // valeur neutre, écrasée par le CSV HelloAsso
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _error = 'Erreur : $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyColors.cream,
      appBar: AppBar(
        backgroundColor: CyColors.cream,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: CyColors.inkDark, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Nouvel événement', style: CyText.heading(size: 16)),
        centerTitle: true,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 0.5, color: CyColors.creamBorder)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 8),
          const CySectionTitle('Informations'),
          CyTextField(controller: _name, label: 'Nom de l\'événement *', icon: Icons.celebration_outlined),
          const SizedBox(height: 12),
          CyTextField(controller: _desc, label: 'Description (optionnel)', icon: Icons.notes_rounded, maxLines: 3),

          const SizedBox(height: 28),
          const CySectionTitle('Dates'),
          Row(children: [
            Expanded(child: _dateBtn('Début', _start, isStart: true)),
            const SizedBox(width: 12),
            Expanded(child: _dateBtn('Fin', _end, isStart: false)),
          ]),

          if (_error != null) ...[
            const SizedBox(height: 20),
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

          const SizedBox(height: 32),
          CyButton(label: 'Créer l\'événement', onPressed: _submit, isLoading: _loading,
              icon: Icons.check_rounded),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _dateBtn(String label, DateTime? d, {required bool isStart}) {
    final hasDate = d != null;
    return GestureDetector(
      onTap: () => _pickDate(isStart: isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: hasDate ? CyColors.bordeauxBorder : CyColors.creamBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(),
              style: CyText.label(size: 10, color: CyColors.inkLight).copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 5),
          Text(
            hasDate
                ? '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}'
                : 'Choisir…',
            style: hasDate
                ? CyText.heading(size: 15, color: CyColors.bordeaux)
                : CyText.body(size: 15, color: CyColors.inkLight),
          ),
        ]),
      ),
    );
  }
}