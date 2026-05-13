import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EventsScreen extends StatelessWidget {
  final String email;
  const EventsScreen({super.key, required this.email});

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
                      Text('My Events',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                      Text('Events you have registered for',
                          style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                    ],
                  ),
                  const Icon(Icons.event, color: AppColors.student, size: 26),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: uid == null
                  ? const Center(child: Text('Not logged in'))
                  : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('event_registrations')
                    .where('userId', isEqualTo: uid)
                    .orderBy('registeredAt', descending: true)
                    .snapshots(),
                builder: (ctx, regSnap) {
                  if (regSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.student));
                  }
                  if (regSnap.hasError) {
                    return Center(child: Text('Error: ${regSnap.error}'));
                  }
                  final regs = regSnap.data?.docs ?? [];
                  if (regs.isEmpty) {
                    return _EmptyEvents();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: regs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (c, i) {
                      final reg = regs[i].data() as Map<String, dynamic>;
                      final eventId = reg['eventId'] as String? ?? '';
                      final paymentStatus = reg['paymentStatus'] as String? ?? 'pending';
                      return _RegisteredEventCard(
                        eventId: eventId,
                        paymentStatus: paymentStatus,
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

// Fetches and displays a single registered event by eventId
class _RegisteredEventCard extends StatelessWidget {
  final String eventId;
  final String paymentStatus;
  const _RegisteredEventCard({required this.eventId, required this.paymentStatus});

  Color get _paymentColor {
    switch (paymentStatus) {
      case 'paid':    return AppColors.primary;
      case 'free':    return AppColors.student;
      default:        return AppColors.president;
    }
  }

  String get _paymentLabel {
    switch (paymentStatus) {
      case 'paid':    return 'Paid';
      case 'free':    return 'Free';
      default:        return 'Payment Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('events').doc(eventId).get(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Container(
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator(color: AppColors.student, strokeWidth: 2)),
          );
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const SizedBox.shrink();
        }
        final d = snap.data!.data() as Map<String, dynamic>;
        final title    = d['title']    as String? ?? '(Untitled)';
        final location = d['location'] as String? ?? '';
        final status   = d['status']   as String? ?? 'upcoming';
        final ts       = d['date']     as Timestamp?;
        final dateStr  = ts != null ? _formatDate(ts) : 'Date TBC';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: const Border(left: BorderSide(color: AppColors.student, width: 4)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              // Date badge
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.student.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event, color: AppColors.student, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMedium),
                        const SizedBox(width: 3),
                        Expanded(child: Text(location,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMedium))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Event status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(status[0].toUpperCase() + status.substring(1),
                        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 6),
                  // Payment status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _paymentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_paymentLabel,
                        style: TextStyle(fontSize: 11, color: _paymentColor, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(Timestamp ts) {
    final d = ts.toDate();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _EmptyEvents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.student.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_busy, color: AppColors.student, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('No events yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 8),
            const Text(
              'Events will appear here once you register.\nCheck the Home tab for available events.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}