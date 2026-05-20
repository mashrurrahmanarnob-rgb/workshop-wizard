import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:signature/signature.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/activity_service.dart';

// ─── Helpers ───────────────────────────────────────────────────────────────────

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'in_review': return AppColors.president;
    case 'approved':  return AppColors.primary;
    case 'rejected':  return AppColors.admin;
    default:          return AppColors.textMedium; // draft
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

String _formatSubmittedAt(Timestamp? ts) {
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
                    boxShadow: [BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 12, offset: const Offset(0, 4))],
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
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (c, i) {
                      final d      = docs[i].data() as Map<String, dynamic>;
                      final id     = docs[i].id;
                      final title  = d['title']  as String? ?? '(Untitled)';
                      final status = d['status'] as String? ?? 'draft';
                      final date   = _formatSubmittedAt(
                          d['submittedAt'] as Timestamp? ?? d['createdAt'] as Timestamp?);
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
  final String id, title, status, date;
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
                  Text(title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Row(children: [
                    StatusBadge(label: _statusLabel(status), color: _statusColor(status)),
                    const SizedBox(width: 10),
                    Text(date, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                  ]),
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
  bool _deleting = false;

  Future<void> _generatePdf(Map<String, dynamic> data) async {
    setState(() => _generatingPdf = true);
    try {
      final title    = data['title']          as String? ?? '';
      final desc     = data['description']    as String? ?? '';
      final obj      = data['objectives']     as String? ?? '';
      final loc      = data['location']       as String? ?? '';
      final budget   = (data['budget'] as num?)?.toStringAsFixed(2) ?? '0.00';
      final maxPart  = data['maxParticipants']?.toString() ?? '—';
      final time     = data['time']           as String? ?? '—';
      final duration = data['duration']       as String? ?? '—';
      final audience = data['targetAudience'] as String? ?? '—';
      final dateStr  = _formatDate(data['date'] as Timestamp?);
      final status   = data['status']         as String? ?? 'draft';
      final sigB64   = data['signature']      as String?;
      final isFree   = data['isFree']         as bool? ?? true;
      final fee      = (data['fee'] as num?)?.toStringAsFixed(2) ?? '0.00';

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context ctx) => [
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('IEEE PES UTM',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('4CAF50'))),
              pw.Text('Workshop Proposal',
                  style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
            ]),
            pw.SizedBox(height: 4),
            pw.Divider(color: PdfColor.fromHex('4CAF50'), thickness: 2),
            pw.SizedBox(height: 16),
            pw.Text(title,
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Status: ${_statusLabel(status)}  |  Date: $dateStr',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
            pw.SizedBox(height: 24),
            pw.Text('Description',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text(desc, style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 16),
            if (obj.isNotEmpty) ...[
              pw.Text('Learning Objectives',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text(obj, style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 16),
            ],
            pw.Text('Event Details',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              context: ctx,
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('E8F5E9')),
              headerHeight: 28, cellHeight: 26,
              cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerLeft},
              data: [
                ['Field', 'Value'],
                ['Location', loc],
                ['Date', dateStr],
                ['Time', time],
                ['Duration', duration],
                ['Target Audience', audience],
                ['Expected Participants', maxPart],
                ['Estimated Budget (RM)', 'RM $budget'],
                ['Registration Fee', isFree ? 'Free' : 'RM $fee'],
              ],
            ),
            if (sigB64 != null) ...[
              pw.SizedBox(height: 24),
              pw.Text('Digital Signature',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Container(
                height: 80, width: 200,
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                child: pw.Image(pw.MemoryImage(base64Decode(sigB64))),
              ),
              pw.SizedBox(height: 4),
              pw.Text('Submitter\'s Digital Signature',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ],
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Center(child: pw.Text('IEEE PES UTM Student Branch © 2026',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey))),
          ],
        ),
      );
      await Printing.layoutPdf(onLayout: (_) async => pdf.save(), name: '$title.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  Future<void> _deleteProposal(String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Proposal'),
        content: Text('Are you sure you want to delete "$title"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.admin),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _deleting = true);
    try {
      await FirebaseFirestore.instance.collection('proposals').doc(widget.id).delete();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('proposals').doc(widget.id).snapshots(),
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
            final isDraft = status == 'draft';
            final isFree  = data['isFree'] as bool? ?? true;
            final fee     = (data['fee'] as num?)?.toStringAsFixed(2) ?? '0.00';

            return Column(children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      // Delete — drafts only
                      if (isDraft)
                        GestureDetector(
                          onTap: _deleting ? null : () => _deleteProposal(title),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10)),
                            child: _deleting
                                ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('PROPOSAL STATUS',
                      style: TextStyle(color: Colors.white, fontSize: 18,
                          fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(title,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13, fontWeight: FontWeight.w500)),
                ]),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [

                    // Status card
                    _InfoCard(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        StatusBadge(label: _statusLabel(status), color: _statusColor(status)),
                        Text(_formatSubmittedAt(
                            data['submittedAt'] as Timestamp? ?? data['createdAt'] as Timestamp?),
                            style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                      ]),
                      if (status == 'rejected') ...[
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        const Align(alignment: Alignment.centerLeft,
                            child: Text('Rejection Reason',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.admin))),
                        const SizedBox(height: 6),
                        Align(alignment: Alignment.centerLeft,
                            child: Text(data['rejectionReason'] as String? ?? 'No reason provided.',
                                style: const TextStyle(fontSize: 13, color: AppColors.textDark))),
                      ],
                    ]),
                    const SizedBox(height: 16),

                    // Details card
                    _InfoCard(children: [
                      const Text('Proposal Details',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      const SizedBox(height: 16),
                      _DetailRow(icon: Icons.title_outlined,                  label: 'Title',                value: title),
                      _DetailRow(icon: Icons.location_on_outlined,            label: 'Location',             value: data['location'] as String? ?? '—'),
                      _DetailRow(icon: Icons.calendar_today_outlined,         label: 'Event Date',           value: _formatDate(data['date'] as Timestamp?)),
                      _DetailRow(icon: Icons.access_time_outlined,            label: 'Time',                 value: data['time'] as String? ?? '—'),
                      _DetailRow(icon: Icons.timelapse_outlined,              label: 'Duration',             value: data['duration'] as String? ?? '—'),
                      _DetailRow(icon: Icons.people_outline,                  label: 'Target Audience',      value: data['targetAudience'] as String? ?? '—'),
                      _DetailRow(icon: Icons.group_outlined,                  label: 'Exp. Participants',    value: data['maxParticipants']?.toString() ?? '—'),
                      _DetailRow(icon: Icons.account_balance_wallet_outlined, label: 'Budget',               value: 'RM ${(data['budget'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                      _DetailRow(
                        icon: isFree ? Icons.card_giftcard_outlined : Icons.attach_money_outlined,
                        label: 'Registration Fee',
                        value: isFree ? 'Free' : 'RM $fee',
                      ),
                      if ((data['description'] as String? ?? '').isNotEmpty) ...[
                        const SizedBox(height: 10), const Divider(height: 1), const SizedBox(height: 10),
                        const Text('Description',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        const SizedBox(height: 6),
                        Text(data['description'] as String? ?? '',
                            style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.5)),
                      ],
                      if ((data['objectives'] as String? ?? '').isNotEmpty) ...[
                        const SizedBox(height: 10), const Divider(height: 1), const SizedBox(height: 10),
                        const Text('Learning Objectives',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        const SizedBox(height: 6),
                        Text(data['objectives'] as String? ?? '',
                            style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.5)),
                      ],
                      // Signature preview
                      if (data['signature'] != null) ...[
                        const SizedBox(height: 10), const Divider(height: 1), const SizedBox(height: 10),
                        const Text('Digital Signature',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        const SizedBox(height: 8),
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.divider),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              base64Decode(data['signature'] as String),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 16),

                    // Approval progress
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

                    // Edit — drafts only
                    if (isDraft) ...[
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
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

// ─── Shared card / row widgets ─────────────────────────────────────────────────

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
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, size: 15, color: AppColors.textMedium),
      const SizedBox(width: 8),
      SizedBox(width: 130,
          child: Text(label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark))),
      Expanded(child: Text(value,
          style: const TextStyle(fontSize: 13, color: AppColors.textMedium))),
    ]),
  );
}

