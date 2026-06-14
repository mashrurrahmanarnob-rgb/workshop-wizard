import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

// ─── Notifications Screen ──────────────────────────────────────────────────────

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Detect if this screen was pushed (has a route below it) or is a tab
    final canPop = Navigator.of(context).canPop();

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
                children: [
                  // Back button — shown when pushed, hidden when used as a tab
                  if (canPop) ...[
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: const Icon(Icons.arrow_back, color: AppColors.textDark, size: 20),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('IEEE PES UTM',
                            style: TextStyle(fontSize: 12, color: AppColors.textLight,
                                fontWeight: FontWeight.w500)),
                        Text('Notifications',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                                color: AppColors.textDark)),
                        Text('Your latest updates',
                            style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                      ],
                    ),
                  ),
                  // Mark all read
                  GestureDetector(
                    onTap: () => markAllRead(uid),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(children: [
                        Icon(Icons.done_all, color: AppColors.primary, size: 16),
                        SizedBox(width: 6),
                        Text('Mark all read',
                            style: TextStyle(fontSize: 12, color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: uid.isEmpty
                  ? const Center(child: Text('Not logged in'))
                  : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('userId', isEqualTo: uid)
                    .orderBy('createdAt', descending: true)
                    .limit(50)
                    .snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_none,
                              color: AppColors.primary, size: 34),
                        ),
                        const SizedBox(height: 16),
                        const Text('No notifications yet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                color: AppColors.textDark)),
                        const SizedBox(height: 6),
                        const Text('You\'re all caught up!',
                            style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                      ]),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (c, i) {
                      final d     = docs[i].data() as Map<String, dynamic>;
                      final id    = docs[i].id;
                      final read  = d['read']  as bool?   ?? true;
                      final type  = d['type']  as String? ?? NotifType.general;
                      final title = d['title'] as String? ?? '';
                      final body  = d['body']  as String? ?? '';
                      final ts    = d['createdAt'] as Timestamp?;
                      return _NotifCard(
                        id: id, type: type, title: title,
                        body: body, ts: ts, read: read,
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

// ─── Notification Card ─────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final String id, type, title, body;
  final Timestamp? ts;
  final bool read;
  const _NotifCard({
    required this.id, required this.type, required this.title,
    required this.body, required this.ts, required this.read,
  });

  IconData get _icon {
    switch (type) {
      case NotifType.taskAssigned:      return Icons.assignment_outlined;
      case NotifType.taskUpdated:       return Icons.task_alt;
      case NotifType.proposalApproved:  return Icons.verified_outlined;
      case NotifType.proposalRejected:  return Icons.cancel_outlined;
      case NotifType.proposalSubmitted: return Icons.send_outlined;
      default:                          return Icons.notifications_outlined;
    }
  }

  Color get _color {
    switch (type) {
      case NotifType.taskAssigned:      return AppColors.committee;
      case NotifType.taskUpdated:       return AppColors.president;
      case NotifType.proposalApproved:  return AppColors.primary;
      case NotifType.proposalRejected:  return AppColors.admin;
      case NotifType.proposalSubmitted: return AppColors.president;
      default:                          return AppColors.student;
    }
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    final d = ts.toDate();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { if (!read) markRead(id); },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: read ? AppColors.cardWhite : _color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: read ? Colors.transparent : _color.withValues(alpha: 0.25)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: _color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(title,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: read ? AppColors.textDark : _color)),
                ),
                if (!read)
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
              ]),
              const SizedBox(height: 4),
              Text(body,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4)),
              const SizedBox(height: 6),
              Text(_timeAgo(ts),
                  style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Bell Icon Widget ──────────────────────────────────────────────────────────

class NotificationBell extends StatelessWidget {
  final Color color;
  const NotificationBell({super.key, this.color = AppColors.textMedium});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<int>(
      stream: unreadCountStream(uid),
      builder: (ctx, snap) {
        final count = snap.data ?? 0;
        return GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Icon(Icons.notifications_outlined, color: color, size: 22),
            ),
            if (count > 0)
              Positioned(
                top: -4, right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppColors.admin, shape: BoxShape.circle),
                  child: Text(count > 9 ? '9+' : '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 9,
                          fontWeight: FontWeight.w800)),
                ),
              ),
          ]),
        );
      },
    );
  }
}