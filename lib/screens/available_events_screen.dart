import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'event_detail_screen.dart';

class AvailableEventsScreen extends StatefulWidget {
  const AvailableEventsScreen({super.key});

  @override
  State<AvailableEventsScreen> createState() => _AvailableEventsScreenState();
}

class _AvailableEventsScreenState extends State<AvailableEventsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: const Icon(Icons.arrow_back, color: AppColors.textDark, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Available Events', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                        Text('Upcoming workshops open for registration', style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search events...',
                  hintStyle: const TextStyle(color: AppColors.textLight),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                  filled: true,
                  fillColor: AppColors.cardWhite,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Events list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .where('status', isEqualTo: 'upcoming')
                    .snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.student));
                  }
                  final docs = snap.data?.docs ?? [];
                  final filtered = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final title = (data['title'] as String? ?? '').toLowerCase();
                    final loc = (data['location'] as String? ?? '').toLowerCase();
                    return title.contains(_query) || loc.contains(_query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy, color: AppColors.textLight, size: 48),
                          SizedBox(height: 12),
                          Text('No events found', style: TextStyle(color: AppColors.textMedium, fontSize: 15, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (c, i) => _EventListCard(doc: filtered[i]),
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

class _EventListCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _EventListCard({required this.doc});

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'Date TBC';
    final d = ts.toDate();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final d = doc.data() as Map<String, dynamic>;
    final title = d['title'] as String? ?? '(Untitled)';
    final description = d['description'] as String? ?? '';
    final location = d['location'] as String? ?? '';
    final time = d['time'] as String? ?? '';
    final duration = d['duration'] as String? ?? '';
    final fee = (d['fee'] as num?)?.toDouble() ?? 0;
    final isFree = d['isFree'] as bool? ?? (fee == 0);
    final maxPart = d['maxParticipants'] as int? ?? 0;
    final regCount = d['registrationCount'] as int? ?? 0;
    final dateStr = _formatDate(d['date'] as Timestamp?);
    final feeLabel = isFree || fee == 0 ? 'Free' : 'RM ${fee.toStringAsFixed(2)}';
    final isSoldOut = maxPart > 0 && regCount >= maxPart;
    final spotsLeft = maxPart > 0 ? maxPart - regCount : 0;
    final progress = maxPart > 0 ? regCount / maxPart : 0.0;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => EventDetailScreen(eventId: doc.id, data: d),
      )),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blue header area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.student, Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Technical', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(feeLabel, style: const TextStyle(color: AppColors.student, fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_month, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ),

            // White body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  const SizedBox(height: 6),
                  Text(description, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.4)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMedium),
                      const SizedBox(width: 6),
                      Text(dateStr, style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: AppColors.textMedium),
                      const SizedBox(width: 6),
                      Text('$time ${duration.isNotEmpty ? '($duration)' : ''}', style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMedium),
                      const SizedBox(width: 6),
                      Expanded(child: Text(location, style: const TextStyle(fontSize: 13, color: AppColors.textMedium), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 14, color: AppColors.textMedium),
                      const SizedBox(width: 6),
                      Text('$regCount / $maxPart registered', style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
                      const Spacer(),
                      if (isSoldOut)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.admin.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: const Text('Sold Out', style: TextStyle(color: AppColors.admin, fontSize: 12, fontWeight: FontWeight.w700)),
                        )
                      else
                        Text('$spotsLeft left', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isSoldOut ? AppColors.admin : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSoldOut ? null : () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => EventDetailScreen(eventId: doc.id, data: d),
                      )),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSoldOut ? AppColors.textLight : AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(isSoldOut ? 'Sold Out' : 'Register Now', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
