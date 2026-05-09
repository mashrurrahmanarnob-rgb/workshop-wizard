import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

// ─── Payments Dashboard ────────────────────────────────────────────────────────

class PaymentsScreen extends StatelessWidget {
  final String role;
  const PaymentsScreen({super.key, required this.role});

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
                          style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500)),
                      Text('Payments',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                      Text('Verify workshop payments',
                          style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                    ],
                  ),
                  const Icon(Icons.attach_money, color: AppColors.primary, size: 26),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Live grouped list ───────────────────────────────────────────────
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
                  if (docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.credit_card_off, color: AppColors.textLight, size: 48),
                          SizedBox(height: 12),
                          Text('No payment records yet', style: TextStyle(color: AppColors.textMedium, fontSize: 15, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }

                  // Group by workshopName
                  final Map<String, WorkshopGroup> groups = {};
                  for (final doc in docs) {
                    final d    = doc.data() as Map<String, dynamic>;
                    final name = d['workshopName'] as String? ?? 'Unknown Workshop';
                    final amt  = (d['amount'] as num?)?.toDouble() ?? 0;
                    final st   = (d['status'] as String? ?? 'pending').toLowerCase();
                    final uid  = d['userId'] as String? ?? '';

                    groups.putIfAbsent(name, () => WorkshopGroup(name: name));
                    groups[name]!.add(
                      docId: doc.id,
                      amount: amt,
                      status: st,
                      userId: uid,
                      data: d,
                    );
                  }
                  final workshopList = groups.values.toList();

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: workshopList.length,
                    separatorBuilder: (_, idx) => const SizedBox(height: 12),
                    itemBuilder: (c, i) => _WorkshopPaymentCard(group: workshopList[i]),
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

// ─── Group model (built from Firestore docs) ───────────────────────────────────

class WorkshopGroup {
  final String name;
  double totalCollected = 0;
  int verified = 0;
  int pending  = 0;
  final List<Map<String, dynamic>> participants = [];

  WorkshopGroup({required this.name});

  void add({required String docId, required double amount, required String status, required String userId, required Map<String, dynamic> data}) {
    if (status == 'verified') {
      totalCollected += amount;
      verified++;
    } else if (status == 'pending') {
      pending++;
    }
    participants.add({...data, 'docId': docId});
  }

  String get totalLabel => 'RM ${totalCollected.toStringAsFixed(0)}';
  int get total => verified + pending;
}

// ─── Workshop Payment Card ─────────────────────────────────────────────────────

class _WorkshopPaymentCard extends StatelessWidget {
  final WorkshopGroup group;
  const _WorkshopPaymentCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => PaymentDetailScreen(group: group))),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: const Border(left: BorderSide(color: AppColors.primary, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(group.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark))),
                const Icon(Icons.arrow_forward, color: AppColors.primary, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Collected:', style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                Text(group.totalLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                PaymentBadge(label: 'Verified', count: '${group.verified}', color: AppColors.primary),
                Container(width: 1, height: 28, color: AppColors.divider),
                PaymentBadge(label: 'Pending',  count: '${group.pending}',  color: AppColors.president),
                Container(width: 1, height: 28, color: AppColors.divider),
                PaymentBadge(label: 'Total',    count: '${group.total}',    color: AppColors.textMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Payment Detail Screen ─────────────────────────────────────────────────────

class PaymentDetailScreen extends StatelessWidget {
  final WorkshopGroup group;
  const PaymentDetailScreen({super.key, required this.group});

  Color _statusColor(String s) {
    switch (s) {
      case 'verified': return AppColors.primary;
      case 'rejected': return AppColors.admin;
      default:         return AppColors.president;
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
                  Text(group.name, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),

            // Summary card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    PaymentBadge(label: 'Collected', count: group.totalLabel, color: AppColors.primary),
                    Container(width: 1, height: 28, color: AppColors.divider),
                    PaymentBadge(label: 'Verified',  count: '${group.verified}', color: AppColors.primary),
                    Container(width: 1, height: 28, color: AppColors.divider),
                    PaymentBadge(label: 'Pending',   count: '${group.pending}',  color: AppColors.president),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Participants list with live status update
            Expanded(
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: group.participants.length,
                separatorBuilder: (_, idx) => const SizedBox(height: 10),
                itemBuilder: (c, i) {
                  final p       = group.participants[i];
                  final docId   = p['docId']   as String? ?? '';
                  final name    = p['userId']  as String? ?? 'Unknown';
                  final amount  = (p['amount'] as num?)?.toDouble() ?? 0;
                  final status  = (p['status'] as String? ?? 'pending').toLowerCase();
                  final matNo   = p['matrixNo'] as String? ?? '';
                  return _ParticipantRow(
                    docId: docId,
                    name: name,
                    matrixNo: matNo,
                    amount: 'RM ${amount.toStringAsFixed(2)}',
                    status: status,
                    statusColor: _statusColor(status),
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

// ─── Participant Row with verify/reject actions ────────────────────────────────

class _ParticipantRow extends StatelessWidget {
  final String docId;
  final String name;
  final String matrixNo;
  final String amount;
  final String status;
  final Color statusColor;
  const _ParticipantRow({required this.docId, required this.name, required this.matrixNo, required this.amount, required this.status, required this.statusColor});

  Future<void> _updateStatus(String newStatus) async {
    await FirebaseFirestore.instance.collection('payments').doc(docId).update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                if (matrixNo.isNotEmpty) Text(matrixNo, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ],
            ),
          ),
          if (status == 'pending') ...[
            IconButton(
              onPressed: () => _updateStatus('verified'),
              icon: const Icon(Icons.check_circle_outline, color: AppColors.primary),
              tooltip: 'Verify',
            ),
            IconButton(
              onPressed: () => _updateStatus('rejected'),
              icon: const Icon(Icons.cancel_outlined, color: AppColors.admin),
              tooltip: 'Reject',
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}
