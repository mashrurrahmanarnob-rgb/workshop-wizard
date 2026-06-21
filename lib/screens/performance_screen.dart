import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Performance Screen (President only) ──────────────────────────────────────
//
// Score formula (out of 100):
//   Approved proposals × 25  (max 50 pts, capped)
//   Completed tasks    × 10  (max 50 pts, capped)

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  String _sortBy = 'score';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: const BoxDecoration(
                color: AppColors.president,
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('MEMBER PERFORMANCE',
                      style: TextStyle(color: Colors.white, fontSize: 18,
                          fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  const Text('Committee performance overview',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sort chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                _SortChip(label: 'Top Score',  value: 'score',     current: _sortBy,
                    onTap: (v) => setState(() => _sortBy = v)),
                _SortChip(label: 'Name',       value: 'name',      current: _sortBy,
                    onTap: (v) => setState(() => _sortBy = v)),
                _SortChip(label: 'Proposals',  value: 'proposals', current: _sortBy,
                    onTap: (v) => setState(() => _sortBy = v)),
                _SortChip(label: 'Tasks Done', value: 'tasks',     current: _sortBy,
                    onTap: (v) => setState(() => _sortBy = v)),
              ]),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'committee')
                    .snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: AppColors.president));
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.people_outline, color: AppColors.textLight, size: 48),
                        SizedBox(height: 12),
                        Text('No committee members yet',
                            style: TextStyle(color: AppColors.textMedium, fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ]),
                    );
                  }
                  return _MemberPerformanceList(members: docs, sortBy: _sortBy);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Async member list ─────────────────────────────────────────────────────────

class _MemberPerformanceList extends StatefulWidget {
  final List<QueryDocumentSnapshot> members;
  final String sortBy;
  const _MemberPerformanceList({required this.members, required this.sortBy});

  @override
  State<_MemberPerformanceList> createState() => _MemberPerformanceListState();
}

class _MemberPerformanceListState extends State<_MemberPerformanceList> {
  List<_MemberStats>? _stats;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void didUpdateWidget(_MemberPerformanceList old) {
    super.didUpdateWidget(old);
    if (old.members != widget.members) _loadAll();
  }

  Future<void> _loadAll() async {
    final results = await Future.wait(
      widget.members.map((doc) => _fetchStats(doc)),
    );
    if (mounted) setState(() => _stats = results);
  }

  Future<_MemberStats> _fetchStats(QueryDocumentSnapshot doc) async {
    final uid  = doc.id;
    final data = doc.data() as Map<String, dynamic>;

    final results = await Future.wait([
      // Approved proposals
      FirebaseFirestore.instance
          .collection('proposals')
          .where('createdBy', isEqualTo: uid)
          .where('status', isEqualTo: 'approved')
          .count().get(),
      // Total proposals submitted (in_review + approved + rejected)
      FirebaseFirestore.instance
          .collection('proposals')
          .where('createdBy', isEqualTo: uid)
          .where('status', whereIn: ['in_review', 'approved', 'rejected'])
          .count().get(),
      // Completed tasks
      FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', isEqualTo: uid)
          .where('status', isEqualTo: 'Done')
          .count().get(),
      // Total tasks assigned
      FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', isEqualTo: uid)
          .count().get(),
    ]);

    final approved   = results[0].count ?? 0;
    final totalProps = results[1].count ?? 0;
    final tasksDone  = results[2].count ?? 0;
    final totalTasks = results[3].count ?? 0;

    // Score out of 100 — proposals max 50, tasks max 50
    final proposalPts = (approved  * 25).clamp(0, 50);
    final taskPts     = (tasksDone * 10).clamp(0, 50);
    final score       = (proposalPts + taskPts).clamp(0, 100);

    return _MemberStats(
      uid:         uid,
      name:        data['fullName'] as String? ?? '—',
      email:       data['email']    as String? ?? '',
      faculty:     data['faculty']  as String? ?? '',
      approved:    approved,
      totalProps:  totalProps,
      tasksDone:   tasksDone,
      totalTasks:  totalTasks,
      proposalPts: proposalPts,
      taskPts:     taskPts,
      score:       score,
    );
  }

  List<_MemberStats> _sorted(List<_MemberStats> list) {
    final copy = List<_MemberStats>.from(list);
    switch (widget.sortBy) {
      case 'name':      copy.sort((a, b) => a.name.compareTo(b.name));               break;
      case 'proposals': copy.sort((a, b) => b.approved.compareTo(a.approved));       break;
      case 'tasks':     copy.sort((a, b) => b.tasksDone.compareTo(a.tasksDone));     break;
      default:          copy.sort((a, b) => b.score.compareTo(a.score));             break;
    }
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    if (_stats == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.president));
    }
    final sorted = _sorted(_stats!);
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (c, i) => _MemberCard(stats: sorted[i], rank: i + 1),
    );
  }
}

