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
                  const Expanded(
                    child: Column(
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
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.student.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.event, color: AppColors.student, size: 24),
                  ),
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
                    .snapshots(),
                builder: (ctx, regSnap) {
                  if (regSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.student));
                  }
                  if (regSnap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.admin, size: 48),
                            const SizedBox(height: 12),
                            Text('Error: ${regSnap.error}', textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.textMedium)),
                            const SizedBox(height: 8),
                            const Text('If this is an index error, create the index in Firebase Console.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  }
                  final regs = regSnap.data?.docs ?? [];
                  if (regs.isEmpty) {
                    return _EmptyEvents();
                  }
                  // Sort client-side since composite index may not exist
                  final sorted = List<QueryDocumentSnapshot>.from(regs)
                    ..sort((a, b) {
                      final aTs = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      final bTs = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      if (aTs == null || bTs == null) return 0;
                      return bTs.compareTo(aTs);
                    });

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: sorted.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (c, i) {
                      final reg = sorted[i].data() as Map<String, dynamic>;
                      final eventId = reg['eventId'] as String? ?? '';
                      final paymentStatus = reg['paymentStatus'] as String? ?? 'pending';
                      final eventName = reg['eventName'] as String? ?? '';
                      final status = reg['status'] as String? ?? 'pending';
                      return _RegisteredEventCard(
                        eventId: eventId,
                        eventName: eventName,
                        paymentStatus: paymentStatus,
                        registrationStatus: status,
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

class _RegisteredEventCard extends StatelessWidget {
  final String eventId;
  final String eventName;
  final String paymentStatus;
  final String registrationStatus;
  const _RegisteredEventCard({
    required this.eventId,
    required this.eventName,
    required this.paymentStatus,
    required this.registrationStatus,
  });

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

  Color get _regColor {
    switch (registrationStatus.toLowerCase()) {
      case 'verified': return AppColors.primary;
      case 'rejected': return AppColors.admin;
      default:         return AppColors.president;
    }
  }

  String get _regLabel {
    switch (registrationStatus.toLowerCase()) {
      case 'verified': return 'Verified';
      case 'rejected': return 'Rejected';
      default:         return 'Pending';
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
          return _buildCard(
            title: eventName.isNotEmpty ? eventName : '(Event removed)',
            location: '',
            dateStr: 'Date TBC',
            timeStr: null,
          );
        }
        final d = snap.data!.data() as Map<String, dynamic>;
        final title    = d['title']    as String? ?? '(Untitled)';
        final location = d['location'] as String? ?? '';
        final ts       = d['date']     as Timestamp?;
        final dateStr  = ts != null ? _formatDate(ts) : 'Date TBC';
        // Support both a separate 'time' string field and extracting time from the
        // same Timestamp used for the date (whichever your Firestore doc uses).
        final timeStr  = (d['time'] as String?)?.isNotEmpty == true
            ? d['time'] as String
            : (ts != null ? _formatTime(ts) : null);

        return _buildCard(title: title, location: location, dateStr: dateStr, timeStr: timeStr);
      },
    );
  }

  Widget _buildCard({
    required String title,
    required String location,
    required String dateStr,
    required String? timeStr,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: AppColors.student, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMedium),
              const SizedBox(width: 4),
              Expanded(
                child: Text(location.isNotEmpty ? location : 'Location TBC',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Date and time on the same row
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMedium),
              const SizedBox(width: 4),
              Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
              if (timeStr != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.access_time_outlined, size: 13, color: AppColors.textMedium),
                const SizedBox(width: 4),
                Text(timeStr, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _paymentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_paymentLabel,
                    style: TextStyle(fontSize: 11, color: _paymentColor, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _regColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_regLabel,
                    style: TextStyle(fontSize: 11, color: _regColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp ts) {
    final d = ts.toDate();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // Extracts time from the Timestamp (e.g. "9:00 AM")
  String _formatTime(Timestamp ts) {
    final d = ts.toDate();
    final hour   = d.hour;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:$minute $period';
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