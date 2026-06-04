import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/activity_service.dart';

class PaymentsScreen extends StatefulWidget {
  final String role;
  const PaymentsScreen({super.key, required this.role});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'all'; // all, pending, verified, rejected

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('IEEE PES UTM',
                            style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500)),
                        Text('Payment Verification',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                        Text('Review and verify student payments',
                            style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.attach_money, color: AppColors.primary, size: 24),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search by name, student ID, or event...',
                  hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                  filled: true,
                  fillColor: AppColors.cardWhite,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _filterChip('Pending', 'pending'),
                    const SizedBox(width: 8),
                    _filterChip('Verified', 'verified'),
                    const SizedBox(width: 8),
                    _filterChip('Rejected', 'rejected'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Payments list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('payments')
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

                  // Filter by status and search
                  final filtered = docs.where((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final status = (d['status'] as String? ?? 'pending').toLowerCase();
                    final name = (d['studentName'] as String? ?? '').toLowerCase();
                    final sid = (d['studentId'] as String? ?? '').toLowerCase();
                    final event = (d['eventName'] as String? ?? d['workshopName'] as String? ?? '').toLowerCase();

                    final matchesFilter = _filter == 'all' || status == _filter;
                    final matchesSearch = _query.isEmpty || name.contains(_query) || sid.contains(_query) || event.contains(_query);
                    return matchesFilter && matchesSearch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.credit_card_off, color: AppColors.textLight, size: 48),
                          SizedBox(height: 12),
                          Text('No payments found', style: TextStyle(color: AppColors.textMedium, fontSize: 15, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (c, i) => _PaymentCard(doc: filtered[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isActive = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.cardWhite,
      labelStyle: TextStyle(
        color: isActive ? Colors.white : AppColors.textMedium,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      showCheckmark: false,
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _PaymentCard({required this.doc});

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'verified': return AppColors.primary;
      case 'rejected': return AppColors.admin;
      default:         return AppColors.president;
    }
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'N/A';
    final d = ts.toDate();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('payments').doc(doc.id).update({
        'status': newStatus,
        if (newStatus == 'verified') ...{
          'verifiedAt': FieldValue.serverTimestamp(),
        },
      });
      // Also update event_registrations
      final regSnap = await FirebaseFirestore.instance
          .collection('event_registrations')
          .where('userId', isEqualTo: (doc.data() as Map<String, dynamic>)['userId'])
          .where('eventId', isEqualTo: (doc.data() as Map<String, dynamic>)['eventId'])
          .limit(1)
          .get();
      if (regSnap.docs.isNotEmpty) {
        await regSnap.docs.first.reference.update({
          'status': newStatus,
          'paymentStatus': newStatus == 'verified' ? 'paid' : newStatus == 'rejected' ? 'rejected' : 'pending',
          if (newStatus == 'verified') 'verifiedAt': FieldValue.serverTimestamp(),
        });
      }
      await logActivity(
        newStatus == 'verified' ? 'Payment Verified' : 'Payment Rejected',
        '${(doc.data() as Map<String, dynamic>)['studentName'] ?? 'Unknown'} — ${(doc.data() as Map<String, dynamic>)['eventName'] ?? ''}',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment ${newStatus == 'verified' ? 'verified' : 'rejected'}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.admin),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = doc.data() as Map<String, dynamic>;
    final name = d['studentName'] as String? ?? d['userId'] as String? ?? 'Unknown';
    final studentId = d['studentId'] as String? ?? d['matrixNo'] as String? ?? '';
    final eventName = d['eventName'] as String? ?? d['workshopName'] as String? ?? 'Unknown Event';
    final amount = (d['amount'] as num?)?.toDouble() ?? 0;
    final status = (d['status'] as String? ?? 'pending').toLowerCase();
    final createdAt = d['createdAt'] as Timestamp?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 2),
                    Text(studentId, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                    const SizedBox(height: 4),
                    Text(eventName, style: const TextStyle(fontSize: 13, color: AppColors.student, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status == 'verified' ? Icons.check_circle_outline : status == 'rejected' ? Icons.cancel_outlined : Icons.access_time,
                      size: 14,
                      color: _statusColor(status),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(fontSize: 12, color: _statusColor(status), fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Amount', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                    Text('RM ${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Submitted', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                    Text(_formatDate(createdAt), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PaymentDetailScreen(docId: doc.id, data: d),
                  )),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMedium,
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (status == 'pending') ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(context, 'verified'),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Verify'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(context, 'rejected'),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.admin,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Payment Detail Screen ─────────────────────────────────────────────────────

class PaymentDetailScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const PaymentDetailScreen({super.key, required this.docId, required this.data});

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'verified': return AppColors.primary;
      case 'rejected': return AppColors.admin;
      default:         return AppColors.president;
    }
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'N/A';
    final d = ts.toDate();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('payments').doc(docId).update({
        'status': newStatus,
        if (newStatus == 'verified') 'verifiedAt': FieldValue.serverTimestamp(),
      });
      final regSnap = await FirebaseFirestore.instance
          .collection('event_registrations')
          .where('userId', isEqualTo: data['userId'])
          .where('eventId', isEqualTo: data['eventId'])
          .limit(1)
          .get();
      if (regSnap.docs.isNotEmpty) {
        await regSnap.docs.first.reference.update({
          'status': newStatus,
          'paymentStatus': newStatus == 'verified' ? 'paid' : 'pending',
          if (newStatus == 'verified') 'verifiedAt': FieldValue.serverTimestamp(),
        });
      }
      await logActivity(
        newStatus == 'verified' ? 'Payment Verified' : 'Payment Rejected',
        '${data['studentName'] ?? 'Unknown'} — ${data['eventName'] ?? ''}',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment ${newStatus == 'verified' ? 'verified' : 'rejected'}')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.admin),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = data['studentName'] as String? ?? 'Unknown';
    final studentId = data['studentId'] as String? ?? data['matrixNo'] as String? ?? '';
    final email = data['email'] as String? ?? '';
    final phone = data['phone'] as String? ?? '';
    final department = data['department'] as String? ?? '';
    final eventName = data['eventName'] as String? ?? data['workshopName'] as String? ?? 'Unknown Event';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final status = (data['status'] as String? ?? 'pending').toLowerCase();
    final createdAt = data['createdAt'] as Timestamp?;
    final verifiedAt = data['verifiedAt'] as Timestamp?;
    final proofUrl = data['paymentProofUrl'] as String? ?? '';
    final isPending = status == 'pending';

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
                  const Text('PAYMENT DETAILS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(eventName, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                status == 'verified' ? Icons.check_circle : status == 'rejected' ? Icons.cancel : Icons.access_time,
                                color: _statusColor(status),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                status[0].toUpperCase() + status.substring(1),
                                style: TextStyle(color: _statusColor(status), fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Student info
                    _sectionHeader('Student Information'),
                    const SizedBox(height: 12),
                    _infoCard([
                      _infoRow('Full Name', name),
                      _infoRow('Student ID', studentId),
                      _infoRow('Email', email),
                      _infoRow('Phone', phone),
                      _infoRow('Department', department),
                    ]),
                    const SizedBox(height: 20),

                    // Event & Payment
                    _sectionHeader('Event & Payment'),
                    const SizedBox(height: 12),
                    _infoCard([
                      _infoRow('Event', eventName),
                      _infoRow('Amount', 'RM ${amount.toStringAsFixed(2)}'),
                      _infoRow('Submitted', _formatDate(createdAt)),
                      if (verifiedAt != null) _infoRow('Verified', _formatDate(verifiedAt)),
                    ]),
                    const SizedBox(height: 20),

                    // Payment proof
                    if (proofUrl.isNotEmpty) ...[
                      _sectionHeader('Payment Proof'),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildProofImage(proofUrl),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            if (isPending)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus(context, 'verified'),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Verify Payment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus(context, 'rejected'),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.admin,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) => Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark));

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildProofImage(String proofUrl) {
    if (proofUrl.startsWith('data:image') || proofUrl.startsWith('/9j/') || proofUrl.startsWith('iVBOR')) {
      // Base64 image
      try {
        final bytes = base64Decode(proofUrl);
        return Image.memory(Uint8List.fromList(bytes), fit: BoxFit.cover, width: double.infinity);
      } catch (_) {
        return _placeholderImage();
      }
    }
    // URL
    if (proofUrl.startsWith('http')) {
      return Image.network(proofUrl, fit: BoxFit.cover, width: double.infinity,
        loadingBuilder: (_, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, _, _) => _placeholderImage(),
      );
    }
    return _placeholderImage();
  }

  Widget _placeholderImage() {
    return Container(
      height: 200,
      color: AppColors.inputBg,
      child: const Center(child: Icon(Icons.image_not_supported, color: AppColors.textLight, size: 48)),
    );
  }
}
