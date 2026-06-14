import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/activity_service.dart';
import '../services/notification_service.dart';

// ─── Constants ─────────────────────────────────────────────────────────────────

const _priorities = ['Low', 'Medium', 'High'];
const _statuses   = ['To Do', 'In Progress', 'Done'];

Color _priorityColor(String p) {
  switch (p.toLowerCase()) {
    case 'high':   return AppColors.admin;
    case 'medium': return AppColors.president;
    default:       return AppColors.primary;
  }
}

Color _statusColor(String s) {
  switch (s.toLowerCase()) {
    case 'done':        return AppColors.primary;
    case 'in progress': return AppColors.president;
    default:            return AppColors.textMedium;
  }
}

IconData _statusIcon(String s) {
  switch (s.toLowerCase()) {
    case 'done':        return Icons.check_circle;
    case 'in progress': return Icons.timelapse;
    default:            return Icons.radio_button_unchecked;
  }
}

String _formatDate(Timestamp? ts) {
  if (ts == null) return 'No deadline';
  final d = ts.toDate();
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

bool _isOverdue(Timestamp? ts, String status) {
  if (ts == null || status.toLowerCase() == 'done') return false;
  return ts.toDate().isBefore(DateTime.now());
}

// ─── President: Task Management Screen ────────────────────────────────────────

class PresidentTaskScreen extends StatefulWidget {
  const PresidentTaskScreen({super.key});

  @override
  State<PresidentTaskScreen> createState() => _PresidentTaskScreenState();
}

class _PresidentTaskScreenState extends State<PresidentTaskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      primary: false,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('IEEE PES UTM',
                      style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500)),
                  Text('Tasks',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  Text('Assign and track committee tasks',
                      style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                ]),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const _AssignTaskScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.president,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: AppColors.president.withValues(alpha: 0.4),
                          blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tab,
              indicator: BoxDecoration(
                color: AppColors.president,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textMedium,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'To Do'),
                Tab(text: 'In Progress'),
                Tab(text: 'Done'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _TaskList(filterStatus: 'To Do',      role: 'president'),
                _TaskList(filterStatus: 'In Progress', role: 'president'),
                _TaskList(filterStatus: 'Done',        role: 'president'),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Committee: My Tasks Screen ────────────────────────────────────────────────

class CommitteeTaskScreen extends StatefulWidget {
  const CommitteeTaskScreen({super.key});

  @override
  State<CommitteeTaskScreen> createState() => _CommitteeTaskScreenState();
}

class _CommitteeTaskScreenState extends State<CommitteeTaskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      primary: false,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('IEEE PES UTM',
                      style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500)),
                  Text('My Tasks',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  Text('Tasks assigned to you',
                      style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                ]),
                const Icon(Icons.task_alt, color: AppColors.committee, size: 26),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tab,
              indicator: BoxDecoration(
                color: AppColors.committee,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textMedium,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'To Do'),
                Tab(text: 'In Progress'),
                Tab(text: 'Done'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _TaskList(filterStatus: 'To Do',      role: 'committee'),
                _TaskList(filterStatus: 'In Progress', role: 'committee'),
                _TaskList(filterStatus: 'Done',        role: 'committee'),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Shared Task List ──────────────────────────────────────────────────────────

class _TaskList extends StatelessWidget {
  final String filterStatus;
  final String role; // 'president' | 'committee'
  const _TaskList({required this.filterStatus, required this.role});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // President sees all tasks with this status
    // Committee sees only their assigned tasks
    final query = role == 'president'
        ? FirebaseFirestore.instance
        .collection('tasks')
        .where('status', isEqualTo: filterStatus)
        .orderBy('createdAt', descending: true)
        : FirebaseFirestore.instance
        .collection('tasks')
        .where('assignedTo', isEqualTo: uid)
        .where('status', isEqualTo: filterStatus)
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(
              color: role == 'president' ? AppColors.president : AppColors.committee));
        }
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(_statusIcon(filterStatus),
                  color: AppColors.textLight, size: 48),
              const SizedBox(height: 12),
              Text('No $filterStatus tasks',
                  style: const TextStyle(color: AppColors.textMedium,
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ]),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (c, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return _TaskCard(id: docs[i].id, data: d, role: role);
          },
        );
      },
    );
  }
}

