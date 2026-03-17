import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../services/api_service.dart';
import '../../theme/cy_theme.dart';
import 'ticket_qr_screen.dart';

class TicketManagementScreen extends StatefulWidget {
  final EventModel event;
  const TicketManagementScreen({super.key, required this.event});
  @override
  State<TicketManagementScreen> createState() => _TicketManagementScreenState();
}

class _TicketManagementScreenState extends State<TicketManagementScreen> {
  List<dynamic> _tickets = [];
  bool _loading = true;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load({String search = ''}) async {
    setState(() => _loading = true);
    try {
      final t = await context.read<AppState>().api.getTickets(widget.event.id, search: search);
      setState(() { _tickets = t; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _adjust(Map<String, dynamic> t, int delta) async {
    try {
      final r = await context.read<AppState>().api.adjustDrinks(t['id'], delta);
      setState(() {
        final i = _tickets.indexWhere((x) => x['id'] == t['id']);
        if (i != -1) {
          _tickets[i] = Map<String,dynamic>.from(_tickets[i])
            ..['drinks_remaining'] = r['drinks_remaining']
            ..['drinks_total'] = r['drinks_total'];
        }
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: CyColors.errorMid));
    }
  }

  void _showActions(Map<String, dynamic> t) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white, useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => _ActionSheet(
        ticket: t, event: widget.event,
        onAdjust: (d) { Navigator.pop(context); _adjust(t, d); },
        onQR: () { Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => TicketQRScreen(ticket: t, event: widget.event)));
        },
      ),
    );
  }