// ─── Shared form helpers ───────────────────────────────────────────────────────

Widget _sectionHeader(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 14, top: 6),
  child: Row(children: [
    Container(width: 3, height: 16,
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
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
    {int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator}) =>
    TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
      decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14)),
      validator: validator,
    );

Widget _datePickerWidget(BuildContext context, DateTime? value, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMedium),
          const SizedBox(width: 8),
          Text(
            value != null ? '${value.day}/${value.month}/${value.year}' : 'Select date',
            style: TextStyle(fontSize: 13,
                color: value != null ? AppColors.textDark : AppColors.textLight),
          ),
        ]),
      ),
    );

Widget _timePickerWidget(BuildContext context, TimeOfDay? value, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.access_time_outlined, size: 16, color: AppColors.textMedium),
          const SizedBox(width: 8),
          Text(
            value != null ? value.format(context) : 'Select time',
            style: TextStyle(fontSize: 13,
                color: value != null ? AppColors.textDark : AppColors.textLight),
          ),
        ]),
      ),
    );

Widget _buildSignaturePad(SignatureController ctrl) => Container(
  decoration: BoxDecoration(
    color: AppColors.cardWhite,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 10, offset: const Offset(0, 4))],
  ),
  padding: const EdgeInsets.all(20),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionHeader('Digital Signature'),
    _label('Sign below'),
    const SizedBox(height: 4),
    Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.edit_note, size: 16, color: AppColors.textMedium),
            SizedBox(width: 8),
            Text('Sign with your finger or mouse',
                style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
          ]),
        ),
        Signature(controller: ctrl, height: 150, backgroundColor: Colors.white),
      ]),
    ),
  ]),
);

