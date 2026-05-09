import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/activity_service.dart';

// ─── Helpers ───────────────────────────────────────────────────────────────────

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'in_review': return AppColors.president;
    case 'approved':  return AppColors.primary;
    case 'rejected':  return AppColors.admin;
    default:          return AppColors.textMedium;
  }
}

String _statusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'in_review': return 'In Review';
    case 'approved':  return 'Approved';
    case 'rejected':  return 'Rejected';
    default:          return 'Draft';
  }
}

String _formatDate(Timestamp? ts) {
  if (ts == null) return 'Not set';
  final d = ts.toDate();
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

String _formatDateTime(Timestamp? ts) {
  if (ts == null) return 'Not submitted';
  final d = ts.toDate();
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

// ─── Committee: Proposals List Screen ─────────────────────────────────────────

class ProposalsScreen extends StatelessWidget {
  final String role;
  const ProposalsScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      primary: false,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('IEEE PES UTM',
                          style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500)),
                      Text('My Proposals',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                      Text('Manage your workshop proposals',
                          style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                    ],
                  ),
                  const Icon(Icons.description_outlined, color: AppColors.primary, size: 26),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Create button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreateProposalScreen())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Create New Proposal',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: uid == null
                  ? const Center(child: Text('Not logged in'))
                  : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('proposals')
                    .where('createdBy', isEqualTo: uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}',
                        style: const TextStyle(color: AppColors.textMedium)));
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.description_outlined, color: AppColors.textLight, size: 48),
                          SizedBox(height: 12),
                          Text('No proposals yet',
                              style: TextStyle(color: AppColors.textMedium, fontSize: 15, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4),
                          Text('Tap "Create New Proposal" to get started',
                              style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (c, i) {
                      final d      = docs[i].data() as Map<String, dynamic>;
                      final id     = docs[i].id;
                      final title  = d['title']  as String? ?? '(Untitled)';
                      final status = d['status'] as String? ?? 'draft';
                      final date   = _formatDateTime(d['submittedAt'] as Timestamp? ?? d['createdAt'] as Timestamp?);
                      return _ProposalCard(id: id, title: title, status: status, date: date);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Proposal Card ─────────────────────────────────────────────────────────────

class _ProposalCard extends StatelessWidget {
  final String id;
  final String title;
  final String status;
  final String date;
  const _ProposalCard({required this.id, required this.title, required this.status, required this.date});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ProposalDetailScreen(id: id))),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: _statusColor(status), width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StatusBadge(label: _statusLabel(status), color: _statusColor(status)),
                      const SizedBox(width: 10),
                      Text(date, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Committee: Proposal Detail Screen ────────────────────────────────────────

class ProposalDetailScreen extends StatefulWidget {
  final String id;
  const ProposalDetailScreen({super.key, required this.id});

  @override
  State<ProposalDetailScreen> createState() => _ProposalDetailScreenState();
}

class _ProposalDetailScreenState extends State<ProposalDetailScreen> {
  bool _generatingPdf = false;

  Future<void> _generatePdf(Map<String, dynamic> data) async {
    setState(() => _generatingPdf = true);
    try {
      final title    = data['title']          as String? ?? '';
      final desc     = data['description']    as String? ?? 'No description provided.';
      final obj      = data['objectives']     as String? ?? '';
      final loc      = data['location']       as String? ?? 'Not specified';
      final budget   = (data['budget'] as num?)?.toStringAsFixed(2) ?? '0.00';
      final maxPart  = data['maxParticipants']?.toString() ?? '50';
      final time     = data['time']           as String? ?? 'Not specified';
      final duration = data['duration']       as String? ?? 'Not specified';
      final audience = data['targetAudience'] as String? ?? 'Not specified';
      final isFree   = data['isFree']         as bool?   ?? true;
      final fee      = (data['fee'] as num?)?.toStringAsFixed(2) ?? '0.00';
      final dateStr  = _formatDate(data['date'] as Timestamp?);
      final status   = data['status']         as String? ?? 'draft';

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('IEEE PES UTM', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('26A69A'))),
                pw.Text('Workshop Proposal', style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
              ]),
              pw.SizedBox(height: 6),
              pw.Divider(color: PdfColor.fromHex('26A69A'), thickness: 2),
              pw.SizedBox(height: 16),

              // Title & status
              pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text('Status: ${_statusLabel(status)}  |  Event Date: $dateStr',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
              pw.SizedBox(height: 24),

              // Description
              pw.Text('Description', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text(desc, style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 16),

              if (obj.isNotEmpty) ...[
                pw.Text('Objectives', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text(obj, style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 16),
              ],

              // Details table
              pw.Text('Event Details', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                context: ctx,
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('E0F2F1')),
                headerHeight: 28,
                cellHeight: 26,
                cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerLeft},
                data: [
                  ['Field', 'Value'],
                  ['Location', loc],
                  ['Date', dateStr],
                  ['Time', time],
                  ['Duration', duration],
                  ['Target Audience', audience],
                  ['Max Participants', maxPart],
                  ['Budget (RM)', 'RM $budget'],
                  ['Registration', isFree ? 'Free' : 'RM $fee'],
                ],
              ),
              pw.Spacer(),
              pw.Divider(),
              pw.Center(child: pw.Text('IEEE PES UTM Student Branch © 2026',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey))),
            ],
          ),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: '$title.pdf',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('proposals').doc(widget.id).snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (!snap.hasData || !snap.data!.exists) {
              return const Center(child: Text('Proposal not found'));
            }
            final data   = snap.data!.data() as Map<String, dynamic>;
            final title  = data['title']  as String? ?? '(Untitled)';
            final status = data['status'] as String? ?? 'draft';
            final canEdit = status == 'draft';
            final statusColor = _statusColor(status);

            return Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('PROPOSAL STATUS',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(title,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Status card
                        _InfoCard(children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            StatusBadge(label: _statusLabel(status), color: statusColor),
                            Text(_formatDateTime(data['submittedAt'] as Timestamp? ?? data['createdAt'] as Timestamp?),
                                style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                          ]),
                          // Rejection reason
                          if (status == 'rejected') ...[
                            const SizedBox(height: 14),
                            const Divider(height: 1),
                            const SizedBox(height: 14),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Rejection Reason',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.admin)),
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(data['rejectionReason'] as String? ?? 'No reason provided.',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 16),

                        // Proposal details
                        _InfoCard(children: [
                          const Text('Proposal Details',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                          const SizedBox(height: 16),
                          _DetailRow(icon: Icons.title_outlined,         label: 'Title',           value: title),
                          _DetailRow(icon: Icons.location_on_outlined,   label: 'Location',        value: data['location'] as String? ?? '—'),
                          _DetailRow(icon: Icons.calendar_today_outlined, label: 'Event Date',     value: _formatDate(data['date'] as Timestamp?)),
                          _DetailRow(icon: Icons.access_time_outlined,   label: 'Time',            value: data['time'] as String? ?? '—'),
                          _DetailRow(icon: Icons.timelapse_outlined,     label: 'Duration',        value: data['duration'] as String? ?? '—'),
                          _DetailRow(icon: Icons.people_outline,         label: 'Target Audience', value: data['targetAudience'] as String? ?? '—'),
                          _DetailRow(icon: Icons.group_outlined,         label: 'Max Participants',value: data['maxParticipants']?.toString() ?? '—'),
                          _DetailRow(icon: Icons.account_balance_wallet_outlined, label: 'Budget', value: 'RM ${(data['budget'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                          _DetailRow(
                            icon: Icons.payments_outlined,
                            label: 'Registration',
                            value: (data['isFree'] as bool? ?? true)
                                ? 'Free'
                                : 'RM ${(data['fee'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                          ),
                          if ((data['description'] as String? ?? '').isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                            const SizedBox(height: 6),
                            Text(data['description'] as String? ?? '',
                                style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.5)),
                          ],
                          if ((data['objectives'] as String? ?? '').isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            const Text('Objectives', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                            const SizedBox(height: 6),
                            Text(data['objectives'] as String? ?? '',
                                style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.5)),
                          ],
                        ]),
                        const SizedBox(height: 16),

                        // Approval progress — president only
                        _InfoCard(children: [
                          const Text('Approval Progress',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                          const SizedBox(height: 20),
                          ApprovalStepTile(
                            title: 'Club President',
                            subtitle: status == 'approved'
                                ? 'Approved'
                                : status == 'rejected'
                                ? 'Rejected'
                                : status == 'in_review'
                                ? 'Awaiting review'
                                : 'Not yet submitted',
                            isCompleted: status == 'approved',
                            isLast: true,
                          ),
                        ]),
                        const SizedBox(height: 20),

                        // PDF button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _generatingPdf ? null : () => _generatePdf(data),
                            icon: _generatingPdf
                                ? const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.picture_as_pdf, size: 18),
                            label: const Text('View Proposal PDF'),
                          ),
                        ),

                        // Edit button — drafts only
                        if (canEdit) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => EditProposalScreen(id: widget.id))),
                              child: const Text('Edit Proposal'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Shared small widgets ──────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, size: 15, color: AppColors.textMedium),
      const SizedBox(width: 8),
      SizedBox(
        width: 120,
        child: Text('$label', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      ),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textMedium))),
    ]),
  );
}