// ─── Task Card ─────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final String id, role;
  final Map<String, dynamic> data;
  const _TaskCard({required this.id, required this.data, required this.role});

  @override
  Widget build(BuildContext context) {
    final title    = data['title']    as String? ?? '(Untitled)';
    final priority = data['priority'] as String? ?? 'Low';
    final status   = data['status']   as String? ?? 'To Do';
    final deadline = data['deadline'] as Timestamp?;
    final overdue  = _isOverdue(deadline, status);
    final assignedTo = data['assignedTo'] as String? ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => TaskDetailScreen(id: id, data: data, role: role))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: _priorityColor(priority), width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Title + priority
          Row(children: [
            Expanded(child: Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                    color: AppColors.textDark))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _priorityColor(priority).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(priority,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: _priorityColor(priority))),
            ),
          ]),
          const SizedBox(height: 8),

          // Status badge + deadline
          Row(children: [
            Icon(_statusIcon(status), size: 14, color: _statusColor(status)),
            const SizedBox(width: 4),
            Text(status,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: _statusColor(status))),
            const Spacer(),
            Icon(
              overdue ? Icons.warning_amber_rounded : Icons.calendar_today_outlined,
              size: 13,
              color: overdue ? AppColors.admin : AppColors.textMedium,
            ),
            const SizedBox(width: 4),
            Text(_formatDate(deadline),
                style: TextStyle(fontSize: 12,
                    color: overdue ? AppColors.admin : AppColors.textMedium,
                    fontWeight: overdue ? FontWeight.w700 : FontWeight.normal)),
          ]),

          // Assignee row — only shown for president view
          if (role == 'president') ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _AssigneeRow(uid: assignedTo),
          ],
        ]),
      ),
    );
  }
}

// Fetches and shows assignee name
class _AssigneeRow extends StatelessWidget {
  final String uid;
  const _AssigneeRow({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (ctx, snap) {
        final name    = snap.hasData && snap.data!.exists
            ? (snap.data!.data() as Map<String, dynamic>)['fullName'] as String? ?? '—'
            : '—';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
        return Row(children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
                color: AppColors.committee.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: Center(child: Text(initial,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppColors.committee))),
          ),
          const SizedBox(width: 6),
          Text(name,
              style: const TextStyle(fontSize: 12, color: AppColors.textMedium,
                  fontWeight: FontWeight.w500)),
        ]);
      },
    );
  }
}

// ─── Task Detail Screen ────────────────────────────────────────────────────────

class TaskDetailScreen extends StatelessWidget {
  final String id, role;
  final Map<String, dynamic> data;
  const TaskDetailScreen({super.key, required this.id, required this.data, required this.role});