// ─── Reusable Registration Fee Toggle Widget ───────────────────────────────────

class _RegistrationFeeCard extends StatelessWidget {
  final bool isFree;
  final TextEditingController feeCtrl;
  final ValueChanged<bool> onToggle;

  const _RegistrationFeeCard({
    required this.isFree,
    required this.feeCtrl,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return _InfoCard(children: [
      _sectionHeader('Registration Fee'),
      _label('Fee Type', required: false),
      const SizedBox(height: 4),
      Row(children: [
        // Free toggle button
        Expanded(
          child: GestureDetector(
            onTap: () => onToggle(true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isFree ? AppColors.primary : AppColors.inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFree
                      ? AppColors.primary
                      : AppColors.textLight.withValues(alpha: 0.3),
                ),
                boxShadow: isFree
                    ? [BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2))]
                    : [],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.card_giftcard_outlined,
                    size: 16,
                    color: isFree ? Colors.white : AppColors.textMedium),
                const SizedBox(width: 6),
                Text('Free',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isFree ? Colors.white : AppColors.textMedium)),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Paid toggle button
        Expanded(
          child: GestureDetector(
            onTap: () => onToggle(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: !isFree ? AppColors.primary : AppColors.inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !isFree
                      ? AppColors.primary
                      : AppColors.textLight.withValues(alpha: 0.3),
                ),
                boxShadow: !isFree
                    ? [BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2))]
                    : [],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.attach_money_outlined,
                    size: 16,
                    color: !isFree ? Colors.white : AppColors.textMedium),
                const SizedBox(width: 6),
                Text('Paid',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: !isFree ? Colors.white : AppColors.textMedium)),
              ]),
            ),
          ),
        ),
      ]),

      // Fee amount field — only shown when Paid is selected
      if (!isFree) ...[
        const SizedBox(height: 16),
        _label('Fee Amount (RM)'),
        _field(
          feeCtrl,
          'e.g., 10.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            if (isFree) return null;
            if (v == null || v.trim().isEmpty) return 'Required';
            final parsed = double.tryParse(v);
            if (parsed == null || parsed <= 0) return 'Enter a valid amount greater than 0';
            return null;
          },
        ),
      ],
    ]);
  }
}

// ─── Committee: Create Proposal Screen ────────────────────────────────────────

class CreateProposalScreen extends StatefulWidget {
  const CreateProposalScreen({super.key});

  @override
  State<CreateProposalScreen> createState() => _CreateProposalScreenState();
}