// ─── Member Performance Card ───────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  final _MemberStats stats;
  final int rank;
  const _MemberCard({required this.stats, required this.rank});

  Color get _scoreColor {
    if (stats.score >= 80) return AppColors.primary;
    if (stats.score >= 50) return AppColors.president;
    return AppColors.admin;
  }

  @override
  Widget build(BuildContext context) {
    final initial = stats.name.isNotEmpty ? stats.name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => _MemberDetailScreen(stats: stats))),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          // Rank
          SizedBox(
            width: 28,
            child: Text('#$rank',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                    color: rank <= 3 ? AppColors.president : AppColors.textMedium)),
          ),
          const SizedBox(width: 8),

          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.committee.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(initial,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                    color: AppColors.committee))),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(stats.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              if (stats.faculty.isNotEmpty)
                Text(stats.faculty,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
              const SizedBox(height: 8),
              Row(children: [
                _MiniStat(icon: Icons.verified,  value: '${stats.approved}',
                    label: 'Approved', color: AppColors.primary),
                const SizedBox(width: 14),
                _MiniStat(icon: Icons.task_alt,  value: '${stats.tasksDone}',
                    label: 'Tasks',    color: AppColors.committee),
              ]),
            ]),
          ),

          // Score circle
          Column(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _scoreColor.withValues(alpha: 0.12),
                border: Border.all(color: _scoreColor.withValues(alpha: 0.4), width: 2),
              ),
              child: Center(child: Text('${stats.score}',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900,
                      color: _scoreColor))),
            ),
            const SizedBox(height: 4),
            const Text('Score', style: TextStyle(fontSize: 10, color: AppColors.textMedium)),
          ]),
        ]),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _MiniStat({required this.icon, required this.value,
    required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: color),
    const SizedBox(width: 3),
    Text('$value $label',
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
  ]);
}

// ─── Member Detail Screen ──────────────────────────────────────────────────────

class _MemberDetailScreen extends StatelessWidget {
  final _MemberStats stats;
  const _MemberDetailScreen({required this.stats});

  Color get _scoreColor {
    if (stats.score >= 80) return AppColors.primary;
    if (stats.score >= 50) return AppColors.president;
    return AppColors.admin;
  }

  String get _scoreLabel {
    if (stats.score >= 80) return 'Excellent';
    if (stats.score >= 60) return 'Good';
    if (stats.score >= 40) return 'Average';
    return 'Needs Improvement';
  }

  @override
  Widget build(BuildContext context) {
    final initial = stats.name.isNotEmpty ? stats.name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          // Header with back button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: const BoxDecoration(
              color: AppColors.president,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(child: Text(initial,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                        color: Colors.white))),
              ),
              const SizedBox(height: 12),
              Text(stats.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 4),
              Text(stats.email,
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
              if (stats.faculty.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(stats.faculty,
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
              ],
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Score card
                _Card(children: [
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Performance Score',
                            style: TextStyle(fontSize: 13, color: AppColors.textMedium,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Text('${stats.score} / 100',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                                color: _scoreColor)),
                        const SizedBox(height: 4),
                        Text(_scoreLabel,
                            style: TextStyle(fontSize: 13, color: _scoreColor,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    SizedBox(
                      width: 80, height: 80,
                      child: Stack(alignment: Alignment.center, children: [
                        SizedBox(
                          width: 80, height: 80,
                          child: CircularProgressIndicator(
                            value: stats.score / 100,
                            strokeWidth: 8,
                            backgroundColor: AppColors.divider,
                            valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
                          ),
                        ),
                        Text('${stats.score}%',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                                color: _scoreColor)),
                      ]),
                    ),
                  ]),
                ]),
                const SizedBox(height: 16),

                // Score breakdown
                _Card(children: [
                  const Text('Score Breakdown',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 6),
                  const Text('Based on proposals and tasks only',
                      style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
                  const SizedBox(height: 16),

                  _BreakdownRow(
                    icon: Icons.verified,
                    color: AppColors.primary,
                    label: 'Approved Proposals',
                    detail: '${stats.approved} approved out of ${stats.totalProps} submitted',
                    pts: stats.proposalPts,
                    maxPts: 50,
                  ),
                  const SizedBox(height: 16),
                  _BreakdownRow(
                    icon: Icons.task_alt,
                    color: AppColors.committee,
                    label: 'Tasks Completed',
                    detail: '${stats.tasksDone} done out of ${stats.totalTasks} assigned',
                    pts: stats.taskPts,
                    maxPts: 50,
                  ),
                ]),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});
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

class _BreakdownRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, detail;
  final int pts, maxPts;
  const _BreakdownRow({required this.icon, required this.color, required this.label,
    required this.detail, required this.pts, required this.maxPts});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: AppColors.textDark)),
          const SizedBox(height: 2),
          Text(detail, style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
        ])),
        Text('$pts / $maxPts pts',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      ]),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: maxPts > 0 ? pts / maxPts : 0,
          backgroundColor: AppColors.divider,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ),
    ],
  );
}

// ─── Sort chip ─────────────────────────────────────────────────────────────────

class _SortChip extends StatelessWidget {
  final String label, value, current;
  final void Function(String) onTap;
  const _SortChip({required this.label, required this.value,
    required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = current == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.president : AppColors.cardWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: active ? AppColors.president
                    : AppColors.textLight.withValues(alpha: 0.3)),
            boxShadow: active
                ? [BoxShadow(color: AppColors.president.withValues(alpha: 0.3),
                blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Text(label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.textMedium)),
        ),
      ),
    );
  }
}

// ─── Data model ────────────────────────────────────────────────────────────────

class _MemberStats {
  final String uid, name, email, faculty;
  final int approved, totalProps, tasksDone, totalTasks, proposalPts, taskPts, score;

  const _MemberStats({
    required this.uid, required this.name, required this.email, required this.faculty,
    required this.approved, required this.totalProps,
    required this.tasksDone, required this.totalTasks,
    required this.proposalPts, required this.taskPts, required this.score,
  });
}