// ─── Committee: Create Proposal Screen ────────────────────────────────────────

class CreateProposalScreen extends StatefulWidget {
  const CreateProposalScreen({super.key});

  @override
  State<CreateProposalScreen> createState() => _CreateProposalScreenState();
}

class _CreateProposalScreenState extends State<CreateProposalScreen> {
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _objectivesCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _budgetCtrl   = TextEditingController(text: '0.00');
  final _maxPartCtrl  = TextEditingController(text: '50');
  final _feeCtrl      = TextEditingController(text: '0.00');

  DateTime? _eventDate;
  TimeOfDay? _eventTime;
  String _duration       = 'Half Day (4 hrs)';
  String _targetAudience = 'IEEE Members';
  bool   _isFree         = true;
  bool   _saving         = false;

  static const _durations = [
    '1 Hour', '2 Hours', 'Half Day (4 hrs)', 'Full Day (8 hrs)', 'Multi-Day'
  ];
  static const _audiences = [
    'IEEE Members', 'UTM Students', 'Public', 'Postgraduate Only'
  ];

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _objectivesCtrl.dispose();
    _locationCtrl.dispose(); _budgetCtrl.dispose();
    _maxPartCtrl.dispose(); _feeCtrl.dispose();
    super.dispose();
  }

  Widget _sectionHeader(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 14, top: 6),
    child: Row(children: [
      Container(width: 3, height: 16, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
    ]),
  );

  Widget _label(String text, {bool required = true}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      if (required) const Text(' *', style: TextStyle(color: AppColors.admin, fontSize: 13)),
    ]),
  );

  Widget _field(TextEditingController ctrl, String hint,
      {int maxLines = 1, TextInputType? keyboardType}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
        decoration: InputDecoration(hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14)),
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _eventTime = picked);
  }

  bool _validate() {
    if (_titleCtrl.text.trim().isEmpty)    { _snack('Please enter a workshop title'); return false; }
    if (_descCtrl.text.trim().isEmpty)     { _snack('Please enter a description'); return false; }
    if (_locationCtrl.text.trim().isEmpty) { _snack('Please enter a location'); return false; }
    if (_eventDate == null)                { _snack('Please select an event date'); return false; }
    if (_eventTime == null)                { _snack('Please select an event time'); return false; }
    if (!_isFree && (double.tryParse(_feeCtrl.text) ?? 0) <= 0) {
      _snack('Please enter a valid registration fee'); return false;
    }
    return true;
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _submit({required bool asDraft}) async {
    if (!asDraft && !_validate()) return;
    if (asDraft && _titleCtrl.text.trim().isEmpty) {
      _snack('Please enter at least a title to save as draft'); return;
    }
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final eventTimestamp = _eventDate != null ? Timestamp.fromDate(_eventDate!) : null;
      final timeStr = _eventTime != null ? _eventTime!.format(context) : null;

      await FirebaseFirestore.instance.collection('proposals').add({
        'title':           _titleCtrl.text.trim(),
        'description':     _descCtrl.text.trim(),
        'objectives':      _objectivesCtrl.text.trim(),
        'location':        _locationCtrl.text.trim(),
        'budget':          double.tryParse(_budgetCtrl.text) ?? 0,
        'maxParticipants': int.tryParse(_maxPartCtrl.text) ?? 50,
        'date':            eventTimestamp,
        'time':            timeStr,
        'duration':        _duration,
        'targetAudience':  _targetAudience,
        'isFree':          _isFree,
        'fee':             _isFree ? 0 : (double.tryParse(_feeCtrl.text) ?? 0),
        'status':          asDraft ? 'draft' : 'in_review',
        'createdBy':       uid,
        'createdAt':       FieldValue.serverTimestamp(),
        'submittedAt':     asDraft ? null : FieldValue.serverTimestamp(),
      });
      if (!asDraft) await logActivity('Proposal submitted', _titleCtrl.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('CREATE PROPOSAL',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Workshop Proposal Form',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Basic Info ──────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _sectionHeader('Basic Information'),
                        _label('Workshop Title'),
                        _field(_titleCtrl, 'e.g., PCB Soldering Workshop'),
                        const SizedBox(height: 16),
                        _label('Description'),
                        _field(_descCtrl, 'What is this workshop about?', maxLines: 4),
                        const SizedBox(height: 16),
                        _label('Objectives', required: false),
                        _field(_objectivesCtrl, 'What will participants learn or achieve?', maxLines: 3),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // ── Event Details ───────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _sectionHeader('Event Details'),
                        _label('Location'),
                        _field(_locationCtrl, 'e.g., Engineering Lab 3, Block P19'),
                        const SizedBox(height: 16),

                        // Date + Time row
                        Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _label('Event Date'),
                              GestureDetector(
                                onTap: _pickDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.inputBg, borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(children: [
                                    const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMedium),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _eventDate != null
                                            ? '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}'
                                            : 'Select date',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _eventDate != null ? AppColors.textDark : AppColors.textLight,
                                        ),
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _label('Start Time'),
                              GestureDetector(
                                onTap: _pickTime,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.inputBg, borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(children: [
                                    const Icon(Icons.access_time_outlined, size: 16, color: AppColors.textMedium),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _eventTime != null ? _eventTime!.format(context) : 'Select time',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _eventTime != null ? AppColors.textDark : AppColors.textLight,
                                        ),
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                            ]),
                          ),
                        ]),
                        const SizedBox(height: 16),

                        // Duration
                        _label('Duration'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(12)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _duration,
                              isExpanded: true,
                              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                              items: _durations.map((d) =>
                                  DropdownMenuItem(value: d, child: Text(d))).toList(),
                              onChanged: (v) => setState(() => _duration = v!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Target audience
                        _label('Target Audience'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(12)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _targetAudience,
                              isExpanded: true,
                              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                              items: _audiences.map((a) =>
                                  DropdownMenuItem(value: a, child: Text(a))).toList(),
                              onChanged: (v) => setState(() => _targetAudience = v!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Max participants
                        _label('Max Participants'),
                        _field(_maxPartCtrl, '50', keyboardType: TextInputType.number),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // ── Budget & Registration ───────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _sectionHeader('Budget & Registration'),
                        _label('Estimated Budget (RM)'),
                        _field(_budgetCtrl, '0.00', keyboardType: TextInputType.number),
                        const SizedBox(height: 20),

                        // Registration fee toggle
                        Row(children: [
                          const Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Registration Fee', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                              SizedBox(height: 2),
                              Text('Will participants need to pay to join?',
                                  style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
                            ]),
                          ),
                          // Free / Paid toggle
                          Container(
                            decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(20)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              _toggleBtn('Free', _isFree, () => setState(() => _isFree = true)),
                              _toggleBtn('Paid', !_isFree, () => setState(() => _isFree = false)),
                            ]),
                          ),
                        ]),

                        // Fee amount — only shown when Paid
                        if (!_isFree) ...[
                          const SizedBox(height: 16),
                          _label('Fee Amount (RM)'),
                          _field(_feeCtrl, '0.00', keyboardType: TextInputType.number),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // ── Actions ─────────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : () => _submit(asDraft: false),
                        child: _saving
                            ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                            : const Text('Submit Proposal'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => _submit(asDraft: true),
                        child: const Text('Save as Draft'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textMedium,
            )),
      ),
    );
  }
}