class _CreateProposalScreenState extends State<CreateProposalScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl        = TextEditingController();
  final _descCtrl         = TextEditingController();
  final _objectivesCtrl   = TextEditingController();
  final _audienceCtrl     = TextEditingController();
  final _durationCtrl     = TextEditingController();
  final _locationCtrl     = TextEditingController();
  final _participantsCtrl = TextEditingController();
  final _budgetCtrl       = TextEditingController(text: '0.00');
  final _feeCtrl          = TextEditingController(text: '0.00');

  DateTime?  _eventDate;
  TimeOfDay? _eventTime;
  bool       _saving = false;
  bool       _isFree = true;

  final SignatureController _sigCtrl = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _objectivesCtrl.dispose();
    _audienceCtrl.dispose(); _durationCtrl.dispose(); _locationCtrl.dispose();
    _participantsCtrl.dispose(); _budgetCtrl.dispose();
    _feeCtrl.dispose(); _sigCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // Full validation — required for submit
  bool _validateForSubmit() {
    if (!_formKey.currentState!.validate()) return false;
    if (_eventDate == null || _eventTime == null) {
      _snack('Please select a date and time'); return false;
    }
    if (_sigCtrl.isEmpty) {
      _snack('Signature is required to submit'); return false;
    }
    return true;
  }

  // Minimal validation — only title required for draft
  bool _validateForDraft() {
    if (_titleCtrl.text.trim().isEmpty) {
      _snack('Please enter at least a title to save as draft'); return false;
    }
    return true;
  }

  Future<void> _submit({required bool asDraft}) async {
    if (asDraft) {
      if (!_validateForDraft()) return;
    } else {
      if (!_validateForSubmit()) return;
    }

    final timeStr = _eventTime?.format(context);
    setState(() => _saving = true);
    try {
      String? sigBase64;
      if (!asDraft && _sigCtrl.isNotEmpty) {
        final sigBytes = await _sigCtrl.toPngBytes();
        if (sigBytes != null) sigBase64 = base64Encode(sigBytes);
      }
      final uid   = FirebaseAuth.instance.currentUser!.uid;
      final email = FirebaseAuth.instance.currentUser!.email ?? '';
      final combinedDate = _eventDate != null && _eventTime != null
          ? Timestamp.fromDate(DateTime(
          _eventDate!.year, _eventDate!.month, _eventDate!.day,
          _eventTime!.hour, _eventTime!.minute))
          : (_eventDate != null ? Timestamp.fromDate(_eventDate!) : null);

      await FirebaseFirestore.instance.collection('proposals').add({
        'title':           _titleCtrl.text.trim(),
        'description':     _descCtrl.text.trim(),
        'objectives':      _objectivesCtrl.text.trim(),
        'targetAudience':  _audienceCtrl.text.trim(),
        'date':            combinedDate,
        'time':            timeStr,
        'duration':        _durationCtrl.text.trim(),
        'location':        _locationCtrl.text.trim(),
        'maxParticipants': int.tryParse(_participantsCtrl.text) ?? 0,
        'budget':          double.tryParse(_budgetCtrl.text) ?? 0.0,
        'isFree':          _isFree,
        'fee':             _isFree ? 0.0 : (double.tryParse(_feeCtrl.text) ?? 0.0),
        'signature':       sigBase64,
        'status':          asDraft ? 'draft' : 'in_review',
        'createdBy':       uid,
        'submittedBy':     email,
        'createdAt':       FieldValue.serverTimestamp(),
        'submittedAt':     asDraft ? null : FieldValue.serverTimestamp(),
      });

      if (!asDraft) await logActivity('Proposal Submitted', _titleCtrl.text.trim());
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
        child: Column(children: [
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
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10)),
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
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // ── Basic Information ──────────────────────────────────
                  _InfoCard(children: [
                    _sectionHeader('Basic Information'),
                    _label('Workshop Title'),
                    _field(_titleCtrl, 'e.g., PCB Soldering Workshop',
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    _label('Description'),
                    _field(_descCtrl, 'Brief overview of the workshop...', maxLines: 3,
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    _label('Learning Objectives'),
                    _field(_objectivesCtrl, 'What will participants learn?', maxLines: 3,
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    _label('Target Audience'),
                    _field(_audienceCtrl, 'e.g., Engineering students, All years',
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                  ]),
                  const SizedBox(height: 16),

                  // ── Event Details ──────────────────────────────────────
                  _InfoCard(children: [
                    _sectionHeader('Event Details'),
                    _label('Location'),
                    _field(_locationCtrl, 'e.g., Engineering Lab 3, Block P19',
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label('Event Date'),
                        _datePickerWidget(context, _eventDate, () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => _eventDate = picked);
                        }),
                      ])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label('Start Time'),
                        _timePickerWidget(context, _eventTime, () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (picked != null) setState(() => _eventTime = picked);
                        }),
                      ])),
                    ]),
                    const SizedBox(height: 16),
                    _label('Duration'),
                    _field(_durationCtrl, 'e.g., 3 hours / Half Day',
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    _label('Expected Participants'),
                    _field(_participantsCtrl, 'e.g., 50',
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                  ]),
                  const SizedBox(height: 16),

                  // ── Budget ─────────────────────────────────────────────
                  _InfoCard(children: [
                    _sectionHeader('Budget'),
                    _label('Estimated Budget (RM)'),
                    _field(_budgetCtrl, '0.00',
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                  ]),
                  const SizedBox(height: 16),

                  // ── Registration Fee ───────────────────────────────────
                  _RegistrationFeeCard(
                    isFree: _isFree,
                    feeCtrl: _feeCtrl,
                    onToggle: (value) => setState(() {
                      _isFree = value;
                      // Reset fee field when switching back to free
                      if (_isFree) _feeCtrl.text = '0.00';
                    }),
                  ),
                  const SizedBox(height: 16),

                  // ── Signature ──────────────────────────────────────────
                  _buildSignaturePad(_sigCtrl),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _sigCtrl.clear()),
                      icon: const Icon(Icons.refresh, size: 16, color: AppColors.admin),
                      label: const Text('Clear Signature',
                          style: TextStyle(color: AppColors.admin, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Actions ────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : () => _submit(asDraft: false),
                      child: _saving
                          ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
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
                ]),
              ),
            ),
          ),
        ]),
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
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl        = TextEditingController();
  final _descCtrl         = TextEditingController();
  final _objectivesCtrl   = TextEditingController();
  final _audienceCtrl     = TextEditingController();
  final _durationCtrl     = TextEditingController();
  final _locationCtrl     = TextEditingController();
  final _participantsCtrl = TextEditingController();
  final _budgetCtrl       = TextEditingController();
  final _feeCtrl          = TextEditingController(text: '0.00');

  DateTime?  _eventDate;
  TimeOfDay? _eventTime;
  bool _saving  = false;
  bool _loading = true;
  bool _isFree  = true;

  final SignatureController _sigCtrl = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void initState() { super.initState(); _loadData(); }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _objectivesCtrl.dispose();
    _audienceCtrl.dispose(); _durationCtrl.dispose(); _locationCtrl.dispose();
    _participantsCtrl.dispose(); _budgetCtrl.dispose();
    _feeCtrl.dispose(); _sigCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('proposals').doc(widget.id).get();
      if (doc.exists) {
        final d = doc.data()!;
        _titleCtrl.text        = d['title']           as String? ?? '';
        _descCtrl.text         = d['description']     as String? ?? '';
        _objectivesCtrl.text   = d['objectives']      as String? ?? '';
        _audienceCtrl.text     = d['targetAudience']  as String? ?? '';
        _durationCtrl.text     = d['duration']        as String? ?? '';
        _locationCtrl.text     = d['location']        as String? ?? '';
        _participantsCtrl.text = (d['maxParticipants'] as num?)?.toString() ?? '';
        _budgetCtrl.text       = (d['budget'] as num?)?.toString() ?? '0.00';
        // Load fee fields
        _isFree                = d['isFree'] as bool? ?? true;
        _feeCtrl.text          = (d['fee'] as num?)?.toStringAsFixed(2) ?? '0.00';
        final ts = d['date'] as Timestamp?;
        if (ts != null) _eventDate = ts.toDate();
        final timeStr = d['time'] as String?;
        if (timeStr != null) {
          try {
            final lower = timeStr.toLowerCase();
            final isPm  = lower.contains('pm');
            final clean = lower.replaceAll('am', '').replaceAll('pm', '').trim();
            final parts = clean.split(':');
            int hour    = int.parse(parts[0]);
            final min   = int.parse(parts[1].trim());
            if (isPm && hour != 12) hour += 12;
            if (!isPm && hour == 12) hour = 0;
            _eventTime  = TimeOfDay(hour: hour, minute: min);
          } catch (_) {}
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _saveAsDraft() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _snack('Please enter at least a title'); return;
    }
    final timeStr = _eventTime?.format(context);
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('proposals').doc(widget.id).update({
        'title':           _titleCtrl.text.trim(),
        'description':     _descCtrl.text.trim(),
        'objectives':      _objectivesCtrl.text.trim(),
        'targetAudience':  _audienceCtrl.text.trim(),
        'duration':        _durationCtrl.text.trim(),
        'location':        _locationCtrl.text.trim(),
        'maxParticipants': int.tryParse(_participantsCtrl.text) ?? 0,
        'budget':          double.tryParse(_budgetCtrl.text) ?? 0.0,
        'isFree':          _isFree,
        'fee':             _isFree ? 0.0 : (double.tryParse(_feeCtrl.text) ?? 0.0),
        'date':            _eventDate != null ? Timestamp.fromDate(_eventDate!) : null,
        'time':            timeStr,
        'status':          'draft',
      });
      if (mounted) { _snack('Draft saved'); Navigator.pop(context); }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitProposal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventDate == null || _eventTime == null) {
      _snack('Please select a date and time'); return;
    }
    if (_sigCtrl.isEmpty) {
      _snack('Signature is required to submit'); return;
    }

    final timeStr = _eventTime?.format(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Proposal'),
        content: const Text('Once submitted, you can no longer edit this proposal. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _saving = true);
    try {
      final sigBytes  = await _sigCtrl.toPngBytes();
      final sigBase64 = sigBytes != null ? base64Encode(sigBytes) : null;

      await FirebaseFirestore.instance
          .collection('proposals').doc(widget.id).update({
        'title':           _titleCtrl.text.trim(),
        'description':     _descCtrl.text.trim(),
        'objectives':      _objectivesCtrl.text.trim(),
        'targetAudience':  _audienceCtrl.text.trim(),
        'duration':        _durationCtrl.text.trim(),
        'location':        _locationCtrl.text.trim(),
        'maxParticipants': int.tryParse(_participantsCtrl.text) ?? 0,
        'budget':          double.tryParse(_budgetCtrl.text) ?? 0.0,
        'isFree':          _isFree,
        'fee':             _isFree ? 0.0 : (double.tryParse(_feeCtrl.text) ?? 0.0),
        'date':            _eventDate != null
            ? Timestamp.fromDate(DateTime(
            _eventDate!.year, _eventDate!.month, _eventDate!.day,
            _eventTime!.hour, _eventTime!.minute))
            : null,
        'time':            timeStr,
        'signature':       sigBase64,
        'status':          'in_review',
        'submittedAt':     FieldValue.serverTimestamp(),
      });
      await logActivity('Proposal Submitted', _titleCtrl.text.trim());
      if (mounted) {
        _snack('Proposal submitted for review');
        Navigator.pop(context); // pop edit
        Navigator.pop(context); // pop detail — back to list
      }
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
        child: Column(children: [
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
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10)),
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
                : Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // ── Basic Information ────────────────────────────
                  _InfoCard(children: [
                    _sectionHeader('Basic Information'),
                    _label('Workshop Title'),
                    _field(_titleCtrl, 'e.g., PCB Soldering Workshop',
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    _label('Description'),
                    _field(_descCtrl, 'Brief overview...', maxLines: 3,
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    _label('Learning Objectives'),
                    _field(_objectivesCtrl, 'What will participants learn?', maxLines: 3,
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    _label('Target Audience'),
                    _field(_audienceCtrl, 'e.g., Engineering students',
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                  ]),
                  const SizedBox(height: 16),

                  // ── Event Details ────────────────────────────────
                  _InfoCard(children: [
                    _sectionHeader('Event Details'),
                    _label('Location'),
                    _field(_locationCtrl, 'e.g., Engineering Lab 3',
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label('Event Date'),
                        _datePickerWidget(context, _eventDate, () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _eventDate ?? DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => _eventDate = picked);
                        }),
                      ])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label('Start Time'),
                        _timePickerWidget(context, _eventTime, () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _eventTime ?? const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (picked != null) setState(() => _eventTime = picked);
                        }),
                      ])),
                    ]),
                    const SizedBox(height: 16),
                    _label('Duration'),
                    _field(_durationCtrl, 'e.g., 3 hours / Half Day',
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    _label('Expected Participants'),
                    _field(_participantsCtrl, 'e.g., 50',
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                  ]),
                  const SizedBox(height: 16),

                  // ── Budget ───────────────────────────────────────
                  _InfoCard(children: [
                    _sectionHeader('Budget'),
                    _label('Estimated Budget (RM)'),
                    _field(_budgetCtrl, '0.00',
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                  ]),
                  const SizedBox(height: 16),

                  // ── Registration Fee ─────────────────────────────
                  _RegistrationFeeCard(
                    isFree: _isFree,
                    feeCtrl: _feeCtrl,
                    onToggle: (value) => setState(() {
                      _isFree = value;
                      if (_isFree) _feeCtrl.text = '0.00';
                    }),
                  ),
                  const SizedBox(height: 16),

                  // ── Signature ────────────────────────────────────
                  _buildSignaturePad(_sigCtrl),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _sigCtrl.clear()),
                      icon: const Icon(Icons.refresh, size: 16, color: AppColors.admin),
                      label: const Text('Clear Signature',
                          style: TextStyle(color: AppColors.admin, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Actions ──────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submitProposal,
                      child: _saving
                          ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
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
          ),
        ]),
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
                          border: Border.all(
                              color: isSelected ? AppColors.president
                                  : AppColors.textLight.withValues(alpha: 0.3)),
                          boxShadow: isSelected
                              ? [BoxShadow(color: AppColors.president.withValues(alpha: 0.3),
                              blurRadius: 8, offset: const Offset(0, 2))]
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
                  if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.inbox_outlined, color: AppColors.textLight, size: 48),
                        const SizedBox(height: 12),
                        Text(_filter == 'in_review'
                            ? 'No proposals awaiting review' : 'No proposals found',
                            style: const TextStyle(color: AppColors.textMedium,
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ]),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: docs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
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
    final title     = data['title']  as String? ?? '(Untitled)';
    final status    = data['status'] as String? ?? 'draft';
    final date      = _formatSubmittedAt(
        data['submittedAt'] as Timestamp? ?? data['createdAt'] as Timestamp?);
    final budget    = (data['budget'] as num?)?.toStringAsFixed(2) ?? '0.00';
    final isFree    = data['isFree'] as bool? ?? true;
    final fee       = (data['fee'] as num?)?.toStringAsFixed(2) ?? '0.00';
    final createdBy = data['createdBy'] as String? ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) =>
              PresidentProposalDetailScreen(id: id, data: data))),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: _statusColor(status), width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark))),
            StatusBadge(label: _statusLabel(status), color: _statusColor(status)),
          ]),
          const SizedBox(height: 10),
          _SubmitterRow(uid: createdBy),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMedium),
            const SizedBox(width: 4),
            Text(date, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
            const Spacer(),
            const Icon(Icons.account_balance_wallet_outlined, size: 13, color: AppColors.textMedium),
            const SizedBox(width: 4),
            Text('RM $budget', style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
            const SizedBox(width: 10),
            Icon(
              isFree ? Icons.card_giftcard_outlined : Icons.attach_money_outlined,
              size: 13,
              color: AppColors.textMedium,
            ),
            const SizedBox(width: 4),
            Text(
              isFree ? 'Free' : 'RM $fee',
              style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
            ),
          ]),
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
      final budgetNeeded = (data['budget'] as num?)?.toDouble() ?? 0.0;
      final maxParticipants = (data['maxParticipants'] as num?)?.toInt() ?? 0;
      final fee = (data['fee'] as num?)?.toDouble() ?? 0.0;
      final isFree = data['isFree'] as bool? ?? true;

      // Calculate expected revenue from student fees
      final expectedRevenue = isFree ? 0.0 : maxParticipants * fee;
      // Net cost = what treasury actually needs to cover
      final netCost = budgetNeeded > expectedRevenue ? budgetNeeded - expectedRevenue : 0.0;

      // Only check treasury if there's a net cost to cover
      if (netCost > 0) {
        double treasuryAvailable = 0;
        try {
          final treasurySnap = await FirebaseFirestore.instance
              .collection('treasury').doc('funds').get();
          treasuryAvailable = (treasurySnap.data()?['available'] as num?)?.toDouble() ?? 10000.0;
        } catch (_) {}

        if (netCost > treasuryAvailable) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Not Enough Budget'),
                content: Text(
                  'Proposal requires RM ${budgetNeeded.toStringAsFixed(2)}\n'
                  'Expected revenue from fees: RM ${expectedRevenue.toStringAsFixed(2)}\n'
                  'Net cost to treasury: RM ${netCost.toStringAsFixed(2)}\n'
                  'But treasury only has RM ${treasuryAvailable.toStringAsFixed(2)}.',
                ),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
              ),
            );
          }
          return;
        }
      }

      final batch = FirebaseFirestore.instance.batch();
      final proposalRef = FirebaseFirestore.instance.collection('proposals').doc(id);
      final treasuryRef = FirebaseFirestore.instance.collection('treasury').doc('funds');

      batch.update(proposalRef, {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Only deduct net cost from treasury (0 if self-funded)
      if (netCost > 0) {
        batch.set(treasuryRef, {
          'available': FieldValue.increment(-netCost),
        }, SetOptions(merge: true));
      }

      final eventRef = FirebaseFirestore.instance.collection('events').doc();
      batch.set(eventRef, {
        'title':           data['title']           ?? '',
        'description':     data['description']     ?? '',
        'objectives':      data['objectives']      ?? '',
        'location':        data['location']        ?? '',
        'date':            data['date'],
        'time':            data['time']            ?? '',
        'duration':        data['duration']        ?? '',
        'targetAudience':  data['targetAudience']  ?? '',
        'maxParticipants': data['maxParticipants'] ?? 50,
        'budget':          data['budget']          ?? 0,
        // Pass through fee fields so the event reflects the proposal's fee settings
        'isFree':          data['isFree']          ?? true,
        'fee':             data['fee']             ?? 0,
        'status':          'upcoming',
        'proposalId':      id,
        'createdBy':       data['createdBy'],
        'createdAt':       FieldValue.serverTimestamp(),
        'registrationCount': 0,
      });
      await batch.commit();
      await logActivity('Proposal Approved', '${data['title']} — event created');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proposal approved and event created')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _showRejectDialog(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Proposal'),
        content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
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
      await logActivity('Proposal Rejected', data['title'] ?? '');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proposal rejected')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// Compact submitter row for the president list card
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
          name    = u['fullName'] as String? ?? u['email'] as String? ?? '—';
          faculty = u['faculty']  as String? ?? '';
          initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
        }
        return Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
                color: AppColors.president.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: Center(child: Text(initial,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.president))),
          ),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            if (faculty.isNotEmpty)
              Text(faculty, style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
          ])),
        ]);
      },
    );
  }
}

