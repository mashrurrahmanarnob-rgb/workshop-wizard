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
    case 'in_review': case 'in review': return AppColors.president;
    case 'approved':  return AppColors.primary;
    case 'rejected':  return AppColors.admin;
    default:          return AppColors.textMedium; // draft
  }
}

String _statusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'in_review': case 'in review': return 'In Review';
    case 'approved':  return 'Approved';
    case 'rejected':  return 'Rejected';
    default:          return 'Draft';
  }
}

String _formatDate(Timestamp? ts) {
  if (ts == null) return 'Not submitted';
  final d = ts.toDate();
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

// ─── Proposals List Screen ─────────────────────────────────────────────────────

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
                          style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500)),
                      Text('Proposals',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                      Text('Manage workshop proposals',
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

            // ── Live Firestore list ─────────────────────────────────────────────
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
                                Text('No proposals yet', style: TextStyle(color: AppColors.textMedium, fontSize: 15, fontWeight: FontWeight.w600)),
                                SizedBox(height: 4),
                                Text('Tap "Create New Proposal" to get started', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: docs.length,
                          separatorBuilder: (_, idx) => const SizedBox(height: 12),
                          itemBuilder: (c, i) {
                            final d    = docs[i].data() as Map<String, dynamic>;
                            final id   = docs[i].id;
                            final title  = d['title']  as String? ?? '(Untitled)';
                            final status = d['status'] as String? ?? 'draft';
                            final date   = _formatDate(d['date'] as Timestamp? ?? d['createdAt'] as Timestamp?);
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
          MaterialPageRoute(builder: (_) => ProposalDetailScreen(id: id, title: title, status: status, date: date))),
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
                      Text(date, style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
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

// ─── Proposal Detail Screen ────────────────────────────────────────────────────

class ProposalDetailScreen extends StatefulWidget {
  final String id;
  final String title;
  final String status;
  final String date;
  const ProposalDetailScreen({super.key, required this.id, required this.title, required this.status, required this.date});

  @override
  State<ProposalDetailScreen> createState() => _ProposalDetailScreenState();
}

class _ProposalDetailScreenState extends State<ProposalDetailScreen> {
  bool _generatingPdf = false;

  Future<void> _generatePdf() async {
    setState(() => _generatingPdf = true);
    try {
      final docSnap = await FirebaseFirestore.instance.collection('proposals').doc(widget.id).get();
      if (!docSnap.exists) throw Exception('Proposal not found');
      
      final data = docSnap.data()!;
      final desc = data['description'] as String? ?? 'No description provided.';
      final loc = data['location'] as String? ?? 'No location provided.';
      final budget = (data['budget'] as num?)?.toStringAsFixed(2) ?? '0.00';
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
                      pw.Text('IEEE PES UTM — Workshop Wizard', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('26A69A'))),
                      pw.Text('Workshop Proposal', style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
                    ]
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(widget.title, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Text('Status: ${_statusLabel(widget.status)}', style: pw.TextStyle(fontSize: 14)),
                    pw.SizedBox(width: 20),
                    pw.Text('Submitted: ${widget.date}', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
                  ]
                ),
                pw.SizedBox(height: 30),
                pw.Text('Description', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text(desc),
                pw.SizedBox(height: 20),
                pw.Text('Details', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Bullet(text: 'Location: $loc'),
                pw.Bullet(text: 'Budget: RM $budget'),
                pw.Bullet(text: 'Max Participants: $maxPart'),
                pw.SizedBox(height: 30),
                pw.Text('Approval Progress', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  context: context,
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  headerHeight: 30,
                  cellHeight: 30,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerRight,
                  },
                  data: <List<String>>[
                    <String>['Step', 'Status'],
                    <String>['Faculty Advisor', widget.status == 'approved' ? 'Approved' : 'Pending'],
                    <String>['Club President', widget.status == 'approved' ? 'Approved' : 'Pending'],
                    <String>['FKE Office', widget.status == 'approved' ? 'Approved' : 'Pending'],
                    <String>['HEP Student Affairs', widget.status == 'approved' ? 'Approved' : 'Pending'],
                  ],
                ),
                pw.Spacer(),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('IEEE PES UTM Student Branch © 2026', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                  ]
                )
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(widget.status);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('PROPOSAL STATUS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(widget.title, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        children: [
                          Text('Submitted ${widget.date}', style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
                          const SizedBox(height: 10),
                          StatusBadge(label: _statusLabel(widget.status), color: statusColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Approval Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                          const SizedBox(height: 20),
                          ApprovalStepTile(title: 'Faculty Advisor',    subtitle: widget.status == 'approved' ? 'Approved' : 'Pending', isCompleted: widget.status == 'approved', isLast: false),
                          ApprovalStepTile(title: 'Club President',     subtitle: widget.status == 'approved' ? 'Approved' : 'Pending', isCompleted: widget.status == 'approved', isLast: false),
                          ApprovalStepTile(title: 'FKE Office',         subtitle: widget.status == 'approved' ? 'Approved' : 'Pending', isCompleted: widget.status == 'approved', isLast: false),
                          ApprovalStepTile(title: 'HEP Student Affairs',subtitle: widget.status == 'approved' ? 'Approved' : 'Pending', isCompleted: widget.status == 'approved', isLast: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _generatingPdf ? null : _generatePdf,
                        icon: _generatingPdf 
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text('View Proposal PDF'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProposalScreen(id: widget.id, status: widget.status))),
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

// ─── Create Proposal Screen ────────────────────────────────────────────────────

class CreateProposalScreen extends StatefulWidget {
  const CreateProposalScreen({super.key});

  @override
  State<CreateProposalScreen> createState() => _CreateProposalScreenState();
}

class _CreateProposalScreenState extends State<CreateProposalScreen> {
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _budgetCtrl   = TextEditingController(text: '0.00');
  final _maxPartCtrl  = TextEditingController(text: '50');
  bool _saving = false;

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      );

  Widget _field(TextEditingController ctrl, String hint, {int maxLines = 1, TextInputType? keyboardType}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14)),
      );

  Future<void> _submit({required bool asDraft}) async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('proposals').add({
        'title':     _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location':  _locationCtrl.text.trim(),
        'budget':    double.tryParse(_budgetCtrl.text) ?? 0,
        'maxParticipants': int.tryParse(_maxPartCtrl.text) ?? 50,
        'status':    asDraft ? 'draft' : 'in_review',
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'date':      asDraft ? null : Timestamp.now(),
      });
      await logActivity('New proposal created', '${_titleCtrl.text.trim()} submitted');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('CREATE PROPOSAL', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Workshop Proposal Form', style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Workshop Title *'),
                      _field(_titleCtrl, 'e.g., PCB Soldering Workshop'),
                      const SizedBox(height: 16),
                      _label('Description *'),
                      _field(_descCtrl, 'Describe the workshop objectives...', maxLines: 4),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Budget (RM) *'), _field(_budgetCtrl, '0.00', keyboardType: TextInputType.number)])),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Max Participants *'), _field(_maxPartCtrl, '50', keyboardType: TextInputType.number)])),
                      ]),
                      const SizedBox(height: 16),
                      _label('Location *'),
                      _field(_locationCtrl, 'e.g., Engineering Lab 3'),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : () => _submit(asDraft: false),
                          child: _saving
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
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

// ─── Edit Proposal Screen ──────────────────────────────────────────────────────

class EditProposalScreen extends StatefulWidget {
  final String id;
  final String status;
  const EditProposalScreen({super.key, required this.id, required this.status});

  @override
  State<EditProposalScreen> createState() => _EditProposalScreenState();
}

class _EditProposalScreenState extends State<EditProposalScreen> {
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _budgetCtrl   = TextEditingController();
  final _maxPartCtrl  = TextEditingController();
  bool _saving = false;
  bool _loading = true;
  bool _canEdit = true;

  @override
  void initState() {
    super.initState();
    _canEdit = widget.status == 'draft' || widget.status == 'in_review';
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('proposals').doc(widget.id).get();
      if (doc.exists) {
        final d = doc.data()!;
        _titleCtrl.text = d['title'] as String? ?? '';
        _descCtrl.text = d['description'] as String? ?? '';
        _locationCtrl.text = d['location'] as String? ?? '';
        _budgetCtrl.text = (d['budget'] as num?)?.toString() ?? '0.00';
        _maxPartCtrl.text = (d['maxParticipants'] as num?)?.toString() ?? '50';
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading proposal: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      );

  Widget _field(TextEditingController ctrl, String hint, {int maxLines = 1, TextInputType? keyboardType}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        enabled: _canEdit,
        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14)),
      );

  Future<void> _saveChanges() async {
    if (!_canEdit) return;
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('proposals').doc(widget.id).update({
        'title':     _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location':  _locationCtrl.text.trim(),
        'budget':    double.tryParse(_budgetCtrl.text) ?? 0,
        'maxParticipants': int.tryParse(_maxPartCtrl.text) ?? 50,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proposal updated successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('EDIT PROPOSAL', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Update Workshop Details', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Expanded(
              child: _loading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!_canEdit) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(child: Text('This proposal can no longer be edited', style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w600))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          _label('Workshop Title *'),
                          _field(_titleCtrl, 'e.g., PCB Soldering Workshop'),
                          const SizedBox(height: 16),
                          _label('Description *'),
                          _field(_descCtrl, 'Describe the workshop objectives...', maxLines: 4),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Budget (RM) *'), _field(_budgetCtrl, '0.00', keyboardType: TextInputType.number)])),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Max Participants *'), _field(_maxPartCtrl, '50', keyboardType: TextInputType.number)])),
                          ]),
                          const SizedBox(height: 16),
                          _label('Location *'),
                          _field(_locationCtrl, 'e.g., Engineering Lab 3'),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (!_canEdit || _saving) ? null : _saveChanges,
                              child: _saving
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                  : const Text('Save Changes'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
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