  @override
  Widget build(BuildContext context) {
    final title       = data['title']       as String? ?? '(Untitled)';
    final description = data['description'] as String? ?? '';
    final priority    = data['priority']    as String? ?? 'Low';
    final status      = data['status']      as String? ?? 'To Do';
    final deadline    = data['deadline']    as Timestamp?;
    final assignedTo  = data['assignedTo']  as String? ?? '';
    final assignedBy  = data['assignedBy']  as String? ?? '';
    final overdue     = _isOverdue(deadline, status);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            decoration: BoxDecoration(
              color: role == 'president' ? AppColors.president : AppColors.committee,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
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
              const Text('TASK DETAIL',
                  style: TextStyle(color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(title,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Status + priority card
                _Card(children: [
                  Row(children: [
                    StatusBadge(label: status, color: _statusColor(status)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _priorityColor(priority).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$priority Priority',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                              color: _priorityColor(priority))),
                    ),
                    const Spacer(),
                    if (overdue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.admin.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('OVERDUE',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                                color: AppColors.admin)),
                      ),
                  ]),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  _Row(icon: Icons.calendar_today_outlined, label: 'Deadline',
                      value: _formatDate(deadline),
                      valueColor: overdue ? AppColors.admin : null),
                  _Row(icon: Icons.person_outline, label: 'Assigned To',
                      value: '', uid: assignedTo, isAssignee: true),
                  _Row(icon: Icons.supervisor_account_outlined, label: 'Assigned By',
                      value: '', uid: assignedBy, isAssignee: false),
                ]),
                const SizedBox(height: 16),

                // Description
                if (description.isNotEmpty)
                  _Card(children: [
                    const Text('Description',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    const SizedBox(height: 10),
                    Text(description,
                        style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.5)),
                  ]),
                if (description.isNotEmpty) const SizedBox(height: 16),

                // Update progress — committee only, not done
                if (role == 'committee' && status != 'Done') ...[
                  const Text('Update Progress',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  ..._statuses.where((s) => s != status).map((s) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _StatusButton(taskId: id, targetStatus: s, data: data),
                      ),
                  ),
                ],

                // Delete task — president only
                if (role == 'president') ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Task'),
                            content: const Text('Delete this task permanently?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.admin),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                        await FirebaseFirestore.instance.collection('tasks').doc(id).delete();
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete_outline, color: AppColors.admin),
                      label: const Text('Delete Task'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.admin,
                        side: BorderSide(color: AppColors.admin.withValues(alpha: 0.5)),
                      ),
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

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  final String? uid;
  final bool isAssignee;
  const _Row({required this.icon, required this.label, required this.value,
    this.valueColor, this.uid, this.isAssignee = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 15, color: AppColors.textMedium),
        const SizedBox(width: 8),
        SizedBox(width: 100,
            child: Text(label, style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w600, color: AppColors.textDark))),
        if (uid != null && uid!.isNotEmpty)
          _UidName(uid: uid!, color: isAssignee ? AppColors.committee : AppColors.president)
        else
          Text(value, style: TextStyle(fontSize: 13,
              color: valueColor ?? AppColors.textMedium)),
      ]),
    );
  }
}

class _UidName extends StatelessWidget {
  final String uid;
  final Color color;
  const _UidName({required this.uid, required this.color});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (ctx, snap) {
        final name = snap.hasData && snap.data!.exists
            ? (snap.data!.data() as Map<String, dynamic>)['fullName'] as String? ?? '—'
            : '—';
        return Text(name, style: TextStyle(fontSize: 13, color: color,
            fontWeight: FontWeight.w600));
      },
    );
  }
}

// Button that updates task status and sends a notification to the assignee
class _StatusButton extends StatefulWidget {
  final String taskId, targetStatus;
  final Map<String, dynamic> data;
  const _StatusButton({required this.taskId, required this.targetStatus, required this.data});

  @override
  State<_StatusButton> createState() => _StatusButtonState();
}