  void _openCreate() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white, useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => _CreateModal(
        event: widget.event,
        onCreated: (t) {
          _load(search: _search);
          Navigator.push(context, MaterialPageRoute(builder: (_) => TicketQRScreen(ticket: t, event: widget.event)));
        },
      ),
    );
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
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Billets', style: CyText.heading(size: 16)),
          Text(widget.event.name, style: CyText.label(size: 11, color: CyColors.inkLight), overflow: TextOverflow.ellipsis),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: CyColors.inkLight, size: 20),
              onPressed: () => _load(search: _search)),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
            child: Container(height: 0.5, color: CyColors.creamBorder)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: CyColors.bordeaux, elevation: 2,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Billet manuel', style: CyText.label(size: 13, color: Colors.white)),
      ),
      body: Column(children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            style: CyText.body(size: 14, color: CyColors.inkDark),
            onChanged: (v) { _search = v; _load(search: v); },
            decoration: InputDecoration(
              hintText: 'Nom, email, référence…',
              prefixIcon: const Icon(Icons.search_rounded, color: CyColors.inkLight, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear_rounded, color: CyColors.inkLight, size: 18),
                  onPressed: () { _searchCtrl.clear(); _search = ''; _load(); })
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            ),
          ),
        ),
        if (!_loading) Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Align(alignment: Alignment.centerLeft,
              child: Text('${_tickets.length} billet(s)', style: CyText.label(size: 11, color: CyColors.inkLight))),
        ),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: CyColors.bordeaux, strokeWidth: 2))
            : _tickets.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.confirmation_number_outlined, color: CyColors.creamBorder, size: 48),
          const SizedBox(height: 12),
          Text(_search.isNotEmpty ? 'Aucun résultat' : 'Aucun billet',
              style: CyText.body(size: 14, color: CyColors.inkLight)),
        ]))
            : RefreshIndicator(
          onRefresh: () => _load(search: _search), color: CyColors.bordeaux,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            itemCount: _tickets.length,
            itemBuilder: (_, i) => _ticketRow(Map<String, dynamic>.from(_tickets[i])),
          ),
        )),
      ]),
    );
  }

  Widget _ticketRow(Map<String, dynamic> t) {
    final remaining = t['drinks_remaining'] as int;
    final total = t['drinks_total'] as int;
    final empty = remaining == 0;
    final ticketType = (t['ticket_type'] ?? '').toString();
    final manual = ticketType.toLowerCase() == 'manuel';
    final isStaff = ticketType.toLowerCase().contains('staff');
    final initials = _initials(t['holder_name']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CyCard(
        onTap: () => _showActions(t),
        child: Row(children: [
          // Avatar initiales
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: empty
                  ? CyColors.errorLight
                  : isStaff
                  ? const Color(0xFFEEF0FB)
                  : CyColors.bordeauxLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: empty
                  ? CyColors.errorMid.withOpacity(.2)
                  : isStaff
                  ? const Color(0xFF5B6BBF).withOpacity(.25)
                  : CyColors.bordeauxBorder),
            ),
            child: Center(child: Text(initials, style: CyText.heading(size: 14,
                color: empty
                    ? CyColors.errorMid
                    : isStaff
                    ? const Color(0xFF3D4FA8)
                    : CyColors.bordeaux))),
          ),
          const SizedBox(width: 12),

          // Infos
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(t['holder_name'] ?? 'Sans nom',
                  style: CyText.body(size: 13, color: CyColors.inkDark).copyWith(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis)),
              if (isStaff) Container(
                margin: const EdgeInsets.only(left: 5),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF0FB),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF5B6BBF).withOpacity(.35)),
                ),
                child: Text('STAFF', style: CyText.label(size: 9,
                    color: const Color(0xFF3D4FA8)).copyWith(letterSpacing: .8)),
              ),
              if (manual) Container(
                margin: const EdgeInsets.only(left: 5),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CyColors.goldLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: CyColors.goldBorder),
                ),
                child: Text('MANUEL', style: CyText.label(size: 9, color: CyColors.gold).copyWith(letterSpacing: .8)),
              ),
            ]),
            const SizedBox(height: 2),
            Text(t['reference'] ?? '', style: CyText.mono(size: 10, color: CyColors.inkLight),
                overflow: TextOverflow.ellipsis),
          ])),

          const SizedBox(width: 8),

          // Compteur + boutons
          Column(children: [
            Row(children: [
              Icon(Icons.wine_bar_rounded, size: 13,
                  color: empty ? CyColors.errorMid : CyColors.successMid),
              const SizedBox(width: 3),
              Text('$remaining/$total', style: CyText.body(size: 12,
                  color: empty ? CyColors.errorMid : CyColors.inkDark)
                  .copyWith(fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              _microBtn(Icons.remove_rounded, CyColors.errorMid,
                  remaining > 0 ? () => _adjust(t, -1) : null),
              const SizedBox(width: 4),
              _microBtn(Icons.add_rounded, CyColors.successMid, () => _adjust(t, 1)),
            ]),
          ]),
        ]),
      ),
    );
  }

  Widget _microBtn(IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          color: onTap != null ? color.withOpacity(0.1) : CyColors.creamDark,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: onTap != null ? color.withOpacity(0.3) : CyColors.creamBorder),
        ),
        child: Icon(icon, size: 13, color: onTap != null ? color : CyColors.inkLight),
      ),
    );
  }

  String _initials(dynamic name) {
    if (name == null || name.toString().isEmpty) return '?';
    final parts = name.toString().trim().split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.toString()[0].toUpperCase();
  }
}

// ─── BOTTOM SHEET ACTIONS ────────────────────────────────────────────────────

class _ActionSheet extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final EventModel event;
  final Function(int) onAdjust;
  final VoidCallback onQR;
  const _ActionSheet({required this.ticket, required this.event, required this.onAdjust, required this.onQR});

  @override
  Widget build(BuildContext context) {
    final remaining = ticket['drinks_remaining'] as int;
    final total = ticket['drinks_total'] as int;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: CyColors.creamBorder, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 18),
        Text(ticket['holder_name'] ?? 'Sans nom', style: CyText.heading(size: 18)),
        Text(ticket['reference'] ?? '', style: CyText.mono(size: 11, color: CyColors.inkLight)),
        const SizedBox(height: 16),
        // Compteur verres
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CyColors.cream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CyColors.creamBorder),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('VERRES RESTANTS', style: CyText.label(size: 10, color: CyColors.inkLight).copyWith(letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text('$remaining / $total', style: CyText.heading(size: 28,
                  color: remaining == 0 ? CyColors.errorMid : CyColors.bordeaux)),
            ]),
            Row(children: [
              _adjBtn(Icons.remove_rounded, CyColors.errorMid, remaining > 0 ? () => onAdjust(-1) : null),
              const SizedBox(width: 10),
              _adjBtn(Icons.add_rounded, CyColors.successMid, () => onAdjust(1)),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onQR,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              side: const BorderSide(color: CyColors.bordeauxBorder),
              foregroundColor: CyColors.bordeaux,
              backgroundColor: CyColors.bordeauxLight,
            ),
            icon: const Icon(Icons.qr_code_rounded, size: 18),
            label: Text('Voir / télécharger le QR code', style: CyText.label(size: 13, color: CyColors.bordeaux)),
          ),
        ),
      ]),
    );
  }

  Widget _adjBtn(IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: onTap != null ? color.withOpacity(0.1) : CyColors.creamDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: onTap != null ? color.withOpacity(0.3) : CyColors.creamBorder),
        ),
        child: Icon(icon, color: onTap != null ? color : CyColors.inkLight, size: 22),
      ),
    );
  }
}