// ─── President: Proposal Detail Screen ────────────────────────────────────────

class PresidentProposalDetailScreen extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  const PresidentProposalDetailScreen(
      {super.key, required this.id, required this.data});

  @override
  Widget build(BuildContext context) {
    final title  = data['title']  as String? ?? '(Untitled)';
    final status = data['status'] as String? ?? 'draft';
    final budget = (data['budget'] as num?)?.toStringAsFixed(2) ?? '0.00';
    final sigB64 = data['signature'] as String?;
    final isFree = data['isFree'] as bool? ?? true;
    final fee    = (data['fee'] as num?)?.toStringAsFixed(2) ?? '0.00';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
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
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              const Text('PROPOSAL REVIEW',
                  style: TextStyle(color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(title,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13, fontWeight: FontWeight.w500)),
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
                    Text(_formatSubmittedAt(
                        data['submittedAt'] as Timestamp? ?? data['createdAt'] as Timestamp?),
                        style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                  ]),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  const Text('Submitted By',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: AppColors.textMedium)),
                  const SizedBox(height: 8),
                  _SubmitterDetail(uid: data['createdBy'] as String? ?? ''),
                ]),
                const SizedBox(height: 16),

                // Proposal details
                _InfoCard(children: [
                  const Text('Proposal Details',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(height: 16),
                  _DetailRow(icon: Icons.location_on_outlined,            label: 'Location',              value: data['location'] as String? ?? '—'),
                  _DetailRow(icon: Icons.calendar_today_outlined,         label: 'Event Date',            value: _formatDate(data['date'] as Timestamp?)),
                  _DetailRow(icon: Icons.access_time_outlined,            label: 'Time',                  value: data['time'] as String? ?? '—'),
                  _DetailRow(icon: Icons.timelapse_outlined,              label: 'Duration',              value: data['duration'] as String? ?? '—'),
                  _DetailRow(icon: Icons.people_outline,                  label: 'Audience',              value: data['targetAudience'] as String? ?? '—'),
                  _DetailRow(icon: Icons.group_outlined,                  label: 'Exp. Participants',     value: data['maxParticipants']?.toString() ?? '—'),
                  _DetailRow(icon: Icons.account_balance_wallet_outlined, label: 'Budget',                value: 'RM $budget'),
                  _DetailRow(
                    icon: isFree ? Icons.card_giftcard_outlined : Icons.attach_money_outlined,
                    label: 'Registration Fee',
                    value: isFree ? 'Free' : 'RM $fee',
                  ),
                  if ((data['description'] as String? ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10), const Divider(height: 1), const SizedBox(height: 10),
                    const Text('Description',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    Text(data['description'] as String? ?? '',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.5)),
                  ],
                  if ((data['objectives'] as String? ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10), const Divider(height: 1), const SizedBox(height: 10),
                    const Text('Learning Objectives',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    Text(data['objectives'] as String? ?? '',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.5)),
                  ],
                  // Signature
                  if (sigB64 != null) ...[
                    const SizedBox(height: 10), const Divider(height: 1), const SizedBox(height: 10),
                    const Text('Digital Signature',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.divider),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(base64Decode(sigB64), fit: BoxFit.contain),
                      ),
                    ),
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
                      onPressed: () =>
                          _PresidentProposalCard(id: id, data: data)._approve(context),
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
                      onPressed: () =>
                          _PresidentProposalCard(id: id, data: data)._showRejectDialog(context),
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
        ]),
      ),
    );
  }
}

