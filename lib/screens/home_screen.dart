import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'role_management_screen.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

class _HomeData {
  final List<Map<String, dynamic>> stats;
  final Map<String, int> roleCounts;
  final int totalUsers;

  const _HomeData({
    required this.stats,
    this.roleCounts = const {},
    this.totalUsers = 0,
  });
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _relativeTime(Timestamp? ts) {
  if (ts == null) return '';
  final diff = DateTime.now().difference(ts.toDate());
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  final String role;
  final String email;

  const HomeScreen({super.key, required this.role, required this.email});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<_HomeData>? _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchData();
  }

  // ── Fallback static data ───────────────────────────────────────────────────

  List<Map<String, dynamic>> _fallbackStats() {
    switch (widget.role.toLowerCase()) {
      case 'admin':
        return [
          {'label': 'Total Users',    'value': '—',      'icon': Icons.people_alt,          'color': AppColors.admin},
          {'label': 'Active Sessions','value': '—',      'icon': Icons.wifi,                'color': AppColors.student},
          {'label': 'System Health',  'value': '99%',    'icon': Icons.health_and_safety,   'color': AppColors.primary},
          {'label': 'Alerts',         'value': '0',      'icon': Icons.notifications_active,'color': AppColors.president},
        ];
      case 'president':
        return [
          {'label': 'Pending Reviews','value': '7',      'icon': Icons.pending_actions,     'color': AppColors.president},
          {'label': 'Approved',       'value': '12',     'icon': Icons.verified,            'color': AppColors.primary},
          {'label': 'Workshops',      'value': '5',      'icon': Icons.school,              'color': AppColors.student},
          {'label': 'Budget Used',    'value': 'RM 450', 'icon': Icons.account_balance_wallet,'color': AppColors.committee},
        ];
      case 'committee':
        return [
          {'label': 'My Tasks',       'value': '8',      'icon': Icons.task_alt,            'color': AppColors.committee},
          {'label': 'Completed',      'value': '23',     'icon': Icons.check_circle,        'color': AppColors.primary},
          {'label': 'Upcoming',       'value': '3',      'icon': Icons.calendar_month,      'color': AppColors.student},
          {'label': 'Team Members',   'value': '15',     'icon': Icons.group,               'color': AppColors.president},
        ];
      case 'treasurer':
        return [
          {'label': 'Total Collected','value': 'RM 405', 'icon': Icons.payments,            'color': AppColors.primary},
          {'label': 'Pending',        'value': '16',     'icon': Icons.hourglass_empty,     'color': AppColors.president},
          {'label': 'Verified',       'value': '27',     'icon': Icons.verified_user,       'color': AppColors.student},
          {'label': 'Workshops',      'value': '2',      'icon': Icons.event,               'color': AppColors.committee},
        ];
      default:
        return [
          {'label': 'Workshops',      'value': '12',     'icon': Icons.school,              'color': AppColors.student},
          {'label': 'Proposals',      'value': '3',      'icon': Icons.description,         'color': AppColors.primary},
          {'label': 'Payments Due',   'value': '1',      'icon': Icons.credit_card,         'color': AppColors.president},
          {'label': 'Badges Earned',  'value': '5',      'icon': Icons.emoji_events,        'color': AppColors.committee},
        ];
    }
  }

  // ── Firestore fetch ────────────────────────────────────────────────────────

  Future<_HomeData> _fetchData() async {
    final fs = FirebaseFirestore.instance;
    final r  = widget.role.toLowerCase();

    try {
      // ── Admin-specific ─────────────────────────────────────────────────────
      if (r == 'admin') {
        // 1. Fetch all users
        final usersSnap = await fs.collection('users').get();
        final totalUsers = usersSnap.size;

        // 2. Role distribution counts
        final roleCounts = <String, int>{
          'student': 0, 'committee': 0, 'president': 0,
          'treasurer': 0, 'admin': 0,
        };
        for (final doc in usersSnap.docs) {
          final roleField =
              ((doc.data()['role'] as String?) ?? 'student').toLowerCase();
          roleCounts[roleField] = (roleCounts[roleField] ?? 0) + 1;
        }

        // 3. Active sessions (lastSeen within 30 min)
        int activeSessions = 0;
        try {
          final cutoff = Timestamp.fromDate(
              DateTime.now().subtract(const Duration(minutes: 30)));
          final activeSnap = await fs
              .collection('users')
              .where('lastSeen', isGreaterThan: cutoff)
              .count()
              .get();
          activeSessions = activeSnap.count ?? 0;
        } catch (_) {}

        // 4. Alerts
        int alerts = 0;
        try {
          final alertSnap = await fs.collection('alerts').count().get();
          alerts = alertSnap.count ?? 0;
        } catch (_) {}

        final stats = [
          {'label': 'Total Users',    'value': '$totalUsers',    'icon': Icons.people_alt,          'color': AppColors.admin},
          {'label': 'Active Sessions','value': '$activeSessions','icon': Icons.wifi,                'color': AppColors.student},
          {'label': 'System Health',  'value': '99%',            'icon': Icons.health_and_safety,   'color': AppColors.primary},
          {'label': 'Alerts',         'value': '$alerts',        'icon': Icons.notifications_active,'color': AppColors.president},
        ];

        return _HomeData(
          stats: stats,
          roleCounts: roleCounts,
          totalUsers: totalUsers,
        );
      }

      // ── Non-admin: keep fallback stats, use live activities ────────────────
      return _HomeData(
        stats: _fallbackStats(),
      );
    } catch (_) {
      // Full fallback on error
      return _HomeData(
        stats: _fallbackStats(),
        roleCounts: const {
          'student': 128, 'committee': 15, 'president': 1,
          'treasurer': 2, 'admin': 3,
        },
        totalUsers: 149,
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            primary: false,
            backgroundColor: AppColors.background,
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final data = snap.data ??
            _HomeData(
              stats: _fallbackStats(),
              roleCounts: const {
                'student': 128, 'committee': 15, 'president': 1,
                'treasurer': 2, 'admin': 3,
              },
              totalUsers: 149,
            );

        return _HomeContent(
          role:       widget.role,
          email:      widget.email,
          data:       data,
          onRefresh:  () => setState(() => _future = _fetchData()),
        );
      },
    );
  }
}