// ─── MODAL CRÉATION BILLET ────────────────────────────────────────────────────

class _CreateModal extends StatefulWidget {
  final EventModel event;
  final Function(Map<String,dynamic>) onCreated;
  const _CreateModal({required this.event, required this.onCreated});
  @override
  State<_CreateModal> createState() => _CreateModalState();
}

class _CreateModalState extends State<_CreateModal> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _type = TextEditingController(text: 'Manuel');
  bool _customDrinks = false;
  int? _drinks;
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _name.dispose(); _email.dispose(); _type.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) { setState(() => _error = 'Le nom est obligatoire.'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final t = await context.read<AppState>().api.createManualTicket(widget.event.id, {
        'holder_name': _name.text.trim(),
        'holder_email': _email.text.trim().isEmpty ? null : _email.text.trim(),
        'ticket_type': _type.text.trim().isEmpty ? 'Manuel' : _type.text.trim(),
        'drinks_override': _customDrinks ? _drinks : null,
      });
      if (mounted) { Navigator.pop(context); widget.onCreated(t); }
    } catch (e) {
      setState(() { _error = 'Erreur : $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.event.drinksPerTicket;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: CyColors.creamBorder, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        const CySectionTitle('Nouveau billet manuel'),
        Text(widget.event.name, style: CyText.label(size: 12, color: CyColors.inkLight)),
        const SizedBox(height: 16),

        CyTextField(controller: _name, label: 'Nom complet *', icon: Icons.person_outline),
        const SizedBox(height: 10),
        CyTextField(controller: _email, label: 'Email (optionnel)', icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 10),
        CyTextField(controller: _type, label: 'Type de billet', icon: Icons.label_outline),
        const SizedBox(height: 12),

        Row(children: [
          Switch(value: _customDrinks, onChanged: (v) => setState(() {
            _customDrinks = v;
            if (v) _drinks = def;
          }), activeColor: CyColors.bordeaux),
          const SizedBox(width: 8),
          Text('Verres personnalisés', style: CyText.body(size: 13, color: CyColors.inkMid)),
        ]),

        if (_customDrinks) ...[
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
                onPressed: (_drinks ?? 1) > 0 ? () => setState(() => _drinks = (_drinks ?? 1) - 1) : null,
                icon: const Icon(Icons.remove_circle_outline, color: CyColors.bordeaux)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('${_drinks ?? def}', style: CyText.heading(size: 28, color: CyColors.bordeaux))),
            IconButton(
                onPressed: () => setState(() => _drinks = (_drinks ?? def) + 1),
                icon: const Icon(Icons.add_circle_outline, color: CyColors.bordeaux)),
          ]),
        ] else Padding(
          padding: const EdgeInsets.only(top: 4, left: 2),
          child: Text('Par défaut : $def verre(s)', style: CyText.label(size: 11, color: CyColors.inkLight)),
        ),

        if (_error != null) ...[
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: CyColors.errorLight, borderRadius: BorderRadius.circular(8)),
              child: Text(_error!, style: CyText.body(size: 12, color: CyColors.errorMid))),
        ],

        const SizedBox(height: 18),
        CyButton(label: 'Créer et voir le QR code', onPressed: _submit, isLoading: _loading,
            icon: Icons.qr_code_rounded),
      ]),
    );
  }
}