// ─── Committee: Edit Proposal Screen ──────────────────────────────────────────

class EditProposalScreen extends StatefulWidget {
  final String id;
  const EditProposalScreen({super.key, required this.id});

  @override
  State<EditProposalScreen> createState() => _EditProposalScreenState();
}

class _EditProposalScreenState extends State<EditProposalScreen> {
  final _titleCtrl      = TextEditingController();
  final _descCtrl       = TextEditingController();
  final _objectivesCtrl = TextEditingController();
  final _locationCtrl   = TextEditingController();
  final _budgetCtrl     = TextEditingController();
  final _maxPartCtrl    = TextEditingController();
  final _feeCtrl        = TextEditingController();

  DateTime? _eventDate;
  TimeOfDay? _eventTime;
  String _duration       = 'Half Day (4 hrs)';
  String _targetAudience = 'IEEE Members';
  bool   _isFree         = true;
  bool   _saving         = false;
  bool   _loading        = true;

  static const _durations = ['1 Hour', '2 Hours', 'Half Day (4 hrs)', 'Full Day (8 hrs)', 'Multi-Day'];
  static const _audiences = ['IEEE Members', 'UTM Students', 'Public', 'Postgraduate Only'];

  @override
  void initState() { super.initState(); _loadData(); }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _objectivesCtrl.dispose();
    _locationCtrl.dispose(); _budgetCtrl.dispose(); _maxPartCtrl.dispose(); _feeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('proposals').doc(widget.id).get();
      if (doc.exists) {
        final d = doc.data()!;
        _titleCtrl.text      = d['title']          as String? ?? '';
        _descCtrl.text       = d['description']    as String? ?? '';
        _objectivesCtrl.text = d['objectives']     as String? ?? '';
        _locationCtrl.text   = d['location']       as String? ?? '';
        _budgetCtrl.text     = (d['budget'] as num?)?.toString() ?? '0.00';
        _maxPartCtrl.text    = (d['maxParticipants'] as num?)?.toString() ?? '50';
        _feeCtrl.text        = (d['fee'] as num?)?.toString() ?? '0.00';
        _isFree              = d['isFree'] as bool? ?? true;
        _duration            = _durations.contains(d['duration']) ? d['duration'] : _durations[2];
        _targetAudience      = _audiences.contains(d['targetAudience']) ? d['targetAudience'] : _audiences[0];
        final ts = d['date'] as Timestamp?;
        if (ts != null) _eventDate = ts.toDate();
        final timeStr = d['time'] as String?;
        if (timeStr != null) {
          // Parse stored time string back to TimeOfDay
          try {
            final parts = timeStr.split(':');
            _eventTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1].split(' ')[0]));
          } catch (_) {}
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  bool _validate() {
    if (_titleCtrl.text.trim().isEmpty)    { _snack('Please enter a title'); return false; }
    if (_descCtrl.text.trim().isEmpty)     { _snack('Please enter a description'); return false; }
    if (_locationCtrl.text.trim().isEmpty) { _snack('Please enter a location'); return false; }
    if (_eventDate == null)                { _snack('Please select an event date'); return false; }
    if (_eventTime == null)                { _snack('Please select an event time'); return false; }
    if (!_isFree && (double.tryParse(_feeCtrl.text) ?? 0) <= 0) {
      _snack('Please enter a valid registration fee'); return false;
    }
    return true;
  }

  Map<String, dynamic> _buildPayload({required String status}) => {
    'title':           _titleCtrl.text.trim(),
    'description':     _descCtrl.text.trim(),
    'objectives':      _objectivesCtrl.text.trim(),
    'location':        _locationCtrl.text.trim(),
    'budget':          double.tryParse(_budgetCtrl.text) ?? 0,
    'maxParticipants': int.tryParse(_maxPartCtrl.text) ?? 50,
    'date':            _eventDate != null ? Timestamp.fromDate(_eventDate!) : null,
    'time':            _eventTime != null ? _eventTime!.format(context) : null,
    'duration':        _duration,
    'targetAudience':  _targetAudience,
    'isFree':          _isFree,
    'fee':             _isFree ? 0 : (double.tryParse(_feeCtrl.text) ?? 0),
    'status':          status,
  };

  Future<void> _saveAsDraft() async {
    if (_titleCtrl.text.trim().isEmpty) { _snack('Please enter at least a title'); return; }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('proposals').doc(widget.id)
          .update(_buildPayload(status: 'draft'));
      if (mounted) { _snack('Draft saved'); Navigator.pop(context); }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitProposal() async {
    if (!_validate()) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Proposal'),
        content: const Text('Once submitted, you will no longer be able to edit this proposal. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('proposals').doc(widget.id)
          .update({..._buildPayload(status: 'in_review'), 'submittedAt': FieldValue.serverTimestamp()});
      await logActivity('Proposal submitted', _titleCtrl.text.trim());
      if (mounted) {
        _snack('Proposal submitted for review');
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _eventTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _eventTime = picked);
  }

  Widget _sectionHeader(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 14, top: 6),
    child: Row(children: [
      Container(width: 3, height: 16, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
    ]),
  );

  Widget _label(String text, {bool req = true}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      if (req) const Text(' *', style: TextStyle(color: AppColors.admin, fontSize: 13)),
    ]),
  );

  Widget _field(TextEditingController ctrl, String hint,
      {int maxLines = 1, TextInputType? keyboardType}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
        decoration: InputDecoration(hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14)),
      );

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.textMedium)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('EDIT PROPOSAL',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Update Workshop Details',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Basic Info
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _sectionHeader('Basic Information'),
                      _label('Workshop Title'),
                      _field(_titleCtrl, 'e.g., PCB Soldering Workshop'),
                      const SizedBox(height: 16),
                      _label('Description'),
                      _field(_descCtrl, 'What is this workshop about?', maxLines: 4),
                      const SizedBox(height: 16),
                      _label('Objectives', req: false),
                      _field(_objectivesCtrl, 'What will participants learn?', maxLines: 3),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Event Details
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _sectionHeader('Event Details'),
                      _label('Location'),
                      _field(_locationCtrl, 'e.g., Engineering Lab 3'),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _label('Event Date'),
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(12)),
                              child: Row(children: [
                                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMedium),
                                const SizedBox(width: 8),
                                Text(
                                  _eventDate != null ? '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}' : 'Select date',
                                  style: TextStyle(fontSize: 13, color: _eventDate != null ? AppColors.textDark : AppColors.textLight),
                                ),
                              ]),
                            ),
                          ),
                        ])),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _label('Start Time'),
                          GestureDetector(
                            onTap: _pickTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(12)),
                              child: Row(children: [
                                const Icon(Icons.access_time_outlined, size: 16, color: AppColors.textMedium),
                                const SizedBox(width: 8),
                                Text(
                                  _eventTime != null ? _eventTime!.format(context) : 'Select time',
                                  style: TextStyle(fontSize: 13, color: _eventTime != null ? AppColors.textDark : AppColors.textLight),
                                ),
                              ]),
                            ),
                          ),
                        ])),
                      ]),
                      const SizedBox(height: 16),
                      _label('Duration'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _duration, isExpanded: true,
                            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                            items: _durations.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                            onChanged: (v) => setState(() => _duration = v!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _label('Target Audience'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _targetAudience, isExpanded: true,
                            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                            items: _audiences.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                            onChanged: (v) => setState(() => _targetAudience = v!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _label('Max Participants'),
                      _field(_maxPartCtrl, '50', keyboardType: TextInputType.number),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Budget & Registration
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _sectionHeader('Budget & Registration'),
                      _label('Estimated Budget (RM)'),
                      _field(_budgetCtrl, '0.00', keyboardType: TextInputType.number),
                      const SizedBox(height: 20),
                      Row(children: [
                        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Registration Fee', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                          SizedBox(height: 2),
                          Text('Will participants need to pay?', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
                        ])),
                        Container(
                          decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(20)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            _toggleBtn('Free', _isFree, () => setState(() => _isFree = true)),
                            _toggleBtn('Paid', !_isFree, () => setState(() => _isFree = false)),
                          ]),
                        ),
                      ]),
                      if (!_isFree) ...[
                        const SizedBox(height: 16),
                        _label('Fee Amount (RM)'),
                        _field(_feeCtrl, '0.00', keyboardType: TextInputType.number),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submitProposal,
                      child: _saving
                          ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                          : const Text('Submit Proposal'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _saving ? null : _saveAsDraft,
                      child: const Text('Save as Draft'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── President: All Proposals Screen ──────────────────────────────────────────

class PresidentProposalsScreen extends StatefulWidget {
  const PresidentProposalsScreen({super.key});

  @override
  State<PresidentProposalsScreen> createState() => _PresidentProposalsScreenState();
}

class _PresidentProposalsScreenState extends State<PresidentProposalsScreen> {
  String _filter = 'in_review';

  static const _filters = [
    ('In Review', 'in_review'),
    ('Approved',  'approved'),
    ('Rejected',  'rejected'),
    ('All',       'all'),
  ];

  Query<Map<String, dynamic>> get _query {
    final base = FirebaseFirestore.instance.collection('proposals');
    if (_filter == 'all') {
      return base
          .where('status', whereIn: ['in_review', 'approved', 'rejected'])
          .orderBy('createdAt', descending: true);
    }
    return base
        .where('status', isEqualTo: _filter)
        .orderBy('createdAt', descending: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      primary: false,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('IEEE PES UTM',
                        style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500)),
                    Text('Proposals',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    Text('Review and approve submissions',
                        style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                  ]),
                  const Icon(Icons.how_to_vote_outlined, color: AppColors.president, size: 26),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _filters.map((f) {
                  final isSelected = _filter == f.$2;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f.$2),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.president : AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? AppColors.president : AppColors.textLight.withValues(alpha: 0.3)),
                          boxShadow: isSelected
                              ? [BoxShadow(color: AppColors.president.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                              : [],
                        ),
                        child: Text(f.$1,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.textMedium)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _query.snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.president));
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.inbox_outlined, color: AppColors.textLight, size: 48),
                        const SizedBox(height: 12),
                        Text(_filter == 'in_review' ? 'No proposals awaiting review' : 'No proposals found',
                            style: const TextStyle(color: AppColors.textMedium, fontSize: 15, fontWeight: FontWeight.w600)),
                      ]),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (c, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      return _PresidentProposalCard(id: docs[i].id, data: d);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── President Proposal Card ───────────────────────────────────────────────────

class _PresidentProposalCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  const _PresidentProposalCard({required this.id, required this.data});

  @override
  Widget build(BuildContext context) {
    final title  = data['title']  as String? ?? '(Untitled)';
    final status = data['status'] as String? ?? 'draft';
    final date   = _formatDateTime(data['submittedAt'] as Timestamp? ?? data['createdAt'] as Timestamp?);
    final budget = (data['budget'] as num?)?.toStringAsFixed(2) ?? '0.00';
    final isFree = data['isFree'] as bool? ?? true;
    final fee    = (data['fee'] as num?)?.toStringAsFixed(2) ?? '0.00';
    final createdBy = data['createdBy'] as String? ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => PresidentProposalDetailScreen(id: id, data: data))),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: _statusColor(status), width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Title + status badge
          Row(children: [
            Expanded(child: Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark))),
            StatusBadge(label: _statusLabel(status), color: _statusColor(status)),
          ]),
          const SizedBox(height: 10),

          // Submitter info — fetched live
          _SubmitterRow(uid: createdBy),
          const SizedBox(height: 8),

          // Meta row
          Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMedium),
            const SizedBox(width: 4),
            Text(date, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
            const Spacer(),
            const Icon(Icons.account_balance_wallet_outlined, size: 13, color: AppColors.textMedium),
            const SizedBox(width: 4),
            Text('RM $budget', style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isFree
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.student.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(isFree ? 'Free' : 'RM $fee',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: isFree ? AppColors.primary : AppColors.student)),
            ),
          ]),

          // Approve / Reject inline for in_review only
          if (status == 'in_review') ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(context),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.admin,
                    side: BorderSide(color: AppColors.admin.withValues(alpha: 0.5)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approve(context),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  Future<void> _approve(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Proposal'),
        content: const Text('Approving will automatically create an event visible to all students. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Approve')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final batch = FirebaseFirestore.instance.batch();

      batch.update(
        FirebaseFirestore.instance.collection('proposals').doc(id),
        {'status': 'approved', 'approvedAt': FieldValue.serverTimestamp()},
      );

      // Auto-create event — maps all detailed fields for student view
      final eventRef = FirebaseFirestore.instance.collection('events').doc();
      batch.set(eventRef, {
        'title':           data['title']          ?? '',
        'description':     data['description']    ?? '',
        'objectives':      data['objectives']     ?? '',
        'location':        data['location']       ?? '',
        'date':            data['date'],
        'time':            data['time']           ?? '',
        'duration':        data['duration']       ?? '',
        'targetAudience':  data['targetAudience'] ?? '',
        'maxParticipants': data['maxParticipants'] ?? 50,
        'budget':          data['budget']         ?? 0,
        'isFree':          data['isFree']         ?? true,
        'fee':             data['fee']            ?? 0,
        'status':          'upcoming',
        'proposalId':      id,
        'createdBy':       data['createdBy'],
        'createdAt':       FieldValue.serverTimestamp(),
        'registrationCount': 0,
      });

      await batch.commit();
      await logActivity('Proposal approved', '${data['title']} — event created');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Proposal approved and event created')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showRejectDialog(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Proposal'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Provide a reason for rejection (optional):'),
          const SizedBox(height: 12),
          TextField(
            controller: reasonCtrl, maxLines: 3,
            decoration: const InputDecoration(
                hintText: 'e.g., Budget exceeds limit...', border: OutlineInputBorder()),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.admin),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await FirebaseFirestore.instance.collection('proposals').doc(id).update({
        'status': 'rejected',
        'rejectionReason': reasonCtrl.text.trim(),
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      await logActivity('Proposal rejected', data['title'] ?? '');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proposal rejected')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

// Fetches submitter's fullName + faculty from users collection
class _SubmitterRow extends StatelessWidget {
  final String uid;
  const _SubmitterRow({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (ctx, snap) {
        String name    = '—';
        String faculty = '';
        String initial = '?';
        if (snap.hasData && snap.data!.exists) {
          final u = snap.data!.data() as Map<String, dynamic>;
          name    = u['fullName']  as String? ?? u['email'] as String? ?? '—';
          faculty = u['faculty']   as String? ?? '';
          initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
        }
        return Row(children: [
          // Avatar with initial
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.president.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(initial,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.president)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              if (faculty.isNotEmpty)
                Text(faculty, style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
            ]),
          ),
        ]);
      },
    );
  }
}

// ─── President: Proposal Detail Screen ────────────────────────────────────────

class PresidentProposalDetailScreen extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  const PresidentProposalDetailScreen({super.key, required this.id, required this.data});

  @override
  Widget build(BuildContext context) {
    final title  = data['title']  as String? ?? '(Untitled)';
    final status = data['status'] as String? ?? 'draft';
    final isFree = data['isFree'] as bool? ?? true;
    final fee    = (data['fee'] as num?)?.toStringAsFixed(2) ?? '0.00';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: const BoxDecoration(
                color: AppColors.president,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('PROPOSAL REVIEW',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(title,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500)),
              ]),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Status + submitter
                  _InfoCard(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      StatusBadge(label: _statusLabel(status), color: _statusColor(status)),
                      Text(_formatDateTime(data['submittedAt'] as Timestamp? ?? data['createdAt'] as Timestamp?),
                          style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                    ]),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    const Text('Submitted By',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
                    const SizedBox(height: 8),
                    _SubmitterDetail(uid: data['createdBy'] as String? ?? ''),
                  ]),
                  const SizedBox(height: 16),

                  // Proposal details
                  _InfoCard(children: [
                    const Text('Proposal Details',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    const SizedBox(height: 16),
                    _DetailRow(icon: Icons.location_on_outlined,   label: 'Location',         value: data['location'] as String? ?? '—'),
                    _DetailRow(icon: Icons.calendar_today_outlined, label: 'Event Date',       value: _formatDate(data['date'] as Timestamp?)),
                    _DetailRow(icon: Icons.access_time_outlined,   label: 'Time',             value: data['time'] as String? ?? '—'),
                    _DetailRow(icon: Icons.timelapse_outlined,     label: 'Duration',         value: data['duration'] as String? ?? '—'),
                    _DetailRow(icon: Icons.people_outline,         label: 'Audience',         value: data['targetAudience'] as String? ?? '—'),
                    _DetailRow(icon: Icons.group_outlined,         label: 'Max Participants', value: data['maxParticipants']?.toString() ?? '—'),
                    _DetailRow(icon: Icons.account_balance_wallet_outlined, label: 'Budget',  value: 'RM ${(data['budget'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                    _DetailRow(icon: Icons.payments_outlined,      label: 'Registration',     value: isFree ? 'Free' : 'RM $fee'),
                    if ((data['description'] as String? ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10), const Divider(height: 1), const SizedBox(height: 10),
                      const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      const SizedBox(height: 6),
                      Text(data['description'] as String? ?? '',
                          style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.5)),
                    ],
                    if ((data['objectives'] as String? ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10), const Divider(height: 1), const SizedBox(height: 10),
                      const Text('Objectives', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      const SizedBox(height: 6),
                      Text(data['objectives'] as String? ?? '',
                          style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.5)),
                    ],
                  ]),

                  // Rejection reason
                  if (status == 'rejected') ...[
                    const SizedBox(height: 16),
                    _InfoCard(children: [
                      const Text('Rejection Reason',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.admin)),
                      const SizedBox(height: 8),
                      Text(data['rejectionReason'] as String? ?? 'No reason provided.',
                          style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
                    ]),
                  ],

                  // Action buttons — in_review only
                  if (status == 'in_review') ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _PresidentProposalCard(id: id, data: data)._approve(context),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Approve & Create Event'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _PresidentProposalCard(id: id, data: data)._showRejectDialog(context),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Reject Proposal'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.admin,
                            side: BorderSide(color: AppColors.admin.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Full submitter detail widget used in the detail screen
class _SubmitterDetail extends StatelessWidget {
  final String uid;
  const _SubmitterDetail({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return const Text('Unknown', style: TextStyle(color: AppColors.textMedium));
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 20, width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.president));
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const Text('Unknown user', style: TextStyle(color: AppColors.textMedium, fontSize: 13));
        }
        final u        = snap.data!.data() as Map<String, dynamic>;
        final name     = u['fullName']     as String? ?? '—';
        final email    = u['email']        as String? ?? '—';
        final faculty  = u['faculty']      as String? ?? '—';
        final matrixId = u['matrixId']     as String? ?? '—';
        final phone    = u['phoneNumber']  as String? ?? '—';
        final initial  = name.isNotEmpty ? name[0].toUpperCase() : '?';

        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.president.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(initial,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.president)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 2),
              Text(email, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 6, children: [
                _InfoChip(icon: Icons.badge_outlined,    label: matrixId),
                _InfoChip(icon: Icons.school_outlined,   label: faculty),
                _InfoChip(icon: Icons.phone_outlined,    label: phone),
              ]),
            ]),
          ),
        ]);
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.inputBg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: AppColors.textMedium),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textDark, fontWeight: FontWeight.w500)),
    ]),
  );
}