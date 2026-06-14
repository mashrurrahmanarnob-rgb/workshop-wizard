import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'notifications_screen.dart';

class CommitteeHomeScreen extends StatefulWidget {
  final String email;
  const CommitteeHomeScreen({super.key, required this.email});

  @override
  State<CommitteeHomeScreen> createState() => _CommitteeHomeScreenState();
}

class _CommitteeHomeScreenState extends State<CommitteeHomeScreen> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchStats();
  }

  Future<Map<String, dynamic>> _fetchStats() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final fs  = FirebaseFirestore.instance;

    int myProposals = 0, approved = 0, inReview = 0;
    try {
      if (uid != null) {
        final all = await fs.collection('proposals').where('createdBy', isEqualTo: uid).get();
        myProposals = all.size;
        approved = all.docs.where((d) => d['status'] == 'approved').length;
        inReview = all.docs.where((d) => d['status'] == 'in_review').length;
      }
    } catch (_) {}

    int upcomingEvents = 0;
    try {
      final snap = await fs.collection('events').where('status', isEqualTo: 'upcoming').count().get();
      upcomingEvents = snap.count ?? 0;
    } catch (_) {}

    return {
      'myProposals':   myProposals,
      'approved':      approved,
      'inReview':      inReview,
      'upcomingEvents': upcomingEvents,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      primary: false,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.committee,
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
                    const NotificationBell(color: AppColors.textMedium),
                  ],
                ),
                const SizedBox(height: 20),

                // Hero banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.committee, AppColors.committee.withValues(alpha: 0.75)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppColors.committee.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
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
                              child: const Text('COMMITTEE PORTAL',
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

                const Text('My Overview',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 12),

                FutureBuilder<Map<String, dynamic>>(
                  future: _future,
                  builder: (ctx, snap) {
                    final loading = snap.connectionState == ConnectionState.waiting;
                    final my       = snap.data?['myProposals']   ?? '—';
                    final approved = snap.data?['approved']      ?? '—';
                    final inReview = snap.data?['inReview']      ?? '—';
                    final events   = snap.data?['upcomingEvents'] ?? '—';

                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        StatCard(label: 'My Proposals',    value: loading ? '…' : '$my',       icon: Icons.description,      color: AppColors.committee),
                        StatCard(label: 'Approved',        value: loading ? '…' : '$approved', icon: Icons.verified,         color: AppColors.primary),
                        StatCard(label: 'In Review',       value: loading ? '…' : '$inReview', icon: Icons.pending_actions,  color: AppColors.president),
                        StatCard(label: 'Upcoming Events', value: loading ? '…' : '$events',   icon: Icons.event,            color: AppColors.student),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                const Text('Recent Activity',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 12),
                _RecentActivityList(roleColor: AppColors.committee),
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