class _StatusButtonState extends State<_StatusButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(widget.targetStatus);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _update,
        icon: _loading
            ? const SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(_statusIcon(widget.targetStatus), size: 18),
        label: Text('Mark as ${widget.targetStatus}'),
        style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 14)),
      ),
    );
  }

  Future<void> _update() async {
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).update({
        'status':    widget.targetStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify the president (assignedBy) that status changed
      final assignedBy = widget.data['assignedBy'] as String? ?? '';
      final title      = widget.data['title']      as String? ?? 'a task';
      if (assignedBy.isNotEmpty) {
        await sendNotification(
          userId: assignedBy,
          title:  'Task Update',
          body:   '"$title" has been marked as ${widget.targetStatus}',
          type:   NotifType.taskUpdated,
          extra:  {'taskId': widget.taskId},
        );
      }
      await logActivity('Task updated', '"$title" → ${widget.targetStatus}');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

// ─── Assign Task Screen (president only) ───────────────────────────────────────

class _AssignTaskScreen extends StatefulWidget {
  const _AssignTaskScreen();

  @override
  State<_AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<_AssignTaskScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _titleCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();
  String   _priority  = 'Medium';
  DateTime? _deadline;
  String?  _assigneeUid;
  String?  _assigneeName;
  bool     _saving    = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _showAssigneePicker() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _CommitteePicker(
        onSelected: (uid, name) {
          setState(() { _assigneeUid = uid; _assigneeName = name; });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_assigneeUid == null) { _snack('Please select a committee member'); return; }
    if (_deadline == null)    { _snack('Please select a deadline'); return; }

    setState(() => _saving = true);
    try {
      final presidentUid = FirebaseAuth.instance.currentUser!.uid;
      final docRef = await FirebaseFirestore.instance.collection('tasks').add({
        'title':       _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'priority':    _priority,
        'status':      'To Do',
        'assignedTo':  _assigneeUid,
        'assignedBy':  presidentUid,
        'deadline':    Timestamp.fromDate(_deadline!),
        'createdAt':   FieldValue.serverTimestamp(),
      });

      // Notify the committee member
      await sendNotification(
        userId: _assigneeUid!,
        title:  'New Task Assigned',
        body:   'You have been assigned: "${_titleCtrl.text.trim()}" — due ${_formatDate(Timestamp.fromDate(_deadline!))}',
        type:   NotifType.taskAssigned,
        extra:  {'taskId': docRef.id},
      );

      await logActivity('Task assigned', '"${_titleCtrl.text.trim()}" → $_assigneeName');
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
              color: AppColors.president,
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
              const Text('ASSIGN TASK',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Assign a task to a committee member',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
          ),

          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  _Card(children: [
                    // Title
                    _LabelText('Task Title'),
                    TextFormField(
                      controller: _titleCtrl,
                      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                      decoration: const InputDecoration(hintText: 'e.g., Prepare event banner'),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _LabelText('Description (optional)'),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                      decoration: const InputDecoration(hintText: 'What needs to be done?'),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  _Card(children: [
                    // Assignee picker
                    _LabelText('Assign To'),
                    GestureDetector(
                      onTap: _showAssigneePicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                            color: AppColors.inputBg, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          const Icon(Icons.person_outline, size: 18, color: AppColors.textMedium),
                          const SizedBox(width: 10),
                          Expanded(child: Text(
                            _assigneeName ?? 'Select committee member',
                            style: TextStyle(fontSize: 14,
                                color: _assigneeName != null ? AppColors.textDark : AppColors.textLight),
                          )),
                          const Icon(Icons.keyboard_arrow_down, color: AppColors.textMedium),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Deadline
                    _LabelText('Deadline'),
                    GestureDetector(
                      onTap: _pickDeadline,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                            color: AppColors.inputBg, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          const Icon(Icons.calendar_today_outlined, size: 16,
                              color: AppColors.textMedium),
                          const SizedBox(width: 10),
                          Text(
                            _deadline != null
                                ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                                : 'Select deadline',
                            style: TextStyle(fontSize: 14,
                                color: _deadline != null ? AppColors.textDark : AppColors.textLight),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Priority
                    _LabelText('Priority'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                          color: AppColors.inputBg, borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _priority,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                          items: _priorities.map((p) => DropdownMenuItem(
                            value: p,
                            child: Row(children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(
                                  shape: BoxShape.circle, color: _priorityColor(p))),
                              const SizedBox(width: 10),
                              Text(p),
                            ]),
                          )).toList(),
                          onChanged: (v) => setState(() => _priority = v!),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.president),
                      child: _saving
                          ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                          : const Text('Assign Task'),
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

// Small label widget for the form
class _LabelText extends StatelessWidget {
  final String text;
  const _LabelText(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: AppColors.textDark)),
  );
}

// ─── Committee Member Picker (bottom sheet) ────────────────────────────────────

class _CommitteePicker extends StatelessWidget {
  final void Function(String uid, String name) onSelected;
  const _CommitteePicker({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 12),
      Container(width: 40, height: 4,
          decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 16),
      const Text('Select Committee Member',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      const SizedBox(height: 16),
      Flexible(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'committee')
              .snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.committee));
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Padding(padding: EdgeInsets.all(32),
                  child: Text('No committee members found',
                      style: TextStyle(color: AppColors.textMedium)));
            }
            return ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (c, i) {
                final d    = docs[i].data() as Map<String, dynamic>;
                final name = d['fullName'] as String? ?? '—';
                final faculty = d['faculty'] as String? ?? '';
                final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: AppColors.committee.withValues(alpha: 0.15),
                        shape: BoxShape.circle),
                    child: Center(child: Text(initial,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                            color: AppColors.committee))),
                  ),
                  title: Text(name, style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  subtitle: faculty.isNotEmpty ? Text(faculty,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMedium)) : null,
                  onTap: () => onSelected(docs[i].id, name),
                );
              },
            );
          },
        ),
      ),
    ]);
  }
}