// ─── Content widget (pure UI) ─────────────────────────────────────────────────

class _HomeContent extends StatelessWidget {
  final String role;
  final String email;
  final _HomeData data;
  final VoidCallback onRefresh;

  const _HomeContent({
    required this.role,
    required this.email,
    required this.data,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor  = AppTheme.roleColor(role);
    final stats      = data.stats;
    final isAdmin    = role.toLowerCase() == 'admin';

    return Scaffold(
      primary: false,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => onRefresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── App bar row ──────────────────────────────────────────────
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

                // ── Hero banner ──────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [roleColor, roleColor.withValues(alpha: 0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: roleColor.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
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
                              child: Text(AppTheme.roleLabel(role).toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                            ),
                            const SizedBox(height: 10),
                            const Text('Welcome back!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(email, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
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

                // ── Overview grid ────────────────────────────────────────────
                const Text('Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: stats.map((s) => StatCard(
                    label: s['label'] as String,
                    value: s['value'] as String,
                    icon:  s['icon']  as IconData,
                    color: s['color'] as Color,
                  )).toList(),
                ),
                const SizedBox(height: 24),

                // ── Admin: Quick Actions ────────────────────────────────────
                if (isAdmin) ...[
                  Row(
                    children: [
                      Expanded(child: _QuickActionButton(
                        label: 'Manage Roles', icon: Icons.manage_accounts, color: AppColors.admin,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoleManagementScreen())),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _QuickActionButton(
                        label: 'System Settings', icon: Icons.settings, color: const Color(0xFF1A1A2E), onTap: () {},
                      )),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Role Distribution
                  const Text('User Role Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        _RoleBar(label: 'Student',   count: data.roleCounts['student']   ?? 0, total: data.totalUsers, color: AppColors.student),
                        const SizedBox(height: 14),
                        _RoleBar(label: 'Committee', count: data.roleCounts['committee'] ?? 0, total: data.totalUsers, color: AppColors.committee),
                        const SizedBox(height: 14),
                        _RoleBar(label: 'President', count: data.roleCounts['president'] ?? 0, total: data.totalUsers, color: AppColors.president),
                        const SizedBox(height: 14),
                        _RoleBar(label: 'Treasurer', count: data.roleCounts['treasurer'] ?? 0, total: data.totalUsers, color: AppColors.primary),
                        const SizedBox(height: 14),
                        _RoleBar(label: 'Admin',     count: data.roleCounts['admin']     ?? 0, total: data.totalUsers, color: AppColors.admin),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Recent Activity ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    Text('See all', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('activity_logs')
                      .orderBy('createdAt', descending: true)
                      .limit(4)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primary)));
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading activities', style: TextStyle(color: AppColors.textMedium)));
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: const Center(child: Text('No recent activity', style: TextStyle(color: AppColors.textMedium, fontSize: 13, fontWeight: FontWeight.w500))),
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
                          final i = entry.key;
                          final data = entry.value.data() as Map<String, dynamic>;
                          final title = data['title'] as String? ?? '';
                          final sub = data['subtitle'] as String? ?? ''; // subtitle field
                          final timeStr = _relativeTime(data['createdAt'] as Timestamp?);

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38, height: 38,
                                      decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.10), shape: BoxShape.circle),
                                      child: Icon(Icons.circle_notifications_outlined, color: roleColor, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                                          const SizedBox(height: 2),
                                          Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
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
                ),

                // ── Admin: System Status ─────────────────────────────────────
                if (isAdmin) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.monitor_heart, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          const Text('System Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                        ]),
                        const SizedBox(height: 16),
                        const _SystemStatusRow(label: 'Database',    value: 'Healthy',     isBadge: true,  badgeColor: AppColors.primary),
                        const Divider(height: 20, color: AppColors.divider),
                        const _SystemStatusRow(label: 'API Services', value: 'Online',     isBadge: true,  badgeColor: AppColors.primary),
                        const Divider(height: 20, color: AppColors.divider),
                        const _SystemStatusRow(label: 'Last Backup', value: '2 hours ago', isBadge: false, badgeColor: AppColors.primary),
                        const Divider(height: 20, color: AppColors.divider),
                        const _SystemStatusRow(label: 'Uptime',      value: '99.8%',       isBadge: false, badgeColor: AppColors.primary),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Private helpers ───────────────────────────────────────────────────────────

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _RoleBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _RoleBar({required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 10),
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark))),
        Container(
          width: 62,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(8)),
          child: Text('$count users', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.textMedium, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.toDouble(),
              minHeight: 6,
              backgroundColor: AppColors.inputBg,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}

class _SystemStatusRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBadge;
  final Color badgeColor;
  const _SystemStatusRow({required this.label, required this.value, required this.isBadge, required this.badgeColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textMedium)),
        if (isBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(20)),
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          )
        else
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      ],
    );
  }
}
