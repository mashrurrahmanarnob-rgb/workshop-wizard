import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'available_events_screen.dart';
import 'event_detail_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  final String email;
  const StudentHomeScreen({super.key, required this.email});

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'Date TBC';
    final d = ts.toDate();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      primary: false,
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                  gradient: const LinearGradient(
                    colors: [AppColors.student, Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.student.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('STUDENT PORTAL',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                          ),
                          const SizedBox(height: 10),
                          const Text('Welcome back!',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(email,
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
              const SizedBox(height: 28),

              // Available events header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Available Events',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      SizedBox(height: 2),
                      Text('Upcoming workshops open for registration',
                          style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Single trending event preview
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .where('status', isEqualTo: 'upcoming')
                    .orderBy('date')
                    .limit(1)
                    .snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.student),
                    ));
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return _EmptyAvailableEvents();
                  }
                  final doc = docs.first;
                  final d = doc.data() as Map<String, dynamic>;
                  return _TrendingEventCard(id: doc.id, data: d, formatDate: _formatDate);
                },
              ),
              const SizedBox(height: 16),

              // View All Events button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AvailableEventsScreen())),
                  icon: const Icon(Icons.event_note, size: 18),
                  label: const Text('View All Events', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.student,
                    side: const BorderSide(color: AppColors.student),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendingEventCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final String Function(Timestamp?) formatDate;
  const _TrendingEventCard({required this.id, required this.data, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final title       = data['title']           as String? ?? '(Untitled)';
    final location    = data['location']        as String? ?? '';
    final description = data['description']     as String? ?? '';
    final fee         = (data['fee'] as num?)?.toDouble() ?? 0;
    final isFree      = data['isFree'] as bool? ?? (fee == 0);
    final maxPart     = data['maxParticipants'] as int?    ?? 0;
    final regCount    = data['registrationCount'] as int?  ?? 0;
    final dateStr     = formatDate(data['date'] as Timestamp?);
    final feeLabel    = isFree || fee == 0 ? 'Free' : 'RM ${fee.toStringAsFixed(2)}';
    final isSoldOut   = maxPart > 0 && regCount >= maxPart;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => EventDetailScreen(eventId: id, data: data),
      )),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.student, Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.student.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(feeLabel,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85), height: 1.4)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 13, color: Colors.white.withValues(alpha: 0.7)),
                const SizedBox(width: 5),
                Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 13, color: Colors.white.withValues(alpha: 0.7)),
                const SizedBox(width: 5),
                Expanded(child: Text(location, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people_outline, size: 13, color: Colors.white.withValues(alpha: 0.7)),
                const SizedBox(width: 5),
                Text('$regCount / $maxPart registered', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSoldOut ? Colors.white.withValues(alpha: 0.15) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isSoldOut ? 'Sold Out' : 'Register',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSoldOut ? Colors.white.withValues(alpha: 0.7) : AppColors.student,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAvailableEvents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.student.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_outlined, color: AppColors.student, size: 28),
          ),
          const SizedBox(height: 14),
          const Text('No events available',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 6),
          const Text(
            'New workshops will appear here once\na proposal has been approved.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.5),
          ),
        ],
      ),
    );
  }
}
