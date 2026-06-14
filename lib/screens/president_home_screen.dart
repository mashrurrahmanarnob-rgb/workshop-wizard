import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'role_management_screen.dart';
import 'performance_screen.dart';
import 'notifications_screen.dart';

class PresidentHomeScreen extends StatefulWidget {
  final String email;
  const PresidentHomeScreen({super.key, required this.email});

  @override
  State<PresidentHomeScreen> createState() => _PresidentHomeScreenState();
}

class _PresidentHomeScreenState extends State<PresidentHomeScreen> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchStats();
  }

  Future<Map<String, dynamic>> _fetchStats() async {
    final fs = FirebaseFirestore.instance;

    int pendingProposals  = 0;
    int approvedProposals = 0;
    int totalMembers      = 0;
    int upcomingEvents    = 0;
    int pendingTasks      = 0;

    await Future.wait([
      fs.collection('proposals').where('status', isEqualTo: 'in_review').count().get()
          .then((s) => pendingProposals  = s.count ?? 0).catchError((_) {}),
      fs.collection('proposals').where('status', isEqualTo: 'approved').count().get()
          .then((s) => approvedProposals = s.count ?? 0).catchError((_) {}),
      fs.collection('users').where('role', whereIn: ['student', 'committee', 'treasurer']).count().get()
          .then((s) => totalMembers      = s.count ?? 0).catchError((_) {}),
      fs.collection('events').where('status', isEqualTo: 'upcoming').count().get()
          .then((s) => upcomingEvents    = s.count ?? 0).catchError((_) {}),
      fs.collection('tasks').where('status', whereIn: ['To Do', 'In Progress']).count().get()
          .then((s) => pendingTasks      = s.count ?? 0).catchError((_) {}),
    ]);

    return {
      'pendingProposals':  pendingProposals,
      'approvedProposals': approvedProposals,
      'totalMembers':      totalMembers,
      'upcomingEvents':    upcomingEvents,
      'pendingTasks':      pendingTasks,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      primary: false,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.president,
          onRefresh: () async => setState(() => _future = _fetchStats()),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App bar row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('IEEE PES UTM',
                          style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500)),
                      Text('Workshop Wizard',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    ]),
                    // Notification bell with unread badge
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
                      colors: [AppColors.president, AppColors.president.withValues(alpha: 0.75)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppColors.president.withValues(alpha: 0.35),
                        blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20)),
                          child: const Text('PRESIDENT PORTAL',
                              style: TextStyle(color: Colors.white, fontSize: 10,
                                  fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                        ),
                        const SizedBox(height: 10),
                        const Text('Welcome back!',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(widget.email,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                      ]),
                    ),
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2)),
                      child: const Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                // Stats
                const Text('Overview',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 12),

                FutureBuilder<Map<String, dynamic>>(
                  future: _future,
                  builder: (ctx, snap) {
                    final loading  = snap.connectionState == ConnectionState.waiting;
                    final pending  = snap.data?['pendingProposals']  ?? '—';
                    final approved = snap.data?['approvedProposals'] ?? '—';
                    final members  = snap.data?['totalMembers']      ?? '—';
                    final events   = snap.data?['upcomingEvents']    ?? '—';
                    final tasks    = snap.data?['pendingTasks']      ?? '—';

                    return Column(children: [
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12, mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                        children: [
                          _StatCard(label: 'Pending Review',  value: loading ? '…' : '$pending',
                              icon: Icons.pending_actions,   color: AppColors.president),
                          _StatCard(label: 'Approved',        value: loading ? '…' : '$approved',
                              icon: Icons.verified,          color: AppColors.primary),
                          _StatCard(label: 'Total Members',   value: loading ? '…' : '$members',
                              icon: Icons.people_alt,        color: AppColors.student),
                          _StatCard(label: 'Upcoming Events', value: loading ? '…' : '$events',
                              icon: Icons.event,             color: AppColors.committee),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Active tasks — full width
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.president.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.assignment_outlined,
                                color: AppColors.president, size: 22),
                          ),
                          const SizedBox(width: 16),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(loading ? '…' : '$tasks',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                                    color: AppColors.president)),
                            const Text('Active Tasks (To Do + In Progress)',
                                style: TextStyle(fontSize: 12, color: AppColors.textMedium,
                                    fontWeight: FontWeight.w500)),
                          ]),
                        ]),
                      ),
                    ]);
                  },
                ),
                const SizedBox(height: 24),

                // Quick actions
                const Text('Quick Actions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 12),

                _QuickAction(
                  icon: Icons.manage_accounts, color: AppColors.president,
                  title: 'User Management', subtitle: 'Manage roles and member access',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RoleManagementScreen(showBackButton: true))),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                _QuickAction(
                  icon: Icons.bar_chart_rounded, color: AppColors.student,
                  title: 'Member Performance', subtitle: 'View committee performance scores',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PerformanceScreen())),
                ),
                const SizedBox(height: 24),

                // Recent activity
                const Text('Recent Activity',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 12),
                _RecentActivityList(roleColor: AppColors.president),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Quick Action Card ─────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.color, required this.title,
    required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
              color: AppColors.textDark)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
        ])),
        const Icon(Icons.arrow_forward_ios, color: AppColors.textLight, size: 16),
      ]),
    ),
  );
}

// ─── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 40, height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20)),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMedium,
          fontWeight: FontWeight.w500)),
    ]),
  );
}

// ─── Recent activity list ──────────────────────────────────────────────────────

class _RecentActivityList extends StatelessWidget {
  final Color roleColor;
  const _RecentActivityList({required this.roleColor});

  String _relativeTime(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('activity_logs')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16)),
            child: const Center(child: Text('No recent activity',
                style: TextStyle(color: AppColors.textMedium, fontSize: 13))),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: docs.asMap().entries.map((entry) {
              final i   = entry.key;
              final d   = entry.value.data() as Map<String, dynamic>;
              final timeStr = _relativeTime(d['createdAt'] as Timestamp?);
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle),
                      child: Icon(Icons.circle_notifications_outlined, color: roleColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d['title'] as String? ?? '',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: AppColors.textDark)),
                      const SizedBox(height: 2),
                      Text(d['subtitle'] as String? ?? '',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.inputBg,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(timeStr,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMedium,
                              fontWeight: FontWeight.w500)),
                    ),
                  ]),
                ),
                if (i < docs.length - 1)
                  const Divider(height: 1, indent: 66, color: AppColors.divider),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }
}