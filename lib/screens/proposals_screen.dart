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
    case 'in_review':
    case 'in review':
      return AppColors.president;
    case 'approved':
      return AppColors.primary;
    case 'rejected':
      return AppColors.admin;
    default:
      return AppColors.textMedium; // draft
  }
}

String _statusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'in_review':
    case 'in review':
      return 'In Review';
    case 'approved':
      return 'Approved';
    case 'rejected':
      return 'Rejected';
    default:
      return 'Draft';
  }
}

String _formatDate(Timestamp? ts) {
  if (ts == null) return 'Not submitted';
  final d = ts.toDate();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('IEEE PES UTM',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w500)),
                      Text('My Proposals',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark)),
                      Text('Manage your workshop proposals',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textMedium)),
                    ],
                  ),
                  const Icon(Icons.description_outlined,
                      color: AppColors.primary, size: 26),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Create button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CreateProposalScreen())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Create New Proposal',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Live Firestore list — filtered to current user only
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
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary));
                  }
                  if (snap.hasError) {
                    return Center(
                        child: Text('Error: ${snap.error}',
                            style: const TextStyle(
                                color: AppColors.textMedium)));
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.description_outlined,
                              color: AppColors.textLight, size: 48),
                          SizedBox(height: 12),
                          Text('No proposals yet',
                              style: TextStyle(
                                  color: AppColors.textMedium,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          SizedBox(height: 4),
                          Text('Tap "Create New Proposal" to get started',
                              style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 13)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                    itemBuilder: (c, i) {
                      final d =
                      docs[i].data() as Map<String, dynamic>;
                      final id = docs[i].id;
                      final title =
                          d['title'] as String? ?? '(Untitled)';
                      final status =
                          d['status'] as String? ?? 'draft';
                      final date = _formatDate(
                          d['date'] as Timestamp? ??
                              d['createdAt'] as Timestamp?);
                      return _ProposalCard(
                          id: id,
                          title: title,
                          status: status,
                          date: date);
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
  const _ProposalCard(
      {required this.id,
        required this.title,
        required this.status,
        required this.date});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProposalDetailScreen(
                  id: id, title: title, status: status, date: date))),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border:
          Border(left: BorderSide(color: _statusColor(status), width: 4)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StatusBadge(
                          label: _statusLabel(status),
                          color: _statusColor(status)),
                      const SizedBox(width: 10),
                      Text(date,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textMedium)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward,
                color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Committee: Proposal Detail Screen ────────────────────────────────────────

class ProposalDetailScreen extends StatefulWidget {
  final String id;
  final String title;
  final String status;
  final String date;
  const ProposalDetailScreen(
      {super.key,
        required this.id,
        required this.title,
        required this.status,
        required this.date});

  @override
  State<ProposalDetailScreen> createState() => _ProposalDetailScreenState();
}

class _ProposalDetailScreenState extends State<ProposalDetailScreen> {
  bool _generatingPdf = false;

  Future<void> _generatePdf() async {
    setState(() => _generatingPdf = true);
    try {
      final docSnap = await FirebaseFirestore.instance
          .collection('proposals')
          .doc(widget.id)
          .get();
      if (!docSnap.exists) throw Exception('Proposal not found');

      final data = docSnap.data()!;
      final desc =
          data['description'] as String? ?? 'No description provided.';
      final loc = data['location'] as String? ?? 'No location provided.';
      final budget =
          (data['budget'] as num?)?.toStringAsFixed(2) ?? '0.00';
      final maxPart = data['maxParticipants']?.toString() ?? '50';

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('IEEE PES UTM — Workshop Wizard',
                            style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('26A69A'))),
                        pw.Text('Workshop Proposal',
                            style: const pw.TextStyle(
                                fontSize: 16, color: PdfColors.grey700)),
                      ]),
                ),
                pw.SizedBox(height: 20),
                pw.Text(widget.title,
                    style: pw.TextStyle(
                        fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Row(children: [
                  pw.Text('Status: ${_statusLabel(widget.status)}',
                      style: const pw.TextStyle(fontSize: 14)),
                  pw.SizedBox(width: 20),
                  pw.Text('Submitted: ${widget.date}',
                      style: const pw.TextStyle(
                          fontSize: 14, color: PdfColors.grey600)),
                ]),
                pw.SizedBox(height: 30),
                pw.Text('Description',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text(desc),
                pw.SizedBox(height: 20),
                pw.Text('Details',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Bullet(text: 'Location: $loc'),
                pw.Bullet(text: 'Budget: RM $budget'),
                pw.Bullet(text: 'Max Participants: $maxPart'),
                pw.SizedBox(height: 30),
                pw.Text('Approval Progress',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  context: context,
                  headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
                  headerHeight: 30,
                  cellHeight: 30,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerRight,
                  },
                  data: <List<String>>[
                    <String>['Step', 'Status'],
                    <String>[
                      'Faculty Advisor',
                      widget.status == 'approved' ? 'Approved' : 'Pending'
                    ],
                    <String>[
                      'Club President',
                      widget.status == 'approved' ? 'Approved' : 'Pending'
                    ],
                    <String>[
                      'FKE Office',
                      widget.status == 'approved' ? 'Approved' : 'Pending'
                    ],
                    <String>[
                      'HEP Student Affairs',
                      widget.status == 'approved' ? 'Approved' : 'Pending'
                    ],
                  ],
                ),
                pw.Spacer(),
                pw.Divider(),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('IEEE PES UTM Student Branch © 2026',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey)),
                    ])
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: '${widget.title}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error generating PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(widget.status);
    // FIX: Only allow editing drafts — in_review/approved/rejected are locked
    final canEdit = widget.status == 'draft';

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
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(24)),
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
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('PROPOSAL STATUS',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(widget.title,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Status card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        children: [
                          Text('Submitted ${widget.date}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMedium)),
                          const SizedBox(height: 10),
                          StatusBadge(
                              label: _statusLabel(widget.status),
                              color: statusColor),
                          // Show rejection reason if rejected
                          if (widget.status == 'rejected') ...[
                            const SizedBox(height: 12),
                            _RejectionReasonWidget(proposalId: widget.id),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Approval progress card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Approval Progress',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 20),
                          ApprovalStepTile(
                              title: 'Faculty Advisor',
                              subtitle: (widget.status == 'Approved' || widget.status == 'approved')
                                  ? 'Approved'
                                  : 'Pending',
                              isCompleted: (widget.status == 'Approved' || widget.status == 'approved'),
                              isLast: false),
                          ApprovalStepTile(
                              title: 'Club President',
                              subtitle: (widget.status == 'Approved' || widget.status == 'approved')
                                  ? 'Approved'
                                  : widget.status == 'rejected'
                                  ? 'Rejected'
                                  : 'Pending',
                              isCompleted: (widget.status == 'Approved' || widget.status == 'approved'),
                              isLast: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // PDF button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _generatingPdf ? null : _generatePdf,
                        icon: _generatingPdf
                            ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                            : const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text('View Proposal PDF'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // FIX: Edit only shown for drafts
                    if (canEdit)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => EditProposalScreen(
                                      id: widget.id,
                                      status: widget.status))),
                          child: const Text('Edit Proposal'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Shows rejection reason fetched from Firestore
class _RejectionReasonWidget extends StatelessWidget {
  final String proposalId;
  const _RejectionReasonWidget({required this.proposalId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('proposals')
          .doc(proposalId)
          .get(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final reason = (snap.data?.data()
        as Map<String, dynamic>?)?['rejectionReason'] as String?;
        if (reason == null || reason.isEmpty) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.admin.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.admin.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rejection Reason',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.admin)),
              const SizedBox(height: 4),
              Text(reason,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textDark)),
            ],
          ),
        );
      },
    );
  }
}

class _SignatureDialog extends StatefulWidget {
  final String title;
  const _SignatureDialog({required this.title});

  @override
  State<_SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<_SignatureDialog> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      content: Container(
        height: 200,
        width: double.maxFinite,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
        child: Signature(controller: _controller, backgroundColor: Colors.white),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () => _controller.clear(), child: const Text('Clear', style: TextStyle(color: Colors.red))),
        ElevatedButton(
          onPressed: () async {
            if (_controller.isEmpty) return;
            final bytes = await _controller.toPngBytes();
            if (bytes != null && mounted) {
              Navigator.pop(context, base64Encode(bytes));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Approve & Sign'),
        ),
      ],
    );
  }
}

// ─── Committee: Create Proposal Screen ────────────────────────────────────────

class CreateProposalScreen extends StatefulWidget {
  const CreateProposalScreen({super.key});

  @override
  State<CreateProposalScreen> createState() => _CreateProposalScreenState();
}

class _CreateProposalScreenState extends State<CreateProposalScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _learningCtrl = TextEditingController();
  final _audienceCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController(text: '0.00');
  final _durationCtrl = TextEditingController(text: '3');
  final _maxPartCtrl = TextEditingController(text: '50');
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _signatureData; // base64 PNG of committee signature
  // Signature controller
  final SignatureController _sigController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _learningCtrl.dispose();
    _audienceCtrl.dispose();
    _locationCtrl.dispose();
    _budgetCtrl.dispose();
    _durationCtrl.dispose();
    _maxPartCtrl.dispose();
    _sigController.dispose();
    super.dispose();
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark)),
  );

  Widget _field(TextEditingController ctrl, String hint,
      {int maxLines = 1, TextInputType? keyboardType}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
        decoration: InputDecoration(
            hintText: hint,
            hintStyle:
            const TextStyle(color: AppColors.textLight, fontSize: 14)),
      );

  Future<void> _submit({required bool asDraft}) async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a title')));
      return;
    }
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // capture signature PNG if any
      try {
        final png = await _sigController.toPngBytes();
        if (png != null) {
          _signatureData = base64Encode(png);
        }
      } catch (_) {}

      // Build chosen date/time if provided
      DateTime? chosen;
      if (_selectedDate != null) {
        chosen = _selectedDate!;
        if (_selectedTime != null) {
          chosen = DateTime(chosen.year, chosen.month, chosen.day, _selectedTime!.hour, _selectedTime!.minute);
        }
      }
      final ts = chosen != null ? Timestamp.fromDate(chosen) : Timestamp.now();

      await FirebaseFirestore.instance.collection('proposals').add({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'learningObjectives': _learningCtrl.text.trim(),
        'targetAudience': _audienceCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'budget': double.tryParse(_budgetCtrl.text) ?? 0,
        'durationHours': double.tryParse(_durationCtrl.text) ?? 0,
        'maxParticipants': int.tryParse(_maxPartCtrl.text) ?? 50,
        'status': asDraft ? 'draft' : 'in_review',
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        // Only set date when actually submitting
        'date': asDraft ? null : ts,
        'committeeSignature': _signatureData ?? '',
      });
      // Log activity for actual submissions only
      if (!asDraft) {
        await logActivity(
            'New proposal submitted', _titleCtrl.text.trim());
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(24)),
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
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('CREATE PROPOSAL',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Workshop Proposal Form',
                      style:
                      TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Workshop Title *'),
                      _field(_titleCtrl, 'e.g., PCB Soldering Workshop'),
                      const SizedBox(height: 16),
                      _label('Description *'),
                      _field(_descCtrl, 'Brief overview of the workshop...', maxLines: 4),
                      const SizedBox(height: 16),
                      _label('Learning Objectives *'),
                      _field(_learningCtrl, 'What will participants learn from this workshop?', maxLines: 3),
                      const SizedBox(height: 16),
                      _label('Target Audience *'),
                      _field(_audienceCtrl, 'e.g., Engineering students, All years'),
                      const SizedBox(height: 16),

                      Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Date *'),
                              GestureDetector(
                                onTap: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2100),
                                  );
                                  if (d != null) setState(() => _selectedDate = d);
                                },
                                child: AbsorbPointer(
                                  child: TextField(
                                    controller: TextEditingController(text: _selectedDate == null ? '' : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}'),
                                    decoration: const InputDecoration(hintText: 'mm/dd/yyyy', hintStyle: TextStyle(color: AppColors.textLight)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Time *'),
                              GestureDetector(
                                onTap: () async {
                                  final t = await showTimePicker(
                                    context: context,
                                    initialTime: _selectedTime ?? TimeOfDay.now(),
                                  );
                                  if (t != null) setState(() => _selectedTime = t);
                                },
                                child: AbsorbPointer(
                                  child: TextField(
                                    controller: TextEditingController(text: _selectedTime == null ? '' : _selectedTime!.format(context)),
                                    decoration: const InputDecoration(hintText: '--:-- --', hintStyle: TextStyle(color: AppColors.textLight)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),

                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Duration (hours) *'),
                              _field(_durationCtrl, 'e.g., 3', keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Expected Participants *'),
                              _field(_maxPartCtrl, '50', keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                      ]),

                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Expected Budget (RM) *'),
                              _field(_budgetCtrl, 'e.g., 500.00', keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Location *'),
                              _field(_locationCtrl, 'e.g., Engineering Lab 3'),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),

                      _label('Digital Signature *'),
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.textLight.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Signature(
                                controller: _sigController,
                                backgroundColor: Colors.white,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _sigController.clear();
                                          _signatureData = null;
                                        });
                                      },
                                      child: const Text('Clear')),
                                  TextButton(
                                      onPressed: () async {
                                        final png = await _sigController.toPngBytes();
                                        if (png != null) {
                                          setState(() {
                                            _signatureData = base64Encode(png);
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signature captured')));
                                        }
                                      },
                                      child: const Text('Save Signature')),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saving ? null : () => _submit(asDraft: false),
                              child: _saving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                  : const Text('Submit Proposal'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Committee: Edit Proposal Screen ──────────────────────────────────────────

class EditProposalScreen extends StatefulWidget {
  final String id;
  final String status;
  const EditProposalScreen(
      {super.key, required this.id, required this.status});

  @override
  State<EditProposalScreen> createState() => _EditProposalScreenState();
}

class _EditProposalScreenState extends State<EditProposalScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _maxPartCtrl = TextEditingController();
  bool _saving = false;
  bool _loading = true;

  // FIX: Only drafts are editable. in_review, approved, rejected are all locked.
  bool get _canEdit => widget.status == 'draft';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _budgetCtrl.dispose();
    _maxPartCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('proposals')
          .doc(widget.id)
          .get();
      if (doc.exists) {
        final d = doc.data()!;
        _titleCtrl.text = d['title'] as String? ?? '';
        _descCtrl.text = d['description'] as String? ?? '';
        _locationCtrl.text = d['location'] as String? ?? '';
        _budgetCtrl.text =
            (d['budget'] as num?)?.toString() ?? '0.00';
        _maxPartCtrl.text =
            (d['maxParticipants'] as num?)?.toString() ?? '50';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading proposal: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark)),
  );

  Widget _field(TextEditingController ctrl, String hint,
      {int maxLines = 1, TextInputType? keyboardType}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        enabled: _canEdit,
        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
        decoration: InputDecoration(
            hintText: hint,
            hintStyle:
            const TextStyle(color: AppColors.textLight, fontSize: 14)),
      );

  Future<void> _saveChanges() async {
    if (!_canEdit) return;
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a title')));
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('proposals')
          .doc(widget.id)
          .update({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'budget': double.tryParse(_budgetCtrl.text) ?? 0,
        'maxParticipants': int.tryParse(_maxPartCtrl.text) ?? 50,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Proposal updated successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // FIX: Added submit action so a draft can be submitted from the edit screen
  Future<void> _submitProposal() async {
    if (!_canEdit) return;
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a title')));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Proposal'),
        content: const Text(
            'Once submitted, you will no longer be able to edit this proposal. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('proposals')
          .doc(widget.id)
          .update({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'budget': double.tryParse(_budgetCtrl.text) ?? 0,
        'maxParticipants': int.tryParse(_maxPartCtrl.text) ?? 50,
        'status': 'in_review',
        'date': Timestamp.now(),
      });
      await logActivity('Proposal submitted', _titleCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Proposal submitted for review')));
        // Pop twice: edit screen + detail screen, back to proposals list
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(24)),
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
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('EDIT PROPOSAL',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Update Workshop Details',
                      style:
                      TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary))
                  : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Read-only warning for non-draft statuses
                      if (!_canEdit) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.orange
                                  .withValues(alpha: 0.1),
                              borderRadius:
                              BorderRadius.circular(8)),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                  child: Text(
                                      'This proposal can no longer be edited',
                                      style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 13,
                                          fontWeight:
                                          FontWeight.w600))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      _label('Workshop Title *'),
                      _field(_titleCtrl,
                          'e.g., PCB Soldering Workshop'),
                      const SizedBox(height: 16),
                      _label('Description *'),
                      _field(_descCtrl,
                          'Describe the workshop objectives...',
                          maxLines: 4),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  _label('Budget (RM) *'),
                                  _field(_budgetCtrl, '0.00',
                                      keyboardType:
                                      TextInputType.number)
                                ])),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  _label('Max Participants *'),
                                  _field(_maxPartCtrl, '50',
                                      keyboardType:
                                      TextInputType.number)
                                ])),
                      ]),
                      const SizedBox(height: 16),
                      _label('Location *'),
                      _field(_locationCtrl,
                          'e.g., Engineering Lab 3'),
                      const SizedBox(height: 24),
                      if (_canEdit) ...[
                        // FIX: Submit button on edit screen
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saving
                                ? null
                                : _submitProposal,
                            child: _saving
                                ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor:
                                    AlwaysStoppedAnimation<
                                        Color>(
                                        Colors.white)))
                                : const Text('Submit Proposal'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed:
                            _saving ? null : _saveChanges,
                            child: const Text('Save as Draft'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── President: All Proposals Review Screen ────────────────────────────────────
//
// Streams ALL proposals (no createdBy filter).
// President can approve or reject each one.
// On approval, an event document is automatically created.

class PresidentProposalsScreen extends StatefulWidget {
  final String role;
  const PresidentProposalsScreen({super.key, required this.role});

  @override
  State<PresidentProposalsScreen> createState() =>
      _PresidentProposalsScreenState();
}

class _PresidentProposalsScreenState
    extends State<PresidentProposalsScreen> {
  // Filter: 'all' | 'in_review' | 'approved' | 'rejected' | 'draft'
  String _filter = 'in_review';

  static const _filters = [
    ('In Review', 'in_review'),
    ('All', 'all'),
    ('Approved', 'approved'),
    ('Rejected', 'rejected'),
  ];

  Query<Map<String, dynamic>> get _query {
    final base =
    FirebaseFirestore.instance.collection('proposals');
    if (_filter == 'all') {
      return base.orderBy('createdAt', descending: true);
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('IEEE PES UTM',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w500)),
                      Text('Proposals',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark)),
                      Text('Review and approve proposals',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textMedium)),
                    ],
                  ),
                  const Icon(Icons.how_to_vote_outlined,
                      color: AppColors.president, size: 26),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.president
                              : AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isSelected
                                  ? AppColors.president
                                  : AppColors.textLight.withValues(
                                  alpha: 0.3)),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                                color: AppColors.president
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ]
                              : [],
                        ),
                        child: Text(f.$1,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textMedium)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _query.snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.president));
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined,
                              color: AppColors.textLight, size: 48),
                          const SizedBox(height: 12),
                          Text(
                              _filter == 'in_review'
                                  ? 'No proposals awaiting review'
                                  : 'No proposals found',
                              style: const TextStyle(
                                  color: AppColors.textMedium,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                    itemBuilder: (c, i) {
                      final d =
                      docs[i].data() as Map<String, dynamic>;
                      return _PresidentProposalCard(
                        id: docs[i].id,
                        data: d,
                      );
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

  Future<String> _getSubmitterName() async {
    final uid = data['createdBy'] as String?;
    if (uid == null) return 'Unknown';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return doc.data()?['name'] as String? ??
          doc.data()?['email'] as String? ??
          'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? '(Untitled)';
    final status = data['status'] as String? ?? 'draft';
    final date = _formatDate(
        data['date'] as Timestamp? ?? data['createdAt'] as Timestamp?);
    final budget = (data['budget'] as num?)?.toStringAsFixed(2) ?? '0.00';
    final location = data['location'] as String? ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PresidentProposalDetailScreen(
                  id: id, data: data))),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border:
          Border(left: BorderSide(color: _statusColor(status), width: 4)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark))),
                StatusBadge(
                    label: _statusLabel(status),
                    color: _statusColor(status)),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.location_on_outlined,
                  size: 13, color: AppColors.textMedium),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(location,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMedium))),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.attach_money,
                  size: 13, color: AppColors.textMedium),
              const SizedBox(width: 4),
              Text('RM $budget',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMedium)),
              const Spacer(),
              Text(date,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMedium)),
            ]),
            // Show approve/reject buttons inline only for in_review proposals
            if (status == 'in_review') ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showRejectDialog(context),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.admin,
                      side: BorderSide(
                          color: AppColors.admin.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approve(context),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Proposal'),
        content: const Text(
            'Approving this proposal will automatically create an event visible to all students. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Approve')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      // Fetch latest proposal snapshot to validate state/budget
      final propSnap = await FirebaseFirestore.instance.collection('proposals').doc(id).get();
      if (!propSnap.exists) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proposal not found')));
        return;
      }
      final propData = propSnap.data()!;
      final currentStatus = propData['status'] as String? ?? 'draft';

      // 1. Direct Approval (Removing Treasurer bottleneck as requested)
      if (currentStatus != 'Pending' && currentStatus != 'in_review') {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This proposal is not awaiting approval')));
        return;
      }

      final budgetNeeded = (propData['budget'] as num?)?.toDouble() ?? 0.0;
      // Check treasury available funds (document: treasury/funds -> { available: number })
      final treasuryRef = FirebaseFirestore.instance.collection('treasury').doc('funds');
      final treasurySnap = await treasuryRef.get();
      
      // Default to RM 10,000 if document doesn't exist for the demo
      final available = (treasurySnap.data()?['available'] as num?)?.toDouble() ?? 10000.0;

      if (budgetNeeded > available) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Not Enough Budget', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              content: Text('This proposal requires RM $budgetNeeded, but the Treasury only has RM $available remaining.\n\nApproval blocked to prevent deficit.'),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
            ),
          );
        }
        return;
      }

      // 2. Request President's Signature
      if (!context.mounted) return;
      final presidentSig = await showDialog<String>(
        context: context,
        builder: (ctx) => _SignatureDialog(title: 'President Approval Signature'),
      );

      if (presidentSig == null) return;

      final batch = FirebaseFirestore.instance.batch();
      final proposalRef = FirebaseFirestore.instance.collection('proposals').doc(id);

      // 3. Update proposal status and record president info
      batch.update(proposalRef, {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'presidentSignature': presidentSig,
        'presidentUid': FirebaseAuth.instance.currentUser?.uid,
      });

      // 2. Deduct budget from treasury (create doc if it doesn't exist)
      batch.set(treasuryRef, {
        'available': FieldValue.increment(-budgetNeeded),
      }, SetOptions(merge: true));

      // 3. Auto-create event from proposal data
      final eventRef = FirebaseFirestore.instance.collection('events').doc();
      batch.set(eventRef, {
        'title': propData['title'] ?? '',
        'description': propData['description'] ?? '',
        'location': propData['location'] ?? '',
        'budget': propData['budget'] ?? 0,
        'maxParticipants': propData['maxParticipants'] ?? 50,
        'status': 'upcoming',
        'proposalId': id,
        'createdBy': propData['createdBy'],
        'date': propData['date'] ?? FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'registrationCount': 0,
      });

      await batch.commit();

      await logActivity('Proposal approved', '${propData['title']} — event created automatically');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proposal approved and event created successfully')));
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Provide a reason for rejection (optional):'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'e.g., Budget exceeds limit...',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.admin),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reject')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('proposals')
          .doc(id)
          .update({
        'status': 'rejected',
        'rejectionReason': reasonCtrl.text.trim(),
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      await logActivity(
          'Proposal rejected', data['title'] ?? 'Unknown proposal');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Proposal rejected')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
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
    final title = data['title'] as String? ?? '(Untitled)';
    final desc = data['description'] as String? ?? 'No description.';
    final location = data['location'] as String? ?? '';
    final budget =
        (data['budget'] as num?)?.toStringAsFixed(2) ?? '0.00';
    final maxPart = data['maxParticipants']?.toString() ?? '50';
    final status = data['status'] as String? ?? 'draft';
    final date = _formatDate(
        data['date'] as Timestamp? ?? data['createdAt'] as Timestamp?);

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
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(24)),
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
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('PROPOSAL REVIEW',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(title,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status + date
                    _DetailCard(children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StatusBadge(
                                label: _statusLabel(status),
                                color: _statusColor(status)),
                            Text(date,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMedium)),
                          ]),
                    ]),
                    const SizedBox(height: 16),

                    // Proposal details
                    _DetailCard(children: [
                      const Text('Proposal Details',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                      const SizedBox(height: 16),
                      _DetailRow(
                          icon: Icons.title,
                          label: 'Title',
                          value: title),
                      _DetailRow(
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          value: location),
                      _DetailRow(
                          icon: Icons.attach_money,
                          label: 'Budget',
                          value: 'RM $budget'),
                      _DetailRow(
                          icon: Icons.group_outlined,
                          label: 'Max Participants',
                          value: maxPart),
                      const SizedBox(height: 12),
                      const Text('Description',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark)),
                      const SizedBox(height: 6),
                      Text(desc,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMedium,
                              height: 1.5)),
                    ]),

                    // Rejection reason if applicable
                    if (status == 'rejected') ...[
                      const SizedBox(height: 16),
                      _DetailCard(children: [
                        const Text('Rejection Reason',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.admin)),
                        const SizedBox(height: 8),
                        Text(
                            data['rejectionReason'] as String? ??
                                'No reason provided',
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMedium)),
                      ]),
                    ],

                    // Approve / Reject actions (only for in_review)
                    if (status == 'in_review') ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _PresidentProposalCard(
                              id: id, data: data)
                              ._approve(context),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Approve & Create Event'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding:
                              const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _PresidentProposalCard(
                              id: id, data: data)
                              ._showRejectDialog(context),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Reject Proposal'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.admin,
                              side: BorderSide(
                                  color: AppColors.admin
                                      .withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14)),
                        ),
                      ),
                    ],
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
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4))
      ],
    ),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children),
  );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, size: 16, color: AppColors.textMedium),
      const SizedBox(width: 8),
      Text('$label: ',
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark)),
      Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMedium))),
    ]),
  );
}