// Full submitter detail for president's detail screen
class _SubmitterDetail extends StatelessWidget {
  final String uid;
  const _SubmitterDetail({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) {
      return const Text('Unknown', style: TextStyle(color: AppColors.textMedium));
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 20, width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.president));
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const Text('Unknown user',
              style: TextStyle(color: AppColors.textMedium, fontSize: 13));
        }
        final u        = snap.data!.data() as Map<String, dynamic>;
        final name     = u['fullName']    as String? ?? '—';
        final email    = u['email']       as String? ?? '—';
        final faculty  = u['faculty']     as String? ?? '—';
        final matrixId = u['matrixId']    as String? ?? '—';
        final phone    = u['phoneNumber'] as String? ?? '—';
        final initial  = name.isNotEmpty ? name[0].toUpperCase() : '?';

        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: AppColors.president.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: Center(child: Text(initial,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                    color: AppColors.president))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 2),
            Text(email, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 6, children: [
              _InfoChip(icon: Icons.badge_outlined,  label: matrixId),
              _InfoChip(icon: Icons.school_outlined, label: faculty),
              _InfoChip(icon: Icons.phone_outlined,  label: phone),
            ]),
          ])),
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
        color: AppColors.inputBg, borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: AppColors.textMedium),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textDark,
          fontWeight: FontWeight.w500)),
    ]),
  );
}