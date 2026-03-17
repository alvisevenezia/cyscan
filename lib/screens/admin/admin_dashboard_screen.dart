import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../services/api_service.dart';
import '../../theme/cy_theme.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';
import 'ticket_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<EventModel> _events = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final events = await context.read<AppState>().api.getEvents();
      setState(() { _events = events; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _confirmDelete(EventModel ev) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text('Supprimer ?', style: CyText.heading(size: 17)),
      content: Text('L\'événement "${ev.name}" et tous ses billets seront supprimés.',
          style: CyText.body(size: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: CyText.label(size: 14, color: CyColors.inkLight))),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await context.read<AppState>().api.deleteEvent(ev.id);
            _load();
          },
          child: Text('Supprimer', style: CyText.label(size: 14, color: CyColors.errorMid)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyColors.cream,
      appBar: AppBar(
        backgroundColor: CyColors.cream,
        title: const CyScanLogo(size: 20),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: CyColors.inkLight, size: 20),
              onPressed: _load),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: CyColors.inkLight, size: 20),
            onPressed: () async {
              await context.read<AppState>().logout();
              if (mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 0.5, color: CyColors.creamBorder),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEventScreen()));
          _load();
        },
        backgroundColor: CyColors.bordeaux,
        elevation: 2,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Nouvel événement', style: CyText.label(size: 13, color: Colors.white)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: CyColors.bordeaux, strokeWidth: 2));
    if (_error != null) return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, color: CyColors.inkLight, size: 40),
        const SizedBox(height: 12),
        Text(_error!, style: CyText.body(size: 13), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
      ]),
    );
    if (_events.isEmpty) return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 72, height: 72,
            decoration: BoxDecoration(color: CyColors.creamDark, shape: BoxShape.circle),
            child: const Icon(Icons.event_note_outlined, color: CyColors.inkLight, size: 32)),
        const SizedBox(height: 16),
        Text('Aucun événement', style: CyText.heading(size: 16, color: CyColors.inkMid)),
        const SizedBox(height: 6),
        Text('Créez votre premier événement\npour commencer à scanner.',
            style: CyText.body(size: 13, color: CyColors.inkLight), textAlign: TextAlign.center),
      ]),
    );
    return RefreshIndicator(
      onRefresh: _load, color: CyColors.bordeaux,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: _events.length,
        itemBuilder: (_, i) => _eventCard(_events[i]),
      ),
    );
  }

  Widget _eventCard(EventModel ev) {
    final now = DateTime.now();
    final start = DateTime.parse(ev.dateStart);
    final end = DateTime.parse(ev.dateEnd).add(const Duration(days: 1));
    final isActive = now.isAfter(start) && now.isBefore(end);
    final isPast = now.isAfter(end);

    final badge = isActive ? CyBadge.active() : isPast ? CyBadge.past() : CyBadge.upcoming();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CyCard(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => EventDetailScreen(event: ev))).then((_) => _load()),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(ev.name, style: CyText.heading(size: 15))),
            badge,
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 13, color: CyColors.inkLight),
            const SizedBox(width: 6),
            Text('${ev.dateStart}  →  ${ev.dateEnd}',
                style: CyText.body(size: 12, color: CyColors.inkLight)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            // Import CSV
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => EventDetailScreen(event: ev))).then((_) => _load()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  side: const BorderSide(color: CyColors.creamBorder),
                  foregroundColor: CyColors.inkMid,
                ),
                icon: const Icon(Icons.upload_file_outlined, size: 16),
                label: Text('Import CSV', style: CyText.label(size: 12, color: CyColors.inkMid)),
              ),
            ),
            const SizedBox(width: 8),
            // Billets
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => TicketManagementScreen(event: ev))).then((_) => _load()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  side: const BorderSide(color: CyColors.bordeauxBorder),
                  foregroundColor: CyColors.bordeaux,
                ),
                icon: const Icon(Icons.confirmation_number_outlined, size: 16),
                label: Text('Billets', style: CyText.label(size: 12, color: CyColors.bordeaux)),
              ),
            ),
            const SizedBox(width: 8),
            // Supprimer
            IconButton(
              onPressed: () => _confirmDelete(ev),
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: CyColors.inkLight),
              padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ]),
        ]),
      ),
    );
  }
}