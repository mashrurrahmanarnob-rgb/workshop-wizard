import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';


class TreasurerHomeScreen extends StatefulWidget {
  final String email;
  const TreasurerHomeScreen({super.key, required this.email});

  @override
  State<TreasurerHomeScreen> createState() => _TreasurerHomeScreenState();
}

class _TreasurerHomeScreenState extends State<TreasurerHomeScreen> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchStats();
  }

  Future<Map<String, dynamic>> _fetchStats() async {
    final fs = FirebaseFirestore.instance;

    double totalCollected = 0;
    int verified = 0, pending = 0;
    try {
      final snap = await fs.collection('payments').get();
      for (final doc in snap.docs) {
        final d      = doc.data();
        final status = (d['status'] as String? ?? '').toLowerCase();
        final amount = (d['amount'] as num?)?.toDouble() ?? 0;
        if (status == 'verified') {
          totalCollected += amount;
          verified++;
        } else if (status == 'pending') {
          pending++;
        }
      }
    } catch (_) {}

    int workshops = 0;
    try {
      final snap = await fs.collection('payments').get();
      final names = snap.docs
          .map((d) => d['workshopName'] as String? ?? '')
          .toSet();
      workshops = names.length;
    } catch (_) {}

    // Fetch treasury available balance
    double treasuryAvailable = 0;
    try {
      final treasurySnap = await fs.collection('treasury').doc('funds').get();
      treasuryAvailable = (treasurySnap.data()?['available'] as num?)?.toDouble() ?? 10000.0;
    } catch (_) {}

    return {
      'totalCollected': totalCollected,
      'treasuryAvailable': treasuryAvailable,
      'verified':       verified,
      'pending':        pending,
      'workshops':      workshops,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      primary: false,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => setState(() => _future = _fetchStats()),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('IEEE PES UTM',
                            style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500)),
                        Text('Workshop Wizard',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: const Icon(Icons.notifications_outlined, color: AppColors.textMedium, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Hero banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.75)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                              child: const Text('TREASURER PORTAL',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                            ),
                            const SizedBox(height: 10),
                            const Text('Welcome back!',
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(widget.email,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                          ],
                        ),
                      ),
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2)),
                        child: const Icon(Icons.person, color: Colors.white, size: 30),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Payment Overview',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 12),

                FutureBuilder<Map<String, dynamic>>(
                  future: _future,
                  builder: (ctx, snap) {
                    final loading   = snap.connectionState == ConnectionState.waiting;
                    final collected = ((snap.data?['totalCollected'] ?? 0.0) as num).toDouble();
                    final treasuryAvailable = ((snap.data?['treasuryAvailable'] ?? 0.0) as num).toDouble();
                    final verified  = snap.data?['verified']       ?? '—';
                    final pending   = snap.data?['pending']        ?? '—';
                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        StatCard(
                          label: 'Treasury Balance',
                          value: loading ? '…' : 'RM ${treasuryAvailable.toStringAsFixed(0)}',
                          icon: Icons.account_balance_wallet,
                          color: AppColors.primary,
                        ),
                        StatCard(
                          label: 'Total Collected',
                          value: loading ? '…' : 'RM ${collected.toStringAsFixed(0)}',
                          icon: Icons.payments,
                          color: AppColors.student,
                        ),
                        StatCard(label: 'Verified',   value: loading ? '…' : '$verified',  icon: Icons.verified_user,   color: AppColors.president),
                        StatCard(label: 'Pending',    value: loading ? '…' : '$pending',   icon: Icons.hourglass_empty, color: AppColors.committee),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                const Text('Recent Activity',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 12),
                _RecentActivityList(roleColor: AppColors.primary),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  final Color roleColor;
  const _RecentActivityList({required this.roleColor});

  String _relativeTime(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('activity_logs')
          .orderBy('createdAt', descending: true)
          .limit(4)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('No recent activity',
                  style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: docs.asMap().entries.map((entry) {
              final i    = entry.key;
              final d    = entry.value.data() as Map<String, dynamic>;
              final title   = d['title']     as String? ?? '';
              final sub     = d['subtitle']  as String? ?? '';
              final timeStr = _relativeTime(d['createdAt'] as Timestamp?);
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Icon(Icons.circle_notifications_outlined, color: roleColor, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                              const SizedBox(height: 2),
                              Text(sub,   style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(8)),
                          child: Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textMedium, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                  if (i < docs.length - 1)
                    const Divider(height: 1, indent: 66, color: AppColors.